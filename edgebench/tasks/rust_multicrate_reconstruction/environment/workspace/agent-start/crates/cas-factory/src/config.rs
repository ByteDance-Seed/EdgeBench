//! Configuration types for factory mode.

use std::path::PathBuf;

use serde::{Deserialize, Serialize};

/// State of the current epic workflow
#[derive(Debug, Clone, Default)]
pub enum EpicState {
    /// No epic active
    #[default]
    Idle,
    /// Epic is in progress
    Active { epic_id: String, epic_title: String },
    /// All tasks done, awaiting merge
    Completing { epic_id: String, epic_title: String },
}

impl EpicState {
    /// Get the current epic ID, if any
    pub fn epic_id(&self) -> Option<&str> { todo!() }

    /// Get the current epic title, if any
    pub fn epic_title(&self) -> Option<&str> { todo!() }

    /// Check if an epic is active (either in progress or completing)
    pub fn is_active(&self) -> bool { todo!() }
}

/// Notification backend
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NotifyBackend {
    /// Native cross-platform notifications via notify-rust
    /// Works on macOS, Linux, and Windows
    Native,
    /// Terminal bell (\x07)
    Bell,
    /// iTerm2 inline notification (\e]9;...\a)
    ITerm2,
}

impl NotifyBackend {
    /// Detect the best notification backend for the current system
    pub fn detect() -> Self { todo!() }
}

/// Notification configuration
#[derive(Debug, Clone)]
pub struct NotifyConfig {
    /// Whether notifications are enabled
    pub enabled: bool,
    /// Backend to use
    pub backend: NotifyBackend,
    /// Also ring terminal bell (in addition to system notification)
    pub also_bell: bool,
}

impl Default for NotifyConfig {
    fn default() -> Self { todo!() }
}

fn default_true() -> bool { todo!() }

/// Auto-prompting configuration for factory mode events
///
/// Controls which events trigger automatic prompt injection into agent terminals.
/// Set `enabled = false` to disable all auto-prompting globally.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AutoPromptConfig {
    /// Master switch: enable/disable all auto-prompting (default: true)
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Prompt worker when a task is assigned to them (default: true)
    #[serde(default = "default_true")]
    pub on_task_assigned: bool,

    /// Prompt supervisor when a worker completes a task (default: true)
    #[serde(default = "default_true")]
    pub on_task_completed: bool,

    /// Prompt supervisor when a worker is blocked (default: true)
    #[serde(default = "default_true")]
    pub on_task_blocked: bool,

    /// Prompt supervisor when a worker becomes idle (default: true)
    #[serde(default = "default_true")]
    pub on_worker_idle: bool,

    /// Prompt supervisor when an epic is completed (default: true)
    #[serde(default = "default_true")]
    pub on_epic_completed: bool,

    /// Prompt supervisor when a worker registers and is ready (default: true)
    #[serde(default = "default_true")]
    pub on_worker_ready: bool,
}

impl Default for AutoPromptConfig {
    fn default() -> Self { todo!() }
}

/// Configuration for the factory TUI
#[derive(Debug, Clone)]
pub struct FactoryConfig {
    /// Working directory for all agents (main repo)
    pub cwd: PathBuf,
    /// Number of worker agents
    pub workers: usize,
    /// Custom worker names (optional)
    pub worker_names: Vec<String>,
    /// Custom supervisor name (optional)
    pub supervisor_name: Option<String>,
    /// Supervisor CLI (codex, claude, or pi)
    pub supervisor_cli: cas_mux::SupervisorCli,
    /// Worker CLI (codex, claude, or pi)
    pub worker_cli: cas_mux::SupervisorCli,
    /// Model for supervisor (passed as --model flag to CLI)
    pub supervisor_model: Option<String>,
    /// Model for workers (passed as --model flag to CLI)
    pub worker_model: Option<String>,
    /// Enable worktree-based worker isolation (default: true)
    pub enable_worktrees: bool,
    /// Directory where worker worktrees are created (default: ../cas-worktrees)
    pub worktree_root: Option<PathBuf>,
    /// Notification configuration
    pub notify: NotifyConfig,
    /// Use tabbed worker view instead of side-by-side (default: false)
    pub tabbed_workers: bool,
    /// Auto-prompting configuration
    pub auto_prompt: AutoPromptConfig,
    /// Enable terminal recording for time-travel playback
    pub record: bool,
    /// Session identifier for recordings (set when record=true)
    pub session_id: Option<String>,
    /// Per-agent Teams spawn configs (agent_name -> config).
    /// When set, agents are spawned with native Agent Teams CLI flags.
    pub teams_configs: std::collections::HashMap<String, cas_mux::TeamsSpawnConfig>,
    /// UUID for the team lead's Claude Code session.
    /// Used as `leadSessionId` in config.json and passed as `--session-id` to the supervisor.
    pub lead_session_id: Option<String>,
}

impl Default for FactoryConfig {
    fn default() -> Self { todo!() }
}
