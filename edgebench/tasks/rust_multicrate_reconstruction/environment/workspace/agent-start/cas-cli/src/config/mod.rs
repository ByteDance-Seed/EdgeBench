//! Configuration management for CAS

pub mod meta;

pub use meta::{ConfigMeta, ConfigRegistry, ConfigType, Constraint, registry};

// Re-export from cas-factory for backward compatibility
pub use cas_factory::AutoPromptConfig;

use crate::error::MemError;
use crate::ui::theme::ThemeConfig;
use serde::{Deserialize, Serialize};

mod hooks;
mod runtime;
mod settings;

pub use hooks::*;
pub use runtime::*;
pub use settings::*;

/// Main configuration struct
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

    /// Dev mode configuration for tracing
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub dev: Option<DevConfig>,

    /// Code indexing configuration
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub code: Option<CodeConfig>,

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

    /// Theme configuration for TUI
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub theme: Option<ThemeConfig>,

    /// Orchestration configuration for multi-agent sessions
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub orchestration: Option<OrchestrationConfig>,

    /// Factory mode configuration for supervisor task assignment
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub factory: Option<FactoryConfig>,

    /// Telemetry configuration for anonymous usage tracking and crash reporting
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub telemetry: Option<TelemetryConfig>,

    /// Logging configuration for file-based logging
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub logging: Option<crate::logging::LoggingConfig>,

    /// LLM configuration for harness and model selection
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub llm: Option<LlmConfig>,
}

mod access;
pub use access::{
    get_telemetry_consent, global_cas_dir, load_global_config, prompt_telemetry_consent,
    save_global_config, set_telemetry_consent,
};

#[cfg(test)]
mod mod_tests;
