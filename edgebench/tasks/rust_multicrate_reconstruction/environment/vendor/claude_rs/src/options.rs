//! Query options and configuration.

use crate::hook::Hook;
use crate::tool::Tool;
use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::path::PathBuf;
use std::sync::Arc;

/// Custom permission callback for tool usage.
///
/// Called before each tool execution to determine if it should be allowed.
/// Returns a `PermissionResult` indicating whether to allow or deny the tool use.
pub type CanUseToolCallback = Arc<
    dyn Fn(
            CanUseToolRequest,
        ) -> std::pin::Pin<Box<dyn std::future::Future<Output = PermissionResult> + Send>>
        + Send
        + Sync,
>;

/// Request data for permission callback.
#[derive(Debug, Clone)]
pub struct CanUseToolRequest {
    /// Name of the tool being requested
    pub tool_name: String,
    /// Input parameters for the tool
    pub input: Value,
    /// Suggested permission updates (raw JSON value)
    pub suggestions: Option<Value>,
    /// File path that triggered the request (if applicable)
    pub blocked_path: Option<String>,
    /// Reason for the permission request
    pub decision_reason: Option<String>,
    /// Unique identifier for this tool call
    pub tool_use_id: String,
    /// Sub-agent ID if running in sub-agent context
    pub agent_id: Option<String>,
}

/// Result of a permission check.
#[derive(Debug, Clone)]
pub enum PermissionResult {
    /// Allow the tool execution
    Allow {
        /// Updated input to use (if modified)
        updated_input: Option<Value>,
        /// Permission updates to apply
        updated_permissions: Option<Vec<PermissionUpdate>>,
    },
    /// Deny the tool execution
    Deny {
        /// Reason for denial or guidance
        message: String,
        /// Whether to interrupt execution entirely
        interrupt: bool,
    },
}

impl PermissionResult {
    /// Create an allow result with no modifications.
    pub fn allow() -> Self {
        Self::Allow {
            updated_input: None,
            updated_permissions: None,
        }
    }

    /// Create an allow result with updated input.
    pub fn allow_with_input(input: Value) -> Self {
        Self::Allow {
            updated_input: Some(input),
            updated_permissions: None,
        }
    }

    /// Create a deny result.
    pub fn deny(message: impl Into<String>) -> Self {
        Self::Deny {
            message: message.into(),
            interrupt: false,
        }
    }

    /// Create a deny result that interrupts execution.
    pub fn deny_and_interrupt(message: impl Into<String>) -> Self {
        Self::Deny {
            message: message.into(),
            interrupt: true,
        }
    }
}

/// Permission update to apply.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "camelCase")]
pub enum PermissionUpdate {
    /// Add permission rules
    AddRules {
        rules: Vec<PermissionRule>,
        behavior: PermissionBehavior,
        destination: PermissionDestination,
    },
    /// Replace permission rules
    ReplaceRules {
        rules: Vec<PermissionRule>,
        behavior: PermissionBehavior,
        destination: PermissionDestination,
    },
    /// Remove permission rules
    RemoveRules {
        rules: Vec<PermissionRule>,
        behavior: PermissionBehavior,
        destination: PermissionDestination,
    },
    /// Set permission mode
    SetMode {
        mode: PermissionMode,
        destination: PermissionDestination,
    },
    /// Add directories
    AddDirectories {
        directories: Vec<String>,
        destination: PermissionDestination,
    },
    /// Remove directories
    RemoveDirectories {
        directories: Vec<String>,
        destination: PermissionDestination,
    },
}

/// Permission rule value.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct PermissionRule {
    /// Tool name the rule applies to
    pub tool_name: String,
    /// Rule content (pattern or path)
    pub rule_content: Option<String>,
}

/// Permission behavior.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum PermissionBehavior {
    Allow,
    Deny,
    Ask,
}

/// Destination for permission updates.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum PermissionDestination {
    UserSettings,
    ProjectSettings,
    LocalSettings,
    Session,
    CliArg,
}

