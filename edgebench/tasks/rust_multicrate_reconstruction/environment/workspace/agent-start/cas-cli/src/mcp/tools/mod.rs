//! MCP Tools for CAS
//!
//! This module contains MCP tools organized by category:
//! - Memory tools (12): Entry management
//! - Task tools (15): Task and dependency management
//! - Rule tools (10): Rule management
//! - Skill tools (10): Skill management
//! - Search tools (1): Unified search with doc_type filter
//! - System tools (7): Context, stats, diagnostics, and utilities

use crate::hooks::{HookInput, build_context, handle_session_end, handle_session_start};
use crate::types::{
    BeliefType, ClaimResult, DEFAULT_LEASE_DURATION_SECS, Dependency, DependencyType, Entry,
    EntryType, LeaseStatus, MemoryTier, ObservationType, Priority, Rule, RuleStatus, Scope, Skill,
    SkillStatus, SkillType, Task, TaskStatus, TaskType, Verification, VerificationIssue,
    VerificationStatus, VerificationType, WorktreeStatus,
};
use cas_core::{DocType, SearchIndex, SearchOptions};

// Include all request types
mod types;
pub use types::*;

// CAS MCP service (7 meta-tools)
pub mod service;
pub use service::CasService;

// ============================================================================
// Tool Implementations - All in one impl block to satisfy the macro
// ============================================================================

// ============================================================================
// Sort Helper Functions
// ============================================================================

/// Sort a vector of tasks based on sort options
pub(super) fn sort_tasks(tasks: &mut [Task], opts: &cas_types::TaskSortOptions) { todo!() }

/// Sort a vector of blocked tasks (task, blockers) tuples based on sort options
pub(super) fn sort_blocked_tasks(
    blocked: &mut [(Task, Vec<Task>)],
    opts: &cas_types::TaskSortOptions,
) { todo!() }

// ============================================================================
// Branch Name Helper
// ============================================================================

/// Convert a title to a branch-safe slug for epic branches
///
/// Creates branch names like `epic/add-user-authentication` from titles.
fn slugify_for_branch(title: &str) -> String { todo!() }

// ============================================================================
// Epic Merge Check Helper
// ============================================================================

/// Check for unmerged worker branches for an epic
///
/// In factory mode, workers may push branches in format `{epic-id}/{worker-name}` to a remote.
/// This function checks remote branches first, then falls back to local branches when no
/// matching remote branches exist.
///
/// Returns a list of unmerged branch names, or empty if all merged.
fn check_unmerged_epic_branches(epic_id: &str, target_branch: &str) -> Vec<String> { todo!() }

/// Check how many commits behind its sync target a worktree is
///
/// Returns (commits_behind, sync_ref) or None if check fails
fn check_worktree_staleness(clone_path: &str) -> Option<(u32, String)> { todo!() }

fn list_git_branches(path: Option<&std::path::Path>, args: &[&str]) -> Vec<String> { todo!() }

fn normalize_branch_line(line: &str) -> Option<String> { todo!() }

fn current_upstream(path: &std::path::Path) -> Option<String> { todo!() }

fn remote_for_ref(path: &std::path::Path, reference: &str) -> Option<String> { todo!() }

// NOTE: #[tool_router] removed - CasService (service/mod.rs) is the actual MCP service.
// CasCore methods are called directly, not through tool routing.
// This reduces compile time by avoiding proc-macro expansion of ~77 tools.

mod core;

#[cfg(test)]
mod mod_tests;
