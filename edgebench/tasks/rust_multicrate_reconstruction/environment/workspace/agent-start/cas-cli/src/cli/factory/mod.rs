//! Factory session management
//!
//! Spawns a native terminal multiplexer TUI with:
//! - Director (native panel) - monitors events, displays tasks/agents/activity
//! - Supervisor - plans epics, assigns tasks, handles merges
//! - Workers - execute tasks (read-only, inject only)

mod cloud_attach;
mod daemon;
mod lifecycle;
mod queries;
mod remote_attach;
mod worktree_ops;

use crate::cli::Cli;
use crate::config::Config;
use crate::orchestration::names::generate_unique;
use crate::ui::factory::{
    FactoryConfig, NotifyBackend, NotifyConfig, attach, find_session_for_project,
    generate_session_name,
};
use crate::worktree::GitOperations;
use anyhow::{Result, bail};
use clap::{Args, Subcommand};
use std::io::IsTerminal;

pub use lifecycle::{execute_kill, execute_kill_all};
pub use queries::execute_list;

/// Launch hierarchical multi-agent factory session
#[derive(Args, Debug, Clone)]
pub struct FactoryArgs {
    /// Factory subcommand
    #[command(subcommand)]
    pub command: Option<FactoryCommands>,

    /// Number of worker agents (default: 0 for supervisor-only startup)
    #[arg(long, short = 'w', default_value = "0", global = true)]
    pub workers: u8,

    /// Custom session name
    #[arg(long, short = 'n', global = true)]
    pub name: Option<String>,

    /// Start a new session instead of auto-attaching an existing one
    #[arg(long = "new", global = true)]
    pub start_new: bool,

    /// Disable worktree-based worker isolation (all agents share the same directory)
    #[arg(long, global = true)]
    pub no_worktrees: bool,

    /// Custom directory for worker worktrees (default: .cas/worktrees under project)
    #[arg(long, global = true)]
    pub worktree_root: Option<std::path::PathBuf>,

    /// Remove all worker worktree directories
    #[arg(long, conflicts_with = "workers")]
    pub cleanup: bool,

    /// Show what would be removed without actually deleting (use with --cleanup)
    #[arg(long, requires = "cleanup")]
    pub dry_run: bool,

    /// Force cleanup without confirmation (use with --cleanup)
    #[arg(long, short = 'f', requires = "cleanup")]
    pub force: bool,

    /// Run daemon in foreground (no fork) instead of attaching
    #[arg(long, hide = true)]
    pub legacy: bool,

    /// Enable desktop/terminal notifications for task events
    #[arg(long)]
    pub notify: bool,

    /// Also ring terminal bell on notifications (use with --notify)
    #[arg(long, requires = "notify")]
    pub bell: bool,

    /// Use tabbed worker view instead of side-by-side (default: side-by-side)
    #[arg(long, global = true)]
    pub tabbed: bool,

    /// Record terminal sessions for time-travel playback (requires factory-recording feature)
    #[arg(long, global = true)]
    pub record: bool,

    /// Supervisor CLI to use (claude, codex, or pi)
    #[arg(long, default_value = "claude")]
    pub supervisor_cli: String,

    /// Worker CLI to use (claude, codex, or pi)
    #[arg(long, default_value = "claude")]
    pub worker_cli: String,

    /// Disable cloud phone-home (push factory state to CAS Cloud)
    #[arg(long, global = true)]
    pub no_phone_home: bool,
}

impl Default for FactoryArgs {
    fn default() -> Self { todo!() }
}

/// Arguments for `cas attach`
#[derive(Args, Debug, Clone)]
pub struct AttachArgs {
    /// Session name to attach to (default: most recent)
    pub name: Option<String>,

    /// Remote target: `device:factory-id` (SSH) or `factory-id` (cloud relay)
    #[arg(long)]
    pub remote: Option<String>,

    /// Specific worker to focus on (used with --remote)
    #[arg(long)]
    pub worker: Option<String>,
}

/// Arguments for `cas kill`
#[derive(Args, Debug, Clone)]
pub struct KillArgs {
    /// Session name to kill (interactive picker if omitted)
    pub name: Option<String>,