/// Sandbox configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SandboxSettings {
    /// Enable sandbox mode
    #[serde(skip_serializing_if = "Option::is_none")]
    pub enabled: Option<bool>,
    /// Auto-allow bash if sandboxed
    #[serde(skip_serializing_if = "Option::is_none")]
    pub auto_allow_bash_if_sandboxed: Option<bool>,
    /// Network configuration
    #[serde(skip_serializing_if = "Option::is_none")]
    pub network: Option<SandboxNetworkConfig>,
    /// Violations to ignore
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ignore_violations: Option<SandboxIgnoreViolations>,
}

/// Sandbox network configuration.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SandboxNetworkConfig {
    /// Allow local binding
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_local_binding: Option<bool>,
    /// Allow specific Unix sockets
    #[serde(skip_serializing_if = "Option::is_none")]
    pub allow_unix_sockets: Option<Vec<String>>,
}

/// Sandbox violations to ignore.
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SandboxIgnoreViolations {
    /// Paths to ignore
    #[serde(skip_serializing_if = "Option::is_none")]
    pub paths: Option<Vec<String>>,
}

/// Agent definition for custom subagents.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct AgentDefinition {
    /// Natural language description of when to use this agent
    pub description: String,
    /// The agent's system prompt
    pub prompt: String,
    /// Allowed tool names (inherits all if omitted)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub tools: Option<Vec<String>>,
    /// Disallowed tool names
    #[serde(skip_serializing_if = "Option::is_none")]
    pub disallowed_tools: Option<Vec<String>>,
    /// Model to use ('sonnet', 'opus', 'haiku', or 'inherit')
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,
}

/// Plugin configuration.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(tag = "type", rename_all = "camelCase")]
pub enum PluginConfig {
    /// Local plugin from filesystem
    Local {
        /// Path to plugin directory
        path: String,
    },
}

/// Options for configuring a Claude query.
#[derive(Default, Clone)]
pub struct QueryOptions {
    // Core options
    /// Model to use (e.g., "claude-sonnet-4-5-20250929")
    pub model: Option<String>,

    /// System prompt configuration
    pub system_prompt: Option<SystemPrompt>,

    /// Maximum number of conversation turns
    pub max_turns: Option<u32>,

    /// Maximum thinking tokens for extended thinking
    pub max_thinking_tokens: Option<u32>,

    /// Maximum budget in USD
    pub max_budget_usd: Option<f64>,

    /// Working directory for the query
    pub cwd: Option<PathBuf>,

    // Permission options
    /// Permission mode for tool execution
    pub permission_mode: Option<PermissionMode>,

    /// Skip all permission checks (dangerous!)
    /// Must set `allow_dangerously_skip_permissions` to true
    pub dangerously_skip_permissions: bool,

    /// Safety flag required when using bypassPermissions mode
    pub allow_dangerously_skip_permissions: bool,

    /// Custom permission callback
    pub can_use_tool: Option<CanUseToolCallback>,

    /// MCP tool name for permission prompts
    pub permission_prompt_tool_name: Option<String>,

    /// Fallback model if primary fails
    pub fallback_model: Option<String>,

    // Tools and hooks
    /// Custom tools to register
    pub tools: Vec<Tool>,

    /// Hooks for intercepting events
    pub hooks: Vec<Hook>,

    /// Tools allowed for this query
    pub allowed_tools: Vec<String>,

    /// Tools disallowed for this query
    pub disallowed_tools: Vec<String>,

    // MCP configuration
    /// Path to MCP config file
    pub mcp_config: Option<PathBuf>,

    /// Strict MCP config validation
    pub strict_mcp_config: bool,

    // Session options
    /// Continue the last session
    pub continue_session: bool,

    /// Resume a specific session by ID
    pub resume: Option<String>,

    /// Resume up to a specific message UUID
    pub resume_at: Option<String>,

    /// Fork the session on resume
    pub fork_session: bool,

