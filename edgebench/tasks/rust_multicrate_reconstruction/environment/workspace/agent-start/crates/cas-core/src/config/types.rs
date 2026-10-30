use serde::{Deserialize, Serialize};

use crate::config::{
    AgentConfig, CloudSyncConfig, CoordinationConfig, DevConfig, EmbeddingConfig, FactoryConfig,
    HookConfig, LeaseConfig, McpConfig, NotificationConfig, SyncConfig, TasksConfig,
    VerificationConfig, WorktreesConfig,
};

/// Main configuration struct (core version without UI-specific fields)
///
/// This struct contains all configuration that is CLI-agnostic.
/// UI-specific configuration like themes should be handled by extending
/// this config in the CLI layer.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct Config {
    /// Sync configuration (rules to .claude/rules/)
    #[serde(default)]
    pub sync: SyncConfig,

    /// Cloud sync configuration
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cloud: Option<CloudSyncConfig>,

    /// Hook configuration
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub hooks: Option<HookConfig>,

    /// Task configuration
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub tasks: Option<TasksConfig>,

    /// MCP server configuration
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub mcp: Option<McpConfig>,

    /// Dev mode configuration for tracing
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub dev: Option<DevConfig>,

    /// Embedding daemon configuration
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub embedding: Option<EmbeddingConfig>,

    /// Notification configuration for TUI alerts
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub notifications: Option<NotificationConfig>,

    /// Agent configuration for multi-agent mode
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub agent: Option<AgentConfig>,

    /// Coordination configuration for multi-agent mode
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub coordination: Option<CoordinationConfig>,

    /// Lease configuration for task claiming
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub lease: Option<LeaseConfig>,

    /// Verification configuration for task quality gates
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub verification: Option<VerificationConfig>,

    /// Worktree configuration for automatic git worktree management
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub worktrees: Option<WorktreesConfig>,

    /// Factory mode configuration for multi-agent coordination
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub factory: Option<FactoryConfig>,
}
