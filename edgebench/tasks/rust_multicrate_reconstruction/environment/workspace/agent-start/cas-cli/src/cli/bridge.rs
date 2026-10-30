//! Local bridge server for external orchestrators (e.g., OpenClaw).

use anyhow::Result;
use clap::{Args, Subcommand};

use crate::cli::Cli;

#[derive(Args, Debug, Clone)]
pub struct BridgeArgs {
    #[command(subcommand)]
    pub command: BridgeCommands,
}

#[derive(Subcommand, Debug, Clone)]
pub enum BridgeCommands {
    /// Run a local HTTP server exposing a small control/status API
    Serve(ServeArgs),
}

#[derive(Args, Debug, Clone)]
pub struct ServeArgs {
    /// Bind address (default: 127.0.0.1)
    #[arg(long, default_value = "127.0.0.1")]
    pub bind: String,

    /// Port to listen on (0 = auto)
    #[arg(long, default_value = "0")]
    pub port: u16,

    /// Optional explicit CAS root directory (path to a `.cas/` dir).
    ///
    /// This is used as a fallback when a session has no `project_dir` metadata, or when
    /// CAS root detection fails for that `project_dir`.
    #[arg(long)]
    pub cas_root: Option<std::path::PathBuf>,

    /// Bearer token for authorization (default: auto-generate)
    #[arg(long)]
    pub token: Option<String>,

    /// Disable authorization (not recommended; still binds to localhost by default)
    #[arg(long)]
    pub no_auth: bool,

    /// Set CORS allow-origin header (e.g., "*" or "https://openclaw.ai")
    #[arg(long)]
    pub cors_allow_origin: Option<String>,
}

pub fn execute(args: &BridgeArgs, cli: &Cli) -> Result<()> { todo!() }