    /// Persist session to disk (default: true)
    pub persist_session: Option<bool>,

    /// Enable file checkpointing for rewind support
    pub enable_file_checkpointing: bool,

    // Output options
    /// Include partial/streaming messages
    pub include_partial_messages: bool,

    /// JSON schema for structured output
    pub output_schema: Option<Value>,

    // Advanced options
    /// Agent definitions (map of name -> definition)
    pub agents: Option<HashMap<String, AgentDefinition>>,

    /// Plugin configurations
    pub plugins: Option<Vec<PluginConfig>>,

    /// Sandbox configuration
    pub sandbox: Option<SandboxSettings>,

    /// Setting sources to use ('user', 'project', 'local')
    pub setting_sources: Vec<SettingSource>,

    /// Additional directories to allow
    pub additional_directories: Vec<PathBuf>,

    /// Beta features to enable
    pub betas: Vec<String>,

    /// Extra arguments to pass through
    pub extra_args: Vec<String>,

    /// Environment variables to pass to CLI
    pub env: Option<HashMap<String, String>>,

    // Internal options
    /// Enable streaming input mode
    pub(crate) streaming_input: bool,

    /// Enable mock mode (for testing)
    pub mock: bool,

    /// Include replay messages
    pub include_replays: bool,
}

impl std::fmt::Debug for QueryOptions {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("QueryOptions")
            .field("model", &self.model)
            .field("system_prompt", &self.system_prompt)
            .field("max_turns", &self.max_turns)
            .field("max_thinking_tokens", &self.max_thinking_tokens)
            .field("max_budget_usd", &self.max_budget_usd)
            .field("cwd", &self.cwd)
            .field("permission_mode", &self.permission_mode)
            .field(
                "dangerously_skip_permissions",
                &self.dangerously_skip_permissions,
            )
            .field(
                "allow_dangerously_skip_permissions",
                &self.allow_dangerously_skip_permissions,
            )
            .field(
                "can_use_tool",
                &self.can_use_tool.as_ref().map(|_| "<callback>"),
            )
            .field("fallback_model", &self.fallback_model)
            .field("tools", &self.tools.len())
            .field("hooks", &self.hooks.len())
            .field("allowed_tools", &self.allowed_tools)
            .field("disallowed_tools", &self.disallowed_tools)
            .field("mcp_config", &self.mcp_config)
            .field("continue_session", &self.continue_session)
            .field("resume", &self.resume)
            .field("fork_session", &self.fork_session)
            .field("persist_session", &self.persist_session)
            .field("enable_file_checkpointing", &self.enable_file_checkpointing)
            .field("include_partial_messages", &self.include_partial_messages)
            .field("output_schema", &self.output_schema.is_some())
            .field("agents", &self.agents.is_some())
            .field("plugins", &self.plugins.is_some())
            .field("sandbox", &self.sandbox.is_some())
            .field("setting_sources", &self.setting_sources)
            .field("additional_directories", &self.additional_directories)
            .field("betas", &self.betas)
            .field("env", &self.env.is_some())
            .field("mock", &self.mock)
            .finish()
    }
}

/// Setting source for loading configuration.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SettingSource {
    /// Global user settings (~/.claude/settings.json)
    User,
    /// Project settings (.claude/settings.json)
    Project,
    /// Local settings (.claude/settings.local.json)
    Local,
}

impl SettingSource {
    /// Convert to CLI argument value.
    pub fn to_cli_arg(&self) -> &'static str {
        match self {
            SettingSource::User => "user",
            SettingSource::Project => "project",
            SettingSource::Local => "local",
        }
    }
}

impl QueryOptions {
    /// Create a new QueryOptions with defaults.
    pub fn new() -> Self {
        Self::default()
    }

    /// Set the model.
    pub fn model(mut self, model: impl Into<String>) -> Self {
        self.model = Some(model.into());
        self
    }

