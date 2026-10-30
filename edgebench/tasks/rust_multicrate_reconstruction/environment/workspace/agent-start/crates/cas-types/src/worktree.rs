//! Git worktree types for CAS
//!
//! Provides types for tracking git worktrees associated with epics.
//! Worktrees are scoped to epics (not individual tasks), allowing multiple
//! related tasks within an epic to share a single development environment.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use std::str::FromStr;

/// Status of a worktree in its lifecycle
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum WorktreeStatus {
    /// Worktree is active and usable
    #[default]
    Active,
    /// Branch was merged back to parent
    Merged,
    /// Task closed without merge (work discarded)
    Abandoned,
    /// Worktree directory has been removed
    Removed,
    /// Merge conflict detected, needs manual resolution
    Conflict,
}

impl std::fmt::Display for WorktreeStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

impl FromStr for WorktreeStatus {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// A git worktree managed by CAS
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Worktree {
    /// Unique identifier (wt-{short_hash})
    pub id: String,

    /// Epic that owns this worktree
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub epic_id: Option<String>,

    /// Git branch name (e.g., "cas/cas-1234")
    pub branch: String,

    /// Branch the worktree was created from (e.g., "main")
    pub parent_branch: String,

    /// Absolute path to worktree directory
    pub path: PathBuf,

    /// Current status in lifecycle
    pub status: WorktreeStatus,

    /// When the worktree was created
    pub created_at: DateTime<Utc>,

    /// When the branch was merged back (if merged)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub merged_at: Option<DateTime<Utc>>,

    /// When the worktree directory was removed
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub removed_at: Option<DateTime<Utc>>,

    /// Agent that created this worktree
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub created_by_agent: Option<String>,

    /// Commit hash after merge (for audit)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub merge_commit: Option<String>,
}

impl Worktree {
    /// Create a new worktree
    pub fn new(id: String, branch: String, parent_branch: String, path: PathBuf) -> Self { todo!() }

    /// Create a worktree for a specific epic
    ///
    /// Multiple tasks within the same epic share this worktree.
    pub fn for_epic(
        id: String,
        epic_id: String,
        branch: String,
        parent_branch: String,
        path: PathBuf,
        agent_id: Option<String>,
    ) -> Self { todo!() }

    /// Check if the worktree is still active
    pub fn is_active(&self) -> bool { todo!() }

    /// Check if the worktree can be worked on
    pub fn is_usable(&self) -> bool { todo!() }

    /// Mark as merged
    pub fn mark_merged(&mut self, commit: Option<String>) { todo!() }

    /// Mark as abandoned
    pub fn mark_abandoned(&mut self) { todo!() }

    /// Mark as removed
    pub fn mark_removed(&mut self) { todo!() }

    /// Mark as having a merge conflict
    pub fn mark_conflict(&mut self) { todo!() }

    /// Generate a worktree ID
    pub fn generate_id() -> String { todo!() }
}

/// Information about the current git context
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct GitContext {
    /// Current git branch name
    pub branch: Option<String>,

    /// Whether we're in a git worktree (vs main checkout)
    pub is_worktree: bool,

    /// Path to the worktree root (if in a worktree)
    pub worktree_path: Option<PathBuf>,

    /// Path to the main git directory
    pub git_dir: Option<PathBuf>,

    /// CAS worktree record ID (if this worktree is managed by CAS)
    pub cas_worktree_id: Option<String>,
}

impl GitContext {
    /// Check if we have valid git context
    pub fn is_valid(&self) -> bool { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::worktree::*;

    #[test]
    fn test_worktree_status_roundtrip() {
        for status in [
            WorktreeStatus::Active,
            WorktreeStatus::Merged,
            WorktreeStatus::Abandoned,
            WorktreeStatus::Removed,
            WorktreeStatus::Conflict,
        ] {
            let s = status.to_string();
            let parsed: WorktreeStatus = s.parse().unwrap();
            assert_eq!(status, parsed);
        }
    }

    #[test]
    fn test_worktree_new() {
        let wt = Worktree::new(
            "wt-12345678".to_string(),
            "cas/cas-1234".to_string(),
            "main".to_string(),
            PathBuf::from("/tmp/worktree"),
        );

        assert_eq!(wt.status, WorktreeStatus::Active);
        assert!(wt.epic_id.is_none());
        assert!(wt.is_active());
    }


    #[test]
    fn test_worktree_lifecycle() {
        let mut wt = Worktree::new(
            "wt-12345678".to_string(),
            "cas/cas-1234".to_string(),
            "main".to_string(),
            PathBuf::from("/tmp/worktree"),
        );

        assert!(wt.is_active());
        assert!(wt.is_usable());

        wt.mark_merged(Some("abc123".to_string()));
        assert!(!wt.is_active());
        assert!(!wt.is_usable());
        assert!(wt.merged_at.is_some());
        assert_eq!(wt.merge_commit, Some("abc123".to_string()));

        wt.mark_removed();
        assert_eq!(wt.status, WorktreeStatus::Removed);
        assert!(wt.removed_at.is_some());
    }

    #[test]
    fn test_generate_id() {
        let id1 = Worktree::generate_id();
        let id2 = Worktree::generate_id();

        assert!(id1.starts_with("wt-"));
        assert!(id2.starts_with("wt-"));
        // IDs should be unique (with very high probability)
        assert_ne!(id1, id2);
    }
}
