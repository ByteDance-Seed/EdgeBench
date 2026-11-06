//! Hook output types.

use serde::{Deserialize, Serialize};
use serde_json::Value;

/// Output from a hook handler.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookOutput {
    /// Whether to continue execution
    #[serde(default = "default_true")]
    pub continue_execution: bool,

    /// Whether to suppress output
    #[serde(default)]
    pub suppress_output: bool,

    /// Reason to stop (if stopping)
    pub stop_reason: Option<String>,

    /// Permission decision (for PreToolUse)
    pub permission_decision: Option<PermissionDecision>,

    /// Reason for permission decision
    pub permission_decision_reason: Option<String>,

    /// Updated input (for modifying tool input)
    pub updated_input: Option<Value>,

    /// System message to inject
    pub system_message: Option<String>,

    /// Generic reason field
    pub reason: Option<String>,
}

fn default_true() -> bool {
    true
}

/// Permission decision for tool use.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PermissionDecision {
    /// Allow the tool use
    Allow,
    /// Deny the tool use
    Deny,
    /// Ask the user
    Ask,
}

impl std::fmt::Display for PermissionDecision {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            PermissionDecision::Allow => write!(f, "allow"),
            PermissionDecision::Deny => write!(f, "deny"),
            PermissionDecision::Ask => write!(f, "ask"),
        }
    }
}

impl HookOutput {
    /// Create an output that approves/continues.
    pub fn approve() -> Self {
        Self {
            continue_execution: true,
            suppress_output: false,
            stop_reason: None,
            permission_decision: Some(PermissionDecision::Allow),
            permission_decision_reason: None,
            updated_input: None,
            system_message: None,
            reason: None,
        }
    }

    /// Create an output that denies.
    pub fn deny(reason: &str) -> Self {
        Self {
            continue_execution: true,
            suppress_output: false,
            stop_reason: None,
            permission_decision: Some(PermissionDecision::Deny),
            permission_decision_reason: Some(reason.to_string()),
            updated_input: None,
            system_message: None,
            reason: Some(reason.to_string()),
        }
    }

    /// Create an output that asks the user.
    pub fn ask() -> Self {
        Self {
            continue_execution: true,
            suppress_output: false,
            stop_reason: None,
            permission_decision: Some(PermissionDecision::Ask),
            permission_decision_reason: None,
            updated_input: None,
            system_message: None,
            reason: None,
        }
    }

    /// Create an output that stops execution.
    pub fn stop(reason: &str) -> Self {
        Self {
            continue_execution: false,
            suppress_output: false,
            stop_reason: Some(reason.to_string()),
            permission_decision: None,
            permission_decision_reason: None,
            updated_input: None,
            system_message: None,
            reason: Some(reason.to_string()),
        }
    }

    /// Create an empty output (continue with defaults).
    pub fn empty() -> Self {
        Self {
            continue_execution: true,
            suppress_output: false,
            stop_reason: None,
            permission_decision: None,
            permission_decision_reason: None,
            updated_input: None,
            system_message: None,
            reason: None,
        }
    }

    /// Modify the tool input.
    pub fn with_updated_input(mut self, input: Value) -> Self {
        self.updated_input = Some(input);
        self
    }

    /// Add a system message.
    pub fn with_system_message(mut self, message: &str) -> Self {
        self.system_message = Some(message.to_string());
        self
    }

    /// Suppress output.
    pub fn suppress(mut self) -> Self {
        self.suppress_output = true;
        self
    }
}

impl Default for HookOutput {
    fn default() -> Self {
        Self::empty()
    }
}