    /// Set the system prompt.
    pub fn system_prompt(mut self, prompt: SystemPrompt) -> Self {
        self.system_prompt = Some(prompt);
        self
    }

    /// Set max turns.
    pub fn max_turns(mut self, turns: u32) -> Self {
        self.max_turns = Some(turns);
        self
    }

    /// Set max thinking tokens.
    pub fn max_thinking_tokens(mut self, tokens: u32) -> Self {
        self.max_thinking_tokens = Some(tokens);
        self
    }

    /// Set max budget.
    pub fn max_budget_usd(mut self, budget: f64) -> Self {
        self.max_budget_usd = Some(budget);
        self
    }

    /// Set the working directory.
    pub fn cwd(mut self, path: impl Into<PathBuf>) -> Self {
        self.cwd = Some(path.into());
        self
    }

    /// Set permission mode.
    pub fn permission_mode(mut self, mode: PermissionMode) -> Self {
        self.permission_mode = Some(mode);
        self
    }

    /// Add a tool.
    pub fn tool(mut self, tool: Tool) -> Self {
        self.tools.push(tool);
        self
    }

    /// Add multiple tools.
    pub fn tools(mut self, tools: impl IntoIterator<Item = Tool>) -> Self {
        self.tools.extend(tools);
        self
    }

    /// Add a hook.
    pub fn hook(mut self, hook: Hook) -> Self {
        self.hooks.push(hook);
        self
    }

    /// Add multiple hooks.
    pub fn hooks(mut self, hooks: impl IntoIterator<Item = Hook>) -> Self {
        self.hooks.extend(hooks);
        self
    }

    /// Allow specific tools.
    pub fn allow_tool(mut self, tool: impl Into<String>) -> Self {
        self.allowed_tools.push(tool.into());
        self
    }

    /// Disallow specific tools.
    pub fn disallow_tool(mut self, tool: impl Into<String>) -> Self {
        self.disallowed_tools.push(tool.into());
        self
    }

    /// Resume a session.
    pub fn resume_session(mut self, session_id: impl Into<String>) -> Self {
        self.resume = Some(session_id.into());
        self
    }

    /// Continue the last session.
    pub fn continue_last(mut self) -> Self {
        self.continue_session = true;
        self
    }

    /// Fork on resume.
    pub fn fork(mut self) -> Self {
        self.fork_session = true;
        self
    }

    /// Include partial messages in the stream.
    pub fn include_partials(mut self) -> Self {
        self.include_partial_messages = true;
        self
    }

    /// Include replay messages in the stream.
    pub fn include_replays(mut self) -> Self {
        self.include_replays = true;
        self
    }

    /// Set structured output schema.
    pub fn output_schema(mut self, schema: Value) -> Self {
        self.output_schema = Some(schema);
        self
    }

    /// Enable a beta feature.
    pub fn beta(mut self, feature: impl Into<String>) -> Self {
        self.betas.push(feature.into());
        self
    }

    /// Enable mock mode.
    pub fn mock(mut self) -> Self {
        self.mock = true;
        self
    }

    /// Set fallback model.
    pub fn fallback_model(mut self, model: impl Into<String>) -> Self {
        self.fallback_model = Some(model.into());
        self
    }

    /// Add an additional directory.
    pub fn add_directory(mut self, path: impl Into<PathBuf>) -> Self {
        self.additional_directories.push(path.into());
        self
    }

    /// Set sandbox configuration.
    pub fn sandbox(mut self, settings: SandboxSettings) -> Self {
        self.sandbox = Some(settings);
        self
    }

    /// Add an agent definition.
    pub fn agent(mut self, name: impl Into<String>, definition: AgentDefinition) -> Self {
        self.agents
            .get_or_insert_with(HashMap::new)
            .insert(name.into(), definition);
        self
    }

    /// Add a plugin.
    pub fn plugin(mut self, config: PluginConfig) -> Self {
        self.plugins.get_or_insert_with(Vec::new).push(config);
        self
    }

