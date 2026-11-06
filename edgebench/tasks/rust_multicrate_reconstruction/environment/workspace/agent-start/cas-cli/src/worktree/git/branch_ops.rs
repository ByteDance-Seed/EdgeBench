use std::path::Path;
use std::process::Command;

use crate::worktree::git::{GitError, GitOperations, Result};

impl GitOperations {
    /// Create a branch from HEAD if it doesn't exist
    ///
    /// Returns true if the branch was created, false if it already existed.
    pub fn create_branch_if_not_exists(&self, branch: &str) -> Result<bool> { todo!() }

    /// Push a branch to origin
    ///
    /// Pushes the specified branch to the 'origin' remote. If the branch doesn't exist
    /// on origin yet, it will be created. Uses -u to set up tracking.
    pub fn push_branch(&self, branch: &str) -> Result<()> { todo!() }

    /// Mark .claude/, CLAUDE.md, and .mcp.json as skip-worktree in a worktree
    ///
    /// This prevents workers from accidentally staging and committing CAS-synced
    /// changes to these tracked config files. The files remain in the worktree
    /// (Claude Code works normally) but git ignores local modifications.
    pub fn mark_config_skip_worktree(&self, worktree_path: &Path) -> Result<()> { todo!() }

    /// Reset a worktree to a specific branch/ref (hard reset)
    ///
    /// This is used to sync a worker's worktree to the latest epic branch.
    pub fn reset_hard_in_dir(&self, dir: &Path, target: &str) -> Result<()> { todo!() }
}
