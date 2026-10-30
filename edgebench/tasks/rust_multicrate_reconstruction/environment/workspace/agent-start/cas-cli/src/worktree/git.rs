//! Low-level git operations for worktree management
//!
//! This module provides a safe wrapper around git commands for worktree operations.
//! It's independent of CAS storage - purely git operations.

use std::path::{Path, PathBuf};
use std::process::Command;
use thiserror::Error;

use crate::types::GitContext;

mod branch_ops;

/// Errors that can occur during git operations
#[derive(Debug, Error)]
pub enum GitError {
    #[error("Git is not available: {0}")]
    GitNotAvailable(String),

    #[error("Not in a git repository")]
    NotAGitRepo,

    #[error("Failed to execute git command: {0}")]
    CommandFailed(String),

    #[error("Worktree already exists at {0}")]
    WorktreeExists(PathBuf),

    #[error("Worktree not found at {0}")]
    WorktreeNotFound(PathBuf),

    #[error("Branch already exists: {0}")]
    BranchExists(String),

    #[error("Branch not found: {0}")]
    BranchNotFound(String),

    #[error("Merge conflict detected")]
    MergeConflict,

    #[error("Uncommitted changes in worktree")]
    UncommittedChanges,

    #[error("Already inside a worktree at {0}")]
    AlreadyInWorktree(PathBuf),

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

/// Result type for git operations
pub type Result<T> = std::result::Result<T, GitError>;

/// Status of a worktree's uncommitted/unmerged state
#[derive(Debug, Clone)]
pub struct WorktreeDirtyStatus {
    /// Number of modified/staged files
    pub modified_count: usize,
    /// Number of untracked files
    pub untracked_count: usize,
    /// Number of commits not merged to target branch
    pub unmerged_count: usize,
    /// Target branch for unmerged check (e.g., epic branch)
    pub target_branch: Option<String>,
}

impl WorktreeDirtyStatus {
    /// Check if the worktree is clean
    pub fn is_clean(&self) -> bool { todo!() }

    /// Format as human-readable message
    pub fn to_message(&self) -> String { todo!() }
}

/// Git operations wrapper
pub struct GitOperations {
    /// Path to the main repository root
    repo_root: PathBuf,
}

impl GitOperations {
    /// Create a new GitOperations instance for a repository
    pub fn new(repo_root: PathBuf) -> Self { todo!() }

    /// Detect the repository root from a path
    pub fn detect_repo_root(from: &Path) -> Result<PathBuf> { todo!() }

    /// Check if git is available
    pub fn is_git_available() -> bool { todo!() }

    /// Get the current git context (branch, worktree info)
    pub fn get_context(from: &Path) -> Result<GitContext> { todo!() }

    /// Get the current branch name
    pub fn current_branch(&self) -> Result<String> { todo!() }

    /// Check if the repository has any commits
    pub fn has_commits(&self) -> Result<bool> { todo!() }

    /// Detect the default branch of the repository.
    ///
    /// Uses git's own mechanisms in priority order:
    /// 1. Remote origin HEAD (authoritative if remote exists)
    /// 2. HEAD symref target (what git init / clone set up)
    /// 3. `init.defaultBranch` config
    /// 4. Check common branch names that actually exist as refs
    /// 5. "main" as absolute last resort
    pub fn detect_default_branch(&self) -> String { todo!() }

    /// Check if a branch exists
    pub fn branch_exists(&self, branch: &str) -> Result<bool> { todo!() }

    /// Create a worktree with a new branch
    pub fn create_worktree(
        &self,
        path: &Path,
        branch: &str,
        base_branch: Option<&str>,
    ) -> Result<()> { todo!() }

    /// Initialize git submodules in a directory
    ///
    /// This is necessary for worktrees because `git worktree add` doesn't
    /// automatically populate submodule contents. Without this, builds that
    /// depend on vendored submodules (like ghostty_vt_sys) will fail.
    ///
    /// Note: This function does not fail if submodule init fails, because the
    /// worktree is still usable for many tasks that don't require submodules.
    /// A clear error message will be shown if a build later requires the submodule.
    pub fn init_submodules(&self, path: &Path) -> Result<()> { todo!() }

    /// Get submodule paths from .gitmodules
    ///
    /// Parses the .gitmodules file to extract the paths of all configured submodules.
    pub fn get_submodule_paths(&self) -> Result<Vec<PathBuf>> { todo!() }

    /// Fix symlinked submodules before merge operations
    ///
    /// Git merge fails when submodule paths are symbolic links with:
    /// "error: expected submodule path 'vendor/...' not to be a symbolic link"
    ///
    /// This function detects symlinked submodules in the given directory and replaces
    /// them with properly initialized submodules.
    pub fn fix_symlinked_submodules(&self, path: &Path) -> Result<()> { todo!() }

    /// List all worktrees
    pub fn list_worktrees(&self) -> Result<Vec<WorktreeInfo>> { todo!() }

    /// Remove a worktree
    pub fn remove_worktree(&self, path: &Path, force: bool) -> Result<()> { todo!() }

    /// Delete a branch
    pub fn delete_branch(&self, branch: &str, force: bool) -> Result<()> { todo!() }

    /// Merge a branch into the current branch
    pub fn merge_branch(&self, branch: &str, no_ff: bool) -> Result<Option<String>> { todo!() }

    /// Check if the worktree has uncommitted changes
    pub fn has_uncommitted_changes(&self, path: &Path) -> Result<bool> { todo!() }

    /// Count commits in worktree HEAD that are not in target branch
    ///
    /// Returns the number of commits that exist on the worktree's current branch
    /// but not on the target branch (e.g., epic branch).
    pub fn unmerged_commit_count(
        &self,
        worktree_path: &Path,
        target_branch: &str,
    ) -> Result<usize> { todo!() }

    /// Get detailed dirty status of a worktree
    ///
    /// Returns a summary of uncommitted changes, untracked files, and unmerged commits.
    pub fn get_worktree_dirty_status(
        &self,
        worktree_path: &Path,
        target_branch: Option<&str>,
    ) -> Result<WorktreeDirtyStatus> { todo!() }

    /// Checkout a branch in the main repo
    pub fn checkout(&self, branch: &str) -> Result<()> { todo!() }

    /// Prune stale worktree references
    pub fn prune_worktrees(&self) -> Result<()> { todo!() }
}

/// Information about a git worktree
#[derive(Debug, Clone)]
pub struct WorktreeInfo {
    /// Path to the worktree
    pub path: PathBuf,
    /// Branch checked out in the worktree (None if detached)
    pub branch: Option<String>,
    /// Current commit hash
    pub commit: Option<String>,
    /// Whether this is a bare worktree
    pub is_bare: bool,
    /// Whether HEAD is detached
    pub is_detached: bool,
}

#[cfg(test)]
#[path = "git_tests/tests.rs"]
mod tests;
