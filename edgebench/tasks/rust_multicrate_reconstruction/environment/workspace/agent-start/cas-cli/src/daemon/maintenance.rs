use chrono::Utc;

use crate::daemon::decay::{
    apply_memory_decay, auto_prune, run_consolidation, run_entity_summary_update,
};
use crate::daemon::indexing::generate_bm25_index;
use crate::daemon::observation::process_observations;
use crate::daemon::{DaemonConfig, DaemonRunResult};
use crate::error::CasError;

/// Run a single maintenance cycle.
pub fn run_maintenance(config: &DaemonConfig) -> Result<DaemonRunResult, CasError> { todo!() }

/// Clean up orphaned worktrees.
fn cleanup_orphaned_worktrees(config: &DaemonConfig) -> Result<usize, CasError> { todo!() }

/// Run daemon once (for testing or one-shot mode).
pub fn run_once(config: &DaemonConfig) -> Result<DaemonRunResult, CasError> { todo!() }