    /// Force kill without confirmation
    #[arg(long, short = 'f')]
    pub force: bool,
}

/// Arguments for `cas kill-all`
#[derive(Args, Debug, Clone)]
pub struct KillAllArgs {
    /// Force kill without confirmation
    #[arg(long, short = 'f')]
    pub force: bool,
}

/// Internal factory subcommands (hidden from help)
#[derive(Subcommand, Debug, Clone)]
pub enum FactoryCommands {
    /// Run as a factory daemon (internal use)
    #[command(hide = true)]
    Daemon {
        /// Session name
        #[arg(long)]
        session: String,

        /// Working directory
        #[arg(long)]
        cwd: std::path::PathBuf,

        /// Number of workers
        #[arg(long, default_value = "0")]
        workers: u8,

        /// Disable worktree-based worker isolation
        #[arg(long)]
        no_worktrees: bool,

        /// Custom directory for worker worktrees
        #[arg(long)]
        worktree_root: Option<std::path::PathBuf>,

        /// Enable notifications
        #[arg(long)]
        notify: bool,

        /// Supervisor CLI to use (claude, codex, or pi)
        #[arg(long, default_value = "claude")]
        supervisor_cli: String,

        /// Worker CLI to use (claude, codex, or pi)
        #[arg(long, default_value = "claude")]
        worker_cli: String,

        /// Use tabbed worker view
        #[arg(long)]
        tabbed: bool,

        /// Record terminal sessions
        #[arg(long)]
        record: bool,

        /// Run in foreground
        #[arg(long)]
        foreground: bool,

        /// Disable cloud phone-home
        #[arg(long)]
        no_phone_home: bool,

        /// Stream boot initialization progress via socket before attach (internal use)
        #[arg(long, hide = true)]
        boot_progress: bool,

        /// Explicit supervisor name (internal use)
        #[arg(long, hide = true)]
        supervisor_name: Option<String>,

        /// Explicit worker names (internal use, repeat per worker)
        #[arg(long = "worker-name", hide = true)]
        worker_names: Vec<String>,
    },

    /// Check if worktree is behind its sync target (used as SessionStart hook)
    CheckStaleness {
        /// Target branch to check against (auto-detected if not specified)
        #[arg(long, short = 'b')]
        branch: Option<String>,

        /// Fetch from remote before checking
        #[arg(long)]
        fetch: bool,
    },

    /// Sync worktree to its sync target (fetches when target is remote-tracking)
    Sync {
        /// Target branch to sync to (auto-detected if not specified)
        #[arg(long, short = 'b')]
        branch: Option<String>,
    },

    /// List known sessions (JSON-friendly; prefer `cas list --json`)
    Sessions {
        /// Only show sessions that can currently be attached to
        #[arg(long)]
        attachable_only: bool,
    },

    /// Show agent status for a session (reads CAS AgentStore; does not attach)
    Agents {
        /// Session name (default: most recent attachable session for this project)
        #[arg(long)]
        session: Option<String>,

        /// Project directory to scope session discovery (default: current directory)
        #[arg(long)]
        project_dir: Option<std::path::PathBuf>,

        /// Include all active agents in the project store (not just this session's agents)
        #[arg(long)]
        all: bool,

        /// Explicit CAS root (.cas directory) to use instead of resolving from project_dir/session metadata
        #[arg(long)]
        cas_root: Option<std::path::PathBuf>,
    },

    /// Show recent activity events for a session (reads CAS EventStore)
    Activity {
        /// Session name (default: most recent attachable session for this project)
        #[arg(long)]
        session: Option<String>,

        /// Project directory to scope session discovery (default: current directory)
        #[arg(long)]
        project_dir: Option<std::path::PathBuf>,

        /// Include all recent events in the project store (not just this session's agents)
        #[arg(long)]
        all: bool,

        /// Max events to return
        #[arg(long, default_value = "50")]
        limit: usize,

        /// Explicit CAS root (.cas directory) to use instead of resolving from project_dir/session metadata
        #[arg(long)]
        cas_root: Option<std::path::PathBuf>,
    },

