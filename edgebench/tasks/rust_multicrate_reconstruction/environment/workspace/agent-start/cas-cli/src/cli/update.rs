//! Self-update command for CAS CLI
//!
//! Downloads and installs the latest version from a configured release source,
//! and runs schema migrations for the local database.

use std::io;
use std::path::Path;
use std::time::{Duration, Instant};

use clap::Args;

use crate::builtins::sync_all_builtins_for_harness;
use crate::cli::Cli;
use crate::cli::factory_tooling;
use crate::cli::hook::{configure_claude_hooks, configure_codex_mcp_server, configure_mcp_server};
use crate::cli::init::{generate_cas_skill, update_claude_md};
use crate::cli::update::preview::{build_update_transaction, show_enhanced_dry_run};
use crate::migration::{check_migrations, run_migrations};
use crate::store::{open_rule_store, open_skill_store};
use crate::sync::{SkillSyncer, Syncer};
use crate::ui::components::Formatter;
use crate::ui::theme::ActiveTheme;

mod preview;

/// Release repository owner placeholder used by the benchmark starter.
const REPO_OWNER: &str = "benchmark";

/// GitHub repository name
const REPO_NAME: &str = "cas";

/// Binary name in release assets
const BIN_NAME: &str = "cas";

#[derive(Args)]
pub struct UpdateArgs {
    /// Only check for updates without installing
    #[arg(long)]
    pub check: bool,

    /// Update to a specific version (e.g., "0.2.1")
    #[arg(long)]
    pub version: Option<String>,

    /// Skip confirmation prompt
    #[arg(short = 'y', long)]
    pub yes: bool,

    /// Only run schema migrations (skip binary update)
    #[arg(long)]
    pub schema_only: bool,

    /// Only sync .claude/.codex files (agents, skills, rules, settings)
    #[arg(long)]
    pub sync: bool,

    /// Show what migrations would be applied without running them
    #[arg(long)]
    pub dry_run: bool,

    /// Keep backup files after successful update
    #[arg(long)]
    pub keep_backup: bool,
}

pub fn execute(args: &UpdateArgs, cli: &Cli, cas_root: Option<&Path>) -> anyhow::Result<()> { todo!() }

/// Sync rules, skills, and configuration to .claude/.codex directories
fn sync_claude_files(cli: &Cli, cas_root_param: Option<&Path>) -> anyhow::Result<()> { todo!() }

/// Run schema migrations only
fn run_schema_migrations(
    args: &UpdateArgs,
    cli: &Cli,
    cas_root_param: Option<&Path>,
) -> anyhow::Result<()> { todo!() }

/// Check if a newer version is available (binary + schema)
fn check_for_updates(
    current_version: &str,
    cli: &Cli,
    cas_root_param: Option<&Path>,
) -> anyhow::Result<()> { todo!() }

/// Download and install the latest (or specified) version
fn perform_update(args: &UpdateArgs, current_version: &str, cli: &Cli) -> anyhow::Result<()> { todo!() }

/// Try to get a GitHub auth token from `gh auth token` or GITHUB_TOKEN env var.
fn github_auth_token() -> Option<String> { todo!() }

/// Compare semantic versions to check if `new` is newer than `current`
fn is_newer(new: &str, current: &str) -> bool { todo!() }

struct UpdateStepTracker {
    total: usize,
    current: usize,
    enabled: bool,
}

impl UpdateStepTracker {
    fn new(total: usize, enabled: bool) -> Self { todo!() }

    fn run<T, F>(&mut self, label: &str, f: F) -> anyhow::Result<T>
    where
        F: FnOnce() -> anyhow::Result<T>,
    { todo!() }
}

fn format_elapsed(duration: Duration) -> String { todo!() }

#[cfg(test)]
#[path = "update_tests/tests.rs"]
mod tests;
