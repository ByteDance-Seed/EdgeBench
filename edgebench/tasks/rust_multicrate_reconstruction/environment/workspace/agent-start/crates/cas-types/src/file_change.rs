//! File change tracking for code attribution
//!
//! This module contains types for tracking file changes made by AI agents,
//! recording which files were modified, created, or deleted during a session.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::Scope;

/// Type of file change operation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ChangeType {
    /// File was created (Write tool to new file)
    Created,
    /// File was modified (Edit tool or Write to existing)
    Modified,
    /// File was deleted
    Deleted,
    /// Change type could not be determined
    Unknown,
}

impl std::fmt::Display for ChangeType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

impl std::str::FromStr for ChangeType {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// A file change made by an AI agent
///
/// Tracks which files were modified and links changes to sessions,
/// agents, prompts, and git commits.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct FileChange {
    /// Unique identifier (format: "fc-{timestamp}-{random}")
    pub id: String,

    /// Session that made this change
    pub session_id: String,

    /// Agent that made this change
    pub agent_id: String,

    /// The prompt that triggered this change (links to prompts table)
    pub prompt_id: Option<String>,

    /// Repository path or name
    pub repository: String,

    /// Path to the changed file (relative to repository root)
    pub file_path: String,

    /// FK to code_files if the file is indexed
    pub file_id: Option<String>,

    /// Type of change (created, modified, deleted)
    pub change_type: ChangeType,

    /// Tool that made the change ("Write", "Edit", "NotebookEdit")
    pub tool_name: String,

    /// Hash of the old content (before change)
    pub old_content_hash: Option<String>,

    /// Hash of the new content (after change)
    pub new_content_hash: String,

    /// Git commit hash (filled in after commit)
    pub commit_hash: Option<String>,

    /// When the commit was made
    pub committed_at: Option<DateTime<Utc>>,

    /// When this change was recorded
    pub created_at: DateTime<Utc>,

    /// Scope (project or global)
    pub scope: Scope,
}

impl FileChange {
    /// Create a new file change record
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        id: String,
        session_id: String,
        agent_id: String,
        repository: String,
        file_path: String,
        change_type: ChangeType,
        tool_name: String,
        new_content_hash: String,
    ) -> Self { todo!() }

    /// Create a file change with prompt linkage
    #[allow(clippy::too_many_arguments)]
    pub fn with_prompt(
        id: String,
        session_id: String,
        agent_id: String,
        prompt_id: Option<String>,
        repository: String,
        file_path: String,
        change_type: ChangeType,
        tool_name: String,
        old_content_hash: Option<String>,
        new_content_hash: String,
    ) -> Self { todo!() }

    /// Associate this change with a git commit
    pub fn link_commit(&mut self, commit_hash: String) { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::file_change::*;

    #[test]
    fn test_change_type_display() {
        assert_eq!(ChangeType::Created.to_string(), "created");
        assert_eq!(ChangeType::Modified.to_string(), "modified");
        assert_eq!(ChangeType::Deleted.to_string(), "deleted");
        assert_eq!(ChangeType::Unknown.to_string(), "unknown");
    }

    #[test]
    fn test_change_type_parse() {
        assert_eq!(
            "created".parse::<ChangeType>().unwrap(),
            ChangeType::Created
        );
        assert_eq!(
            "Modified".parse::<ChangeType>().unwrap(),
            ChangeType::Modified
        );
        assert_eq!(
            "DELETED".parse::<ChangeType>().unwrap(),
            ChangeType::Deleted
        );
    }

}
