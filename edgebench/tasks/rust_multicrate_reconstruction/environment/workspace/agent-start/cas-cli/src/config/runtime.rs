use serde::{Deserialize, Serialize};

/// Worktree configuration for automatic git worktree management
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WorktreesConfig {
    /// Whether automatic worktree creation is enabled on task start
    #[serde(default)]
    pub enabled: bool,

    /// Base directory for worktrees (relative to repo root's parent)
    /// Supports {project} placeholder for project name
    #[serde(default = "default_worktree_base_path")]
    pub base_path: String,

    /// Prefix for branch names (e.g., "cas/")
    #[serde(default = "default_worktree_branch_prefix")]
    pub branch_prefix: String,

    /// Auto-merge branch on task close (if no conflicts)
    #[serde(default)]
    pub auto_merge: bool,

    /// Auto-cleanup worktree directory on task close
    #[serde(default = "default_true")]
    pub cleanup_on_close: bool,

    /// Promote entries with positive feedback to global scope on merge
    #[serde(default = "default_true")]
    pub promote_entries_on_merge: bool,

    /// Require worktree merge before epic close (triggers worktree-merger jail)
    /// When true (default), closing an epic with an active worktree requires
    /// spawning the worktree-merger agent first. Set to false to allow closing
    /// epics without merging their worktrees.
    #[serde(default = "default_true")]
    pub require_merge_on_epic_close: bool,
}

fn default_worktree_base_path() -> String { todo!() }

fn default_worktree_branch_prefix() -> String { todo!() }

impl Default for WorktreesConfig {
    fn default() -> Self { todo!() }
}

impl WorktreesConfig {
    /// Resolve base_path with {project} placeholder substitution.
    ///
    /// The {project} placeholder is replaced with the project directory name.
    /// Relative paths are resolved relative to the project's parent directory.
    pub fn resolve_base_path(&self, project_dir: &std::path::Path) -> std::path::PathBuf { todo!() }
}

/// Verification configuration for task quality gates
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationConfig {
    /// Whether verification is enabled on task close
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Model to use for verification (Haiku recommended for speed)
    #[serde(default = "default_verification_model")]
    pub model: String,

    /// Allow force bypass of verification (--force flag)
    #[serde(default)]
    pub force_bypass_allowed: bool,

    /// Maximum time for verification (seconds)
    #[serde(default = "default_verification_timeout")]
    pub timeout_secs: u64,

    /// Pattern detection configuration
    #[serde(default)]
    pub patterns: VerificationPatterns,
}

/// Patterns to detect during verification
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct VerificationPatterns {
    /// Detect TODO/FIXME comments
    #[serde(default = "default_true")]
    pub todo_comments: bool,

    /// Detect temporal shortcuts ("for now", "temporarily", etc.)
    #[serde(default = "default_true")]
    pub temporal_shortcuts: bool,

    /// Detect stub implementations
    #[serde(default = "default_true")]
    pub stub_implementations: bool,

    /// Detect empty catch/error blocks
    #[serde(default = "default_true")]
    pub empty_error_handlers: bool,

    /// Custom patterns to detect (regex)
    #[serde(default)]
    pub custom: Vec<String>,
}

fn default_verification_model() -> String { todo!() }

fn default_verification_timeout() -> u64 { todo!() }

impl Default for VerificationPatterns {
    fn default() -> Self { todo!() }
}

impl Default for VerificationConfig {
    fn default() -> Self { todo!() }
}

/// Agent configuration for multi-agent coordination
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentConfig {
    /// Human-readable name for this agent
    #[serde(default = "default_agent_name")]
    pub name: String,

    /// Maximum concurrent tasks this agent can claim
    #[serde(default = "default_max_concurrent_tasks")]
    pub max_concurrent_tasks: u32,

    /// Capabilities this agent advertises
    #[serde(default)]
    pub capabilities: Vec<String>,
}

fn default_agent_name() -> String { todo!() }

fn default_max_concurrent_tasks() -> u32 { todo!() }

impl Default for AgentConfig {
    fn default() -> Self { todo!() }
}

/// Coordination mode for multi-agent setup
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
#[serde(rename_all = "lowercase")]
pub enum CoordinationMode {
    /// Local SQLite-based coordination (single machine)
    Local,
    /// Cloud PostgreSQL-based coordination (distributed)
    Cloud,
}

impl Default for CoordinationMode {
    fn default() -> Self { todo!() }
}

/// Coordination configuration for multi-agent mode
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CoordinationConfig {
    /// Coordination mode: local (SQLite) or cloud (PostgreSQL)
    #[serde(default)]
    pub mode: CoordinationMode,

    /// Cloud coordination URL (only used when mode is Cloud)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cloud_url: Option<String>,
}

impl Default for CoordinationConfig {
    fn default() -> Self { todo!() }
}

/// Lease configuration for task claiming
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LeaseConfig {
    /// Default lease duration in minutes
    #[serde(default = "default_lease_duration")]
    pub default_duration_mins: u32,

    /// Maximum lease duration in minutes
    #[serde(default = "default_max_lease_duration")]
    pub max_duration_mins: u32,

    /// Heartbeat interval in seconds
    #[serde(default = "default_heartbeat_interval")]
    pub heartbeat_interval_secs: u32,

    /// Grace period after expiry before reclaiming (seconds)
    #[serde(default = "default_expiry_grace")]
    pub expiry_grace_secs: u32,
}

fn default_lease_duration() -> u32 { todo!() }

fn default_max_lease_duration() -> u32 { todo!() }

fn default_heartbeat_interval() -> u32 { todo!() }

fn default_expiry_grace() -> u32 { todo!() }

impl Default for LeaseConfig {
    fn default() -> Self { todo!() }
}

fn default_true() -> bool { todo!() }
