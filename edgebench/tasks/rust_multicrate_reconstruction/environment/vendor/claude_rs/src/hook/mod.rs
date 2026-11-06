//! Hook system for intercepting Claude events.
//!
//! Hooks allow you to intercept and respond to various events during
//! a Claude session, such as tool use requests, permission requests,
//! and session lifecycle events.

mod handler;
pub mod input;
pub mod output;

pub use handler::{ApproveHandler, DenyHandler, HookHandler};
pub use input::{HookInput, HookInputData, PermissionSuggestion};
pub use output::{HookOutput, PermissionDecision};

use async_trait::async_trait;
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use std::time::Duration;

/// Hook events that can be intercepted.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum HookEvent {
    /// Before a tool is used
    PreToolUse,
    /// After a tool is used successfully
    PostToolUse,
    /// After a tool use fails
    PostToolUseFailure,
    /// Notification from Claude
    Notification,
    /// User prompt submitted
    UserPromptSubmit,
    /// Session started
    SessionStart,
    /// Session ended
    SessionEnd,
    /// Stop requested
    Stop,
    /// Subagent started
    SubagentStart,
    /// Subagent stopped
    SubagentStop,
    /// Before context compaction
    PreCompact,
    /// Permission request
    PermissionRequest,
}

impl HookEvent {
    /// Get the string name of this event.
    pub fn as_str(&self) -> &'static str {
        match self {
            HookEvent::PreToolUse => "PreToolUse",
            HookEvent::PostToolUse => "PostToolUse",
            HookEvent::PostToolUseFailure => "PostToolUseFailure",
            HookEvent::Notification => "Notification",
            HookEvent::UserPromptSubmit => "UserPromptSubmit",
            HookEvent::SessionStart => "SessionStart",
            HookEvent::SessionEnd => "SessionEnd",
            HookEvent::Stop => "Stop",
            HookEvent::SubagentStart => "SubagentStart",
            HookEvent::SubagentStop => "SubagentStop",
            HookEvent::PreCompact => "PreCompact",
            HookEvent::PermissionRequest => "PermissionRequest",
        }
    }

    /// Get the SDK-format string name (PascalCase).
    /// Used when sending hooks config to the CLI.
    pub fn to_sdk_string(&self) -> &'static str {
        self.as_str()
    }

    /// Parse from string.
    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Option<Self> {
        match s {
            "PreToolUse" | "pre_tool_use" => Some(HookEvent::PreToolUse),
            "PostToolUse" | "post_tool_use" => Some(HookEvent::PostToolUse),
            "PostToolUseFailure" | "post_tool_use_failure" => Some(HookEvent::PostToolUseFailure),
            "Notification" | "notification" => Some(HookEvent::Notification),
            "UserPromptSubmit" | "user_prompt_submit" => Some(HookEvent::UserPromptSubmit),
            "SessionStart" | "session_start" => Some(HookEvent::SessionStart),
            "SessionEnd" | "session_end" => Some(HookEvent::SessionEnd),
            "Stop" | "stop" => Some(HookEvent::Stop),
            "SubagentStart" | "subagent_start" => Some(HookEvent::SubagentStart),
            "SubagentStop" | "subagent_stop" => Some(HookEvent::SubagentStop),
            "PreCompact" | "pre_compact" => Some(HookEvent::PreCompact),
            "PermissionRequest" | "permission_request" => Some(HookEvent::PermissionRequest),
            _ => None,
        }
    }
}

/// A hook for intercepting events.
#[derive(Clone)]
pub struct Hook {
    /// The event to hook
    pub event: HookEvent,

    /// Optional tool name filter (for tool events)
    pub matcher: Option<String>,

    /// Handler for the hook
    handler: Arc<dyn HookHandler>,

    /// Timeout for handler execution
    pub timeout: Duration,
}

impl Hook {
    /// Create a hook for the given event.
    pub fn on<H: HookHandler + 'static>(event: HookEvent, handler: H) -> Self {
        Self {
            event,
            matcher: None,
            handler: Arc::new(handler),
            timeout: Duration::from_secs(30),
        }
    }

    /// Create a hook builder.
    pub fn builder(event: HookEvent) -> HookBuilder {
        HookBuilder::new(event)
    }

    /// Set the tool name matcher.
    pub fn matcher(mut self, tool_name: impl Into<String>) -> Self {
        self.matcher = Some(tool_name.into());
        self
    }

    /// Set the timeout.
    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }

    /// Check if this hook matches the given event and tool name.
    pub fn matches(&self, event: HookEvent, tool_name: Option<&str>) -> bool {
        if self.event != event {
            return false;
        }

        match (&self.matcher, tool_name) {
            (Some(pattern), Some(name)) => pattern == name,
            (Some(_), None) => false,
            (None, _) => true,
        }
    }

    /// Execute the hook handler.
    pub async fn execute(&self, input: HookInput) -> HookOutput {
        self.handler.handle(input).await
    }
}

impl std::fmt::Debug for Hook {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Hook")
            .field("event", &self.event)
            .field("matcher", &self.matcher)
            .field("timeout", &self.timeout)
            .finish()
    }
}

/// Builder for creating hooks.
pub struct HookBuilder {
    event: HookEvent,
    matcher: Option<String>,
    timeout: Duration,
}

impl HookBuilder {
    /// Create a new hook builder.
    pub fn new(event: HookEvent) -> Self {
        Self {
            event,
            matcher: None,
            timeout: Duration::from_secs(30),
        }
    }

    /// Set the tool name matcher.
    pub fn matcher(mut self, tool_name: impl Into<String>) -> Self {
        self.matcher = Some(tool_name.into());
        self
    }

    /// Set the timeout.
    pub fn timeout(mut self, timeout: Duration) -> Self {
        self.timeout = timeout;
        self
    }

    /// Build with the given handler.
    pub fn handler<H: HookHandler + 'static>(self, handler: H) -> Hook {
        Hook {
            event: self.event,
            matcher: self.matcher,
            handler: Arc::new(handler),
            timeout: self.timeout,
        }
    }

    /// Build with a closure handler.
    pub fn handler_fn<F, Fut>(self, f: F) -> Hook
    where
        F: Fn(HookInput) -> Fut + Send + Sync + 'static,
        Fut: std::future::Future<Output = HookOutput> + Send + 'static,
    {
        self.handler(FnHookHandler(f))
    }
}

/// Wrapper for closure hook handlers.
struct FnHookHandler<F>(F);

#[async_trait]
impl<F, Fut> HookHandler for FnHookHandler<F>
where
    F: Fn(HookInput) -> Fut + Send + Sync,
    Fut: std::future::Future<Output = HookOutput> + Send,
{
    async fn handle(&self, input: HookInput) -> HookOutput {
        (self.0)(input).await
    }
}