    /// Aggregated status snapshot for a session (ideal for external tools)
    Status {
        /// Session name (default: most recent attachable session for this project)
        #[arg(long)]
        session: Option<String>,

        /// Project directory to scope session discovery (default: current directory)
        #[arg(long)]
        project_dir: Option<std::path::PathBuf>,

        /// Max activity events to return
        #[arg(long, default_value = "20")]
        activity_limit: usize,

        /// Explicit CAS root (.cas directory) to use instead of resolving from project_dir/session metadata
        #[arg(long)]
        cas_root: Option<std::path::PathBuf>,
    },

    /// List valid messaging targets for a session (supervisor/workers/all_workers)
    Targets {
        /// Session name (default: most recent attachable session for this project)
        #[arg(long)]
        session: Option<String>,

        /// Project directory to scope session discovery (default: current directory)
        #[arg(long)]
        project_dir: Option<std::path::PathBuf>,
    },

    /// Inject a message into supervisor/workers via the prompt queue (no PTY attach)
    Message {
        /// Session name (default: most recent attachable session for this project)
        #[arg(long)]
        session: Option<String>,

        /// Project directory to scope session discovery (default: current directory)
        #[arg(long)]
        project_dir: Option<std::path::PathBuf>,

        /// Target: supervisor | all_workers | <worker-name>
        #[arg(long)]
        target: String,

        /// Message text to enqueue
        #[arg(long)]
        message: String,

        /// Source label for attribution in wrapped message (default: openclaw)
        #[arg(long, default_value = "openclaw")]
        from: String,

        /// Enqueue the raw message without wrapping in an XML `<message>` tag
        #[arg(long)]
        no_wrap: bool,

        /// Wait until the factory daemon records an injection event for this message ID
        #[arg(long)]
        wait_ack: bool,

        /// Timeout in milliseconds for --wait-ack
        #[arg(long, default_value = "5000")]
        timeout_ms: u64,

        /// Explicit CAS root (.cas directory) to use instead of resolving from project_dir/session metadata
        #[arg(long)]
        cas_root: Option<std::path::PathBuf>,
    },
}

pub fn execute(args: &FactoryArgs, cli: &Cli, cas_root: Option<&std::path::Path>) -> Result<()> { todo!() }

/// Attach to an existing factory session (local or remote via SSH)
pub fn execute_attach(args: &AttachArgs) -> Result<()> { todo!() }

/// Validate CAS is initialized in the current project
fn validate_cas_root(
    cwd: &std::path::Path,
    cas_root: Option<&std::path::Path>,
) -> Result<std::path::PathBuf> { todo!() }

fn noninteractive_factory_hints(
    args: &FactoryArgs,
    cwd: &std::path::Path,
    cas_root: Option<&std::path::Path>,
) -> Vec<String> { todo!() }

fn is_claude_installed() -> bool { todo!() }

fn is_codex_installed() -> bool { todo!() }

fn parse_supervisor_cli(value: &str) -> Result<cas_mux::SupervisorCli> { todo!() }

struct FactoryPreflight {
    cas_root: std::path::PathBuf,
    supervisor_cli: cas_mux::SupervisorCli,
    worker_cli: cas_mux::SupervisorCli,
    enable_worktrees: bool,
    notices: Vec<String>,
}

fn resolve_cli_choice(
    role: &str,
    requested: &str,
    allow_default_fallback: bool,
    claude_installed: bool,
    codex_installed: bool,
    notices: &mut Vec<String>,
) -> Result<cas_mux::SupervisorCli> { todo!() }

fn preflight_factory_launch(
    args: &FactoryArgs,
    cwd: &std::path::Path,
    cas_root: Option<&std::path::Path>,
) -> Result<FactoryPreflight> { todo!() }

#[cfg(test)]
mod tests {
    use crate::ui::factory::FactoryConfig;

    #[test]
    fn test_factory_config_default() {
        let config = FactoryConfig::default();
        assert_eq!(config.workers, 0);
        assert!(config.worker_names.is_empty());
        assert!(config.supervisor_name.is_none());
        assert_eq!(config.supervisor_cli, cas_mux::SupervisorCli::Claude);
        assert_eq!(config.worker_cli, cas_mux::SupervisorCli::Claude);
        assert!(config.enable_worktrees);
        assert!(config.worktree_root.is_none());
    }
}
