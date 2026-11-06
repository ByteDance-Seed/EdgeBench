//! Git change tracking DTOs for factory data aggregation.
//!
//! These types represent git file changes without any TUI/rendering dependencies.
//! They are used by DirectorData to aggregate changes across worktrees.

use std::path::PathBuf;

use serde::{Deserialize, Serialize};

/// Git file status type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum GitFileStatus {
    Modified,
    Added,
    Deleted,
    Renamed,
    Untracked,
}

impl GitFileStatus {
    /// Get the single-character symbol for this status
    pub fn symbol(&self) -> &'static str { todo!() }

    /// Get the lowercase name for this status (for UI display)
    pub fn name(&self) -> &'static str { todo!() }
}

/// Display info for a single file change
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileChangeInfo {
    pub file_path: String,
    pub lines_added: usize,
    pub lines_removed: usize,
    pub status: GitFileStatus,
    pub staged: bool,
}

/// Display info for a source (worktree/repo)
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SourceChangesInfo {
    /// Display name (e.g., "main" or branch name)
    pub source_name: String,
    /// Filesystem path to this source's root directory
    pub source_path: PathBuf,
    /// Agent working in this source (if tracked)
    pub agent_name: Option<String>,
    /// File changes in this source
    pub changes: Vec<FileChangeInfo>,
    pub total_added: usize,
    pub total_removed: usize,
}