    /// Set custom permission callback.
    pub fn can_use_tool<F, Fut>(mut self, callback: F) -> Self
    where
        F: Fn(CanUseToolRequest) -> Fut + Send + Sync + 'static,
        Fut: std::future::Future<Output = PermissionResult> + Send + 'static,
    {
        self.can_use_tool = Some(Arc::new(move |req| Box::pin(callback(req))));
        self
    }

    /// Set environment variables.
    pub fn env(mut self, vars: HashMap<String, String>) -> Self {
        self.env = Some(vars);
        self
    }

    /// Add an environment variable.
    pub fn env_var(mut self, key: impl Into<String>, value: impl Into<String>) -> Self {
        self.env
            .get_or_insert_with(HashMap::new)
            .insert(key.into(), value.into());
        self
    }

    /// Enable file checkpointing.
    pub fn enable_file_checkpointing(mut self) -> Self {
        self.enable_file_checkpointing = true;
        self
    }

    /// Set persist session option.
    pub fn persist_session(mut self, persist: bool) -> Self {
        self.persist_session = Some(persist);
        self
    }

    /// Resume at a specific message UUID.
    pub fn resume_at(mut self, message_uuid: impl Into<String>) -> Self {
        self.resume_at = Some(message_uuid.into());
        self
    }

    /// Add a setting source.
    pub fn setting_source(mut self, source: SettingSource) -> Self {
        self.setting_sources.push(source);
        self
    }

    /// Add extra CLI argument.
    pub fn extra_arg(mut self, arg: impl Into<String>) -> Self {
        self.extra_args.push(arg.into());
        self
    }

    /// Set MCP config path.
    pub fn mcp_config(mut self, path: impl Into<PathBuf>) -> Self {
        self.mcp_config = Some(path.into());
        self
    }

    /// Enable strict MCP config validation.
    pub fn strict_mcp_config(mut self) -> Self {
        self.strict_mcp_config = true;
        self
    }

    /// Set permission prompt tool name.
    pub fn permission_prompt_tool(mut self, tool_name: impl Into<String>) -> Self {
        self.permission_prompt_tool_name = Some(tool_name.into());
        self
    }

    /// Enable dangerous permission bypass (requires explicit opt-in).
    pub fn bypass_permissions(mut self, allow_dangerous: bool) -> Self {
        self.dangerously_skip_permissions = true;
        self.allow_dangerously_skip_permissions = allow_dangerous;
        self
    }
}

/// System prompt configuration.
#[derive(Debug, Clone)]
pub enum SystemPrompt {
    /// Custom text system prompt
    Text(String),
    /// Use a preset (e.g., "claude_code")
    Preset(String),
    /// Append to default system prompt
    Append(String),
}

impl SystemPrompt {
    /// Create a text system prompt.
    pub fn text(prompt: impl Into<String>) -> Self {
        Self::Text(prompt.into())
    }

    /// Create a preset system prompt.
    pub fn preset(name: impl Into<String>) -> Self {
        Self::Preset(name.into())
    }

    /// Create an appended system prompt.
    pub fn append(text: impl Into<String>) -> Self {
        Self::Append(text.into())
    }
}

/// Permission mode for tool execution.
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub enum PermissionMode {
    /// Default - ask for permission on sensitive operations
    #[default]
    Default,
    /// Accept file edits without prompting
    AcceptEdits,
    /// Bypass all permission checks
    BypassPermissions,
    /// Plan mode - propose changes without executing
    Plan,
    /// Don't ask for confirmation, just do it
    DontAsk,
}

impl PermissionMode {
    /// Convert to CLI argument value.
    pub fn to_cli_arg(&self) -> &'static str {
        match self {
            PermissionMode::Default => "default",
            PermissionMode::AcceptEdits => "acceptEdits",
            PermissionMode::BypassPermissions => "bypassPermissions",
            PermissionMode::Plan => "plan",
            PermissionMode::DontAsk => "dontAsk",
        }
    }
}
