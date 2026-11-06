use serde::{Deserialize, Serialize};

/// Per-hook configuration for SessionStart
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionStartHookConfig {
    /// Whether this hook is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Timeout in milliseconds
    #[serde(default = "default_session_start_timeout")]
    pub timeout: u32,

    /// Token budget for context injection (0 = unlimited)
    #[serde(default = "default_token_budget")]
    pub token_budget: usize,

    /// Minimal start mode - only inject blocked tasks and pinned memories
    #[serde(default)]
    pub minimal: bool,
}

fn default_session_start_timeout() -> u32 { todo!() }

impl Default for SessionStartHookConfig {
    fn default() -> Self { todo!() }
}

/// Skip configuration for PostToolUse
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PostToolUseSkipConfig {
    /// Commands to skip capturing (e.g., "ls", "cd", "pwd")
    #[serde(default = "default_skip_commands")]
    pub commands: Vec<String>,

    /// Command prefixes to skip (e.g., "cas ", "cas-")
    #[serde(default = "default_skip_prefixes")]
    pub prefixes: Vec<String>,

    /// Read-only git commands to skip
    #[serde(default = "default_skip_git_readonly")]
    pub git_readonly: Vec<String>,

    /// File extensions to skip for Read observations
    #[serde(default = "default_skip_read_extensions")]
    pub read_extensions: Vec<String>,
}

fn default_skip_commands() -> Vec<String> { todo!() }

fn default_skip_prefixes() -> Vec<String> { todo!() }

fn default_skip_git_readonly() -> Vec<String> { todo!() }

fn default_skip_read_extensions() -> Vec<String> { todo!() }

impl Default for PostToolUseSkipConfig {
    fn default() -> Self { todo!() }
}

/// Per-hook configuration for PostToolUse
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PostToolUseHookConfig {
    /// Whether this hook is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Timeout in milliseconds
    #[serde(default = "default_post_tool_use_timeout")]
    pub timeout: u32,

    /// Tool matcher for Claude Code (pipe-separated)
    #[serde(default = "default_post_tool_use_matcher")]
    pub matcher: Vec<String>,

    /// Tools to capture observations from
    #[serde(default = "default_capture_tools")]
    pub capture_tools: Vec<String>,

    /// Maximum observations to buffer before synthesis
    #[serde(default = "default_max_observations")]
    pub max_observations: usize,

    /// Number of recent observations to keep
    #[serde(default = "default_keep_recent")]
    pub keep_recent: usize,

    /// Skip configuration
    #[serde(default)]
    pub skip: PostToolUseSkipConfig,
}

fn default_post_tool_use_timeout() -> u32 { todo!() }

fn default_post_tool_use_matcher() -> Vec<String> { todo!() }

fn default_max_observations() -> usize { todo!() }

fn default_keep_recent() -> usize { todo!() }

impl Default for PostToolUseHookConfig {
    fn default() -> Self { todo!() }
}

/// Protection configuration for PreToolUse
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreToolUseProtectionConfig {
    /// Whether file protection is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Protected file patterns (e.g., ".env", ".env.*")
    #[serde(default = "default_protected_files")]
    pub files: Vec<String>,

    /// Credential file patterns
    #[serde(default = "default_credential_patterns")]
    pub patterns: Vec<String>,
}

fn default_protected_files() -> Vec<String> { todo!() }

fn default_credential_patterns() -> Vec<String> { todo!() }

impl Default for PreToolUseProtectionConfig {
    fn default() -> Self { todo!() }
}

/// Per-hook configuration for PreToolUse
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreToolUseHookConfig {
    /// Whether this hook is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Timeout in milliseconds
    #[serde(default = "default_pre_tool_use_timeout")]
    pub timeout: u32,

    /// Tool matcher for Claude Code (pipe-separated)
    #[serde(default = "default_pre_tool_use_matcher")]
    pub matcher: Vec<String>,

    /// File protection configuration
    #[serde(default)]
    pub protection: PreToolUseProtectionConfig,
}

