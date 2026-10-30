//! CLI commands for CAS
//!
//! Essential commands only. Use MCP tools for memory, tasks, rules, etc.

mod auth;
pub(crate) mod bridge;
mod changelog;
mod cloud;
mod config;
mod config_tui;
mod device;
mod doctor;
mod factory;
mod factory_tooling;
mod hook;
mod init;
pub mod interactive;
mod list;
mod mcp_cmd;
mod queue;
mod status;
mod statusline;
mod update;
pub mod update_transaction;

use std::path::{Path, PathBuf};

use clap::{Parser, Subcommand};

use crate::store::find_cas_root;

pub use auth::AuthCommands;
pub use bridge::BridgeArgs;
pub use changelog::ChangelogArgs;
pub use config::ConfigCommands;
pub use doctor::DoctorArgs;
pub use factory::{AttachArgs, FactoryArgs, KillAllArgs, KillArgs};
pub use hook::HookArgs;
pub use init::InitArgs;
pub use list::ListArgs;
pub use mcp_cmd::McpCommands;
pub use status::StatusArgs;
pub use statusline::StatusLineArgs;
pub use update::UpdateArgs;

/// Build version string including git hash and date
fn build_version() -> String { todo!() }

const LOGO: &str = r#"
   ______   ___    _____
  / ____/  /   |  / ___/
 / /      / /| |  \__ \
/ /___   / ___ | ___/ /
\____/  /_/  |_|/____/
"#;

/// CAS - Multi-agent coding factory
#[derive(Parser)]
#[command(name = "cas")]
#[command(about = "Multi-agent coding factory with persistent memory and task coordination")]
#[command(version = build_version())]
#[command(before_help = LOGO)]
pub struct Cli {
    /// Output in JSON format
    #[arg(long, global = true)]
    pub json: bool,

    /// Include full content in JSON output
    #[arg(long, global = true)]
    pub full: bool,

    /// Verbose output
    #[arg(short, long, global = true)]
    pub verbose: bool,

    #[command(subcommand)]
    pub command: Option<Commands>,
}

#[derive(Subcommand)]
pub enum Commands {
    /// Initialize CAS in current directory
    Init(InitArgs),

    /// Attach to a running factory session
    Attach(AttachArgs),

    /// List running factory sessions
    #[command(alias = "ls")]
    List(ListArgs),

    /// Terminate a factory session
    Kill(KillArgs),

    /// Terminate all factory sessions
    KillAll(KillAllArgs),

    /// Launch factory session (bare `cas` runs factory with defaults)
    Factory(FactoryArgs),

    /// Local helper server for external orchestration tools
    Bridge(BridgeArgs),

    /// Run MCP server for Claude Code integration
    #[cfg(feature = "mcp-server")]
    Serve,

    /// Run diagnostics
    Doctor(DoctorArgs),

    /// Manage configuration
    #[command(subcommand)]
    Config(ConfigCommands),

    /// Show session status
    Status(StatusArgs),

    /// Output status line for Claude Code integration
    #[command(alias = "statusline")]
    StatusLine(StatusLineArgs),

    /// Handle Claude Code hook events
    Hook(HookArgs),

    /// Authentication commands (login, logout, whoami)
    #[command(subcommand)]
    Auth(AuthCommands),

    /// Log in to CAS Cloud (shortcut for 'auth login')
    Login(auth::LoginArgs),

    /// Log out (shortcut for 'auth logout')
    Logout,

    /// Show current user (shortcut for 'auth whoami')
    Whoami,

    /// Update CAS to the latest version
    Update(UpdateArgs),

    /// Show release notes and changelog from GitHub releases
    Changelog(ChangelogArgs),

    /// Manage upstream MCP servers
    #[command(subcommand)]
    Mcp(McpCommands),

    /// Prompt queue operations (poll/ack for native extensions)
    #[command(subcommand)]
    Queue(queue::QueueCommands),

    /// Cloud sync (push/pull data to CAS Cloud)
    #[command(subcommand, hide = true)]
    Cloud(cloud::CloudCommands),

    /// Manage registered devices
    #[command(subcommand)]
    Device(device::DeviceCommands),
}

/// Authentication requirement for a command.
#[derive(Copy, Clone, Eq, PartialEq)]
enum AuthRequirement {
    NotRequired,
    Required,
}

/// Determine whether a command requires authentication.
fn auth_requirement(command: &Option<Commands>) -> AuthRequirement { todo!() }

/// Ensure the user is authenticated before running a command
fn ensure_authenticated() -> anyhow::Result<()> { todo!() }

/// Run the CLI with the given arguments
pub fn run(cli: Cli) -> anyhow::Result<()> { todo!() }

fn categorize_error(e: &anyhow::Error) -> String { todo!() }

fn initialize_dev_tracer() -> bool { todo!() }

fn initialize_telemetry() { todo!() }

fn get_command_name(cmd: &Option<Commands>) -> String { todo!() }

fn require_cas_root(cas_root: Option<&Path>) -> anyhow::Result<&Path> { todo!() }

fn run_command(cli: &Cli, cas_root: Option<&Path>) -> anyhow::Result<()> { todo!() }

#[cfg(feature = "mcp-server")]
fn serve_execute() -> anyhow::Result<()> { todo!() }
