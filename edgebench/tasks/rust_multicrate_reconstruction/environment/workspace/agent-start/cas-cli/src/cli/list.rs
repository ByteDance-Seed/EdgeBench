//! Arguments for `cas list`

use clap::Args;

/// Arguments for listing running factory sessions.
///
/// This stays lightweight and local-only (reads session metadata under ~/.cas).
#[derive(Args, Debug, Clone, Default)]
pub struct ListArgs {
    /// Filter to a specific session name (exact match)
    #[arg(long)]
    pub name: Option<String>,

    /// Filter to sessions for a specific project directory
    #[arg(long)]
    pub project_dir: Option<std::path::PathBuf>,

    /// Only show sessions that can currently be attached to
    #[arg(long)]
    pub attachable_only: bool,

    /// Only show sessions with a running daemon process
    #[arg(long)]
    pub running_only: bool,
}