fn default_pre_tool_use_timeout() -> u32 { todo!() }

fn default_pre_tool_use_matcher() -> Vec<String> { todo!() }

impl Default for PreToolUseHookConfig {
    fn default() -> Self { todo!() }
}

/// Per-hook configuration for Stop
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StopHookConfig {
    /// Whether this hook is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Timeout in milliseconds
    #[serde(default = "default_stop_timeout")]
    pub timeout: u32,

    /// Block exit when agent has open tasks
    #[serde(default = "default_true")]
    pub block_on_open_tasks: bool,

    /// Generate AI summary at session end
    #[serde(default)]
    pub generate_summary: bool,

    /// Enable learning review at session end (blocks stop if unreviewed learnings exceed threshold)
    #[serde(default)]
    pub learning_review_enabled: bool,

    /// Number of unreviewed learnings required to trigger review (default: 5)
    #[serde(default = "default_learning_review_threshold")]
    pub learning_review_threshold: usize,

    /// Enable rule review at session end (blocks stop if draft rules exceed threshold)
    #[serde(default)]
    pub rule_review_enabled: bool,

    /// Number of draft rules required to trigger review (default: 5)
    #[serde(default = "default_rule_review_threshold")]
    pub rule_review_threshold: usize,

    /// Enable duplicate detection at session end
    #[serde(default)]
    pub duplicate_detection_enabled: bool,

    /// Minimum entries before triggering duplicate detection (default: 20)
    #[serde(default = "default_duplicate_detection_threshold")]
    pub duplicate_detection_threshold: usize,

    /// Enable signals analysis at session end (analyzes friction patterns)
    #[serde(default)]
    pub signals_analysis_enabled: bool,

    /// Number of friction events required to trigger analysis (default: 10)
    #[serde(default = "default_signals_analysis_threshold")]
    pub signals_analysis_threshold: usize,
}

fn default_stop_timeout() -> u32 { todo!() }

fn default_learning_review_threshold() -> usize { todo!() }

fn default_rule_review_threshold() -> usize { todo!() }

fn default_duplicate_detection_threshold() -> usize { todo!() }

fn default_signals_analysis_threshold() -> usize { todo!() }

impl Default for StopHookConfig {
    fn default() -> Self { todo!() }
}

/// Per-hook configuration for UserPromptSubmit
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct UserPromptSubmitHookConfig {
    /// Whether this hook is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Timeout in milliseconds
    #[serde(default = "default_user_prompt_submit_timeout")]
    pub timeout: u32,
}

fn default_user_prompt_submit_timeout() -> u32 { todo!() }

impl Default for UserPromptSubmitHookConfig {
    fn default() -> Self { todo!() }
}

/// Per-hook configuration for PermissionRequest
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PermissionRequestHookConfig {
    /// Whether this hook is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Timeout in milliseconds
    #[serde(default = "default_permission_request_timeout")]
    pub timeout: u32,
}

fn default_permission_request_timeout() -> u32 { todo!() }

impl Default for PermissionRequestHookConfig {
    fn default() -> Self { todo!() }
}

/// Per-hook configuration for PreCompact
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PreCompactHookConfig {
    /// Whether this hook is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Timeout in milliseconds
    #[serde(default = "default_pre_compact_timeout")]
    pub timeout: u32,
}

fn default_pre_compact_timeout() -> u32 { todo!() }

impl Default for PreCompactHookConfig {
    fn default() -> Self { todo!() }
}

/// Per-hook configuration for Notification
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct NotificationHookConfig {
    /// Whether this hook is enabled
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Timeout in milliseconds
    #[serde(default = "default_notification_timeout")]
    pub timeout: u32,

    /// Event matcher
    #[serde(default = "default_notification_matcher")]
    pub matcher: Vec<String>,
}

