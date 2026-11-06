use std::io;
use std::path::Path;

use similar::{ChangeTag, TextDiff};

use crate::builtins::{preview_all_builtins, preview_all_codex_builtins};
use crate::cli::Cli;
use crate::cli::update_transaction::{FileChange, MigrationChange, UpdateTransaction};
use crate::migration::MigrationStatus;
use crate::ui::components::Formatter;
use crate::ui::theme::ActiveTheme;

pub(crate) fn compute_claude_md_change(project_root: &Path) -> Option<FileChange> { todo!() }

/// Compute what CAS skill changes would be made (without applying)
pub(crate) fn compute_cas_skill_change(project_root: &Path) -> Option<FileChange> { todo!() }

/// Build an UpdateTransaction with all pending changes
pub(crate) fn build_update_transaction(
    project_root: &Path,
    cas_dir: &Path,
    status: &MigrationStatus,
    keep_backup: bool,
) -> UpdateTransaction { todo!() }

/// Render a colored diff using Formatter
fn render_diff(
    fmt: &mut Formatter,
    prefix: &str,
    path: &str,
    old_content: &str,
    new_content: &str,
) -> io::Result<()> { todo!() }

/// Enhanced dry-run that shows migrations, file diffs, and builtin changes
pub(crate) fn show_enhanced_dry_run(
    tx: &UpdateTransaction,
    status: &MigrationStatus,
    claude_dir: &std::path::Path,
    codex_dir: &std::path::Path,
    cli: &Cli,
) -> anyhow::Result<()> { todo!() }
