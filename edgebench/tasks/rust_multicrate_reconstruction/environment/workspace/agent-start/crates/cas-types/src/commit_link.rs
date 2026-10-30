//! Commit link for associating git commits with AI sessions
//!
//! This module tracks the relationship between git commits and AI sessions,
//! enabling "git blame for AI" functionality - tracing commits back to the
//! sessions, agents, and prompts that created them.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

use crate::Scope;

/// A link between a git commit and an AI session
///
/// Tracks which session, agent, and prompts led to a commit being created.
/// This enables attribution queries like "which AI session created this commit?"
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommitLink {
    /// Git commit hash (full 40-char SHA) - primary key
    pub commit_hash: String,

    /// Session that created this commit
    pub session_id: String,

    /// Agent that created this commit
    pub agent_id: String,

    /// Branch the commit was made on
    pub branch: String,

    /// Commit message
    pub message: String,

    /// Files changed in this commit (relative paths)
    pub files_changed: Vec<String>,

    /// Prompt IDs that led to this commit (from file_changes)
    pub prompt_ids: Vec<String>,

    /// When the commit was made
    pub committed_at: DateTime<Utc>,

    /// Git author (from git config)
    pub author: String,

    /// Scope (project or global)
    pub scope: Scope,
}

impl CommitLink {
    /// Create a new commit link
    #[allow(clippy::too_many_arguments)]
    pub fn new(
        commit_hash: String,
        session_id: String,
        agent_id: String,
        branch: String,
        message: String,
        files_changed: Vec<String>,
        prompt_ids: Vec<String>,
        author: String,
    ) -> Self { todo!() }

    /// Get a short hash (first 7 characters)
    pub fn short_hash(&self) -> &str { todo!() }

    /// Get the first line of the commit message
    pub fn message_summary(&self) -> &str { todo!() }

    /// Get a short preview of the commit
    pub fn preview(&self, max_len: usize) -> String { todo!() }

    /// Number of files changed
    pub fn file_count(&self) -> usize { todo!() }

    /// Check if a file was changed in this commit
    pub fn includes_file(&self, file_path: &str) -> bool { todo!() }
}

impl Default for CommitLink {
    fn default() -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::commit_link::*;

    #[test]
    fn test_commit_link_new() {
        let link = CommitLink::new(
            "abc123def456789".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "main".to_string(),
            "Add new feature".to_string(),
            vec!["src/main.rs".to_string(), "src/lib.rs".to_string()],
            vec!["prompt-1".to_string()],
            "John Doe <john@example.com>".to_string(),
        );

        assert_eq!(link.commit_hash, "abc123def456789");
        assert_eq!(link.branch, "main");
        assert_eq!(link.file_count(), 2);
    }


    #[test]
    fn test_message_summary() {
        let link = CommitLink {
            message: "Add new feature\n\nThis is a longer description.".to_string(),
            ..Default::default()
        };

        assert_eq!(link.message_summary(), "Add new feature");
    }


}