fn default_notification_timeout() -> u32 { todo!() }

fn default_notification_matcher() -> Vec<String> { todo!() }

impl Default for NotificationHookConfig {
    fn default() -> Self { todo!() }
}

/// Hook configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookConfig {
    /// Whether capture is enabled (legacy, use post_tool_use.enabled)
    #[serde(default = "default_true")]
    pub capture_enabled: bool,

    /// Tools to capture (legacy, use post_tool_use.capture_tools)
    #[serde(default = "default_capture_tools")]
    pub capture_tools: Vec<String>,

    /// Whether to inject context at session start (legacy, use session_start.enabled)
    #[serde(default = "default_true")]
    pub inject_context: bool,

    /// Maximum entries to include in context
    #[serde(default = "default_context_limit")]
    pub context_limit: usize,

    /// Whether to generate AI summaries at session end (legacy, use stop.generate_summary)
    #[serde(default)]
    pub generate_summaries: bool,

    /// Token budget for context injection (legacy, use session_start.token_budget)
    #[serde(default = "default_token_budget")]
    pub token_budget: usize,

    /// Use AI to prioritize context items (requires claude CLI)
    #[serde(default)]
    pub ai_context: bool,

    /// Model to use for AI context prioritization
    #[serde(default = "default_ai_model")]
    pub ai_model: String,

    /// Fall back to non-AI context if AI prioritization fails
    #[serde(default = "default_ai_fallback")]
    pub ai_fallback: bool,

    /// Plan mode specific configuration
    #[serde(default)]
    pub plan_mode: PlanModeConfig,

    /// Minimal start mode (legacy, use session_start.minimal)
    #[serde(default)]
    pub minimal_start: bool,

    // === Per-hook configurations ===
    /// SessionStart hook configuration
    #[serde(default)]
    pub session_start: SessionStartHookConfig,

    /// PostToolUse hook configuration
    #[serde(default)]
    pub post_tool_use: PostToolUseHookConfig,

    /// PreToolUse hook configuration
    #[serde(default)]
    pub pre_tool_use: PreToolUseHookConfig,

    /// Stop hook configuration
    #[serde(default)]
    pub stop: StopHookConfig,

    /// UserPromptSubmit hook configuration
    #[serde(default)]
    pub user_prompt_submit: UserPromptSubmitHookConfig,

    /// PermissionRequest hook configuration
    #[serde(default)]
    pub permission_request: PermissionRequestHookConfig,

    /// PreCompact hook configuration
    #[serde(default)]
    pub pre_compact: PreCompactHookConfig,

    /// Notification hook configuration
    #[serde(default)]
    pub notification: NotificationHookConfig,
}

/// Plan mode specific configuration
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanModeConfig {
    /// Whether to use plan-aware context in plan mode
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Token budget for plan mode (typically higher than execution)
    #[serde(default = "default_plan_token_budget")]
    pub token_budget: usize,

    /// Maximum tasks to show in plan context
    #[serde(default = "default_plan_task_limit")]
    pub task_limit: usize,

    /// Include dependency trees in plan context
    #[serde(default = "default_true")]
    pub show_dependencies: bool,

    /// Include closed tasks for reference
    #[serde(default)]
    pub include_closed: bool,

    /// Search for related memories semantically
    #[serde(default = "default_true")]
    pub semantic_search: bool,
}

fn default_plan_token_budget() -> usize { todo!() }

fn default_plan_task_limit() -> usize { todo!() }

impl Default for PlanModeConfig {
    fn default() -> Self { todo!() }
}

fn default_ai_model() -> String { todo!() }

fn default_ai_fallback() -> bool { todo!() }

fn default_capture_tools() -> Vec<String> { todo!() }

fn default_context_limit() -> usize { todo!() }

fn default_token_budget() -> usize { todo!() }

impl Default for HookConfig {
    fn default() -> Self { todo!() }
}

fn default_true() -> bool { todo!() }
