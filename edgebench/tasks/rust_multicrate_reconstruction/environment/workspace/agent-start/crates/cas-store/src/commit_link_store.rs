//! SQLite-based commit link storage for tracking git commits from AI sessions
//!
//! This module provides storage for commit links that enable code attribution:
//! tracing git commits back to the session, agent, and prompts that created them.

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, OptionalExtension, params};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::error::StoreError;
use cas_types::{CommitLink, Scope};

/// Helper to convert mutex poison error to StoreError
fn lock_error<T>(_: std::sync::PoisonError<T>) -> StoreError { todo!() }

/// Schema for commit_links table (also defined in migration m143)
pub const COMMIT_LINK_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS commit_links (
    commit_hash TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    branch TEXT NOT NULL,
    message TEXT NOT NULL,
    files_changed TEXT NOT NULL,
    prompt_ids TEXT NOT NULL,
    committed_at TEXT NOT NULL,
    author TEXT NOT NULL,
    scope TEXT NOT NULL DEFAULT 'project'
);

CREATE INDEX IF NOT EXISTS idx_commit_links_session ON commit_links(session_id);
CREATE INDEX IF NOT EXISTS idx_commit_links_branch ON commit_links(branch);
CREATE INDEX IF NOT EXISTS idx_commit_links_committed ON commit_links(committed_at DESC);
"#;

/// Trait for commit link storage operations
pub trait CommitLinkStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Add a new commit link
    fn add(&self, link: &CommitLink) -> Result<()>;

    /// Get a commit link by hash
    fn get(&self, commit_hash: &str) -> Result<Option<CommitLink>>;

    /// Get commit links for a session
    fn list_by_session(&self, session_id: &str, limit: usize) -> Result<Vec<CommitLink>>;

    /// Get commit links for a branch
    fn list_by_branch(&self, branch: &str, limit: usize) -> Result<Vec<CommitLink>>;

    /// Get recent commits (most recent first)
    fn list_recent(&self, limit: usize) -> Result<Vec<CommitLink>>;

    /// Find commits that changed a specific file
    fn find_by_file(&self, file_path: &str, limit: usize) -> Result<Vec<CommitLink>>;

    /// Delete old commit links (keep last N days)
    fn prune(&self, days: i64) -> Result<usize>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite implementation of CommitLinkStore
pub struct SqliteCommitLinkStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteCommitLinkStore {
    /// Open or create a commit link store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    /// Create from an existing connection (for use within other stores)
    pub fn from_connection(conn: Connection) -> Result<Self> { todo!() }

    /// Parse a row into a CommitLink
    fn row_to_commit_link(row: &rusqlite::Row) -> rusqlite::Result<CommitLink> { todo!() }
}

impl CommitLinkStore for SqliteCommitLinkStore {
    fn init(&self) -> Result<()> { todo!() }

    fn add(&self, link: &CommitLink) -> Result<()> { todo!() }

    fn get(&self, commit_hash: &str) -> Result<Option<CommitLink>> { todo!() }

    fn list_by_session(&self, session_id: &str, limit: usize) -> Result<Vec<CommitLink>> { todo!() }

    fn list_by_branch(&self, branch: &str, limit: usize) -> Result<Vec<CommitLink>> { todo!() }

    fn list_recent(&self, limit: usize) -> Result<Vec<CommitLink>> { todo!() }

    fn find_by_file(&self, file_path: &str, limit: usize) -> Result<Vec<CommitLink>> { todo!() }

    fn prune(&self, days: i64) -> Result<usize> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

/// Parse a datetime string, with fallback to current time
fn parse_datetime(s: &str) -> DateTime<Utc> { todo!() }

/// Helper to add a commit link using the connection from another store
pub fn add_commit_link_with_conn(
    conn: &Connection,
    link: &CommitLink,
) -> std::result::Result<(), rusqlite::Error> { todo!() }

#[cfg(test)]
mod tests {
    use crate::commit_link_store::*;
    use tempfile::TempDir;

    fn setup_store() -> (SqliteCommitLinkStore, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let store = SqliteCommitLinkStore::open(temp_dir.path()).unwrap();
        (store, temp_dir)
    }

    fn create_test_link(commit_hash: &str, session_id: &str, branch: &str) -> CommitLink {
        CommitLink::new(
            commit_hash.to_string(),
            session_id.to_string(),
            "agent-1".to_string(),
            branch.to_string(),
            "Test commit message".to_string(),
            vec!["src/main.rs".to_string(), "src/lib.rs".to_string()],
            vec!["prompt-1".to_string()],
            "Test Author <test@example.com>".to_string(),
        )
    }




    #[test]
    fn test_list_recent() {
        let (store, _dir) = setup_store();

        for i in 0..5 {
            store
                .add(&create_test_link(
                    &format!("commit-{i}"),
                    "session-1",
                    "main",
                ))
                .unwrap();
        }

        let recent = store.list_recent(3).unwrap();
        assert_eq!(recent.len(), 3);
    }

    #[test]
    fn test_find_by_file() {
        let (store, _dir) = setup_store();

        let mut link1 = create_test_link("commit-1", "session-1", "main");
        link1.files_changed = vec!["src/main.rs".to_string()];

        let mut link2 = create_test_link("commit-2", "session-1", "main");
        link2.files_changed = vec!["src/lib.rs".to_string()];

        let mut link3 = create_test_link("commit-3", "session-1", "main");
        link3.files_changed = vec!["src/main.rs".to_string(), "tests/test.rs".to_string()];

        store.add(&link1).unwrap();
        store.add(&link2).unwrap();
        store.add(&link3).unwrap();

        let main_commits = store.find_by_file("src/main.rs", 10).unwrap();
        assert_eq!(main_commits.len(), 2);

        let lib_commits = store.find_by_file("src/lib.rs", 10).unwrap();
        assert_eq!(lib_commits.len(), 1);
    }

    #[test]
    fn test_prune() {
        let (store, _dir) = setup_store();

        store
            .add(&create_test_link("commit-1", "session-1", "main"))
            .unwrap();

        // Prune commits older than 30 days (should delete nothing)
        let deleted = store.prune(30).unwrap();
        assert_eq!(deleted, 0);

        let links = store.list_recent(10).unwrap();
        assert_eq!(links.len(), 1);
    }

    #[test]
    fn test_json_arrays_serialization() {
        let (store, _dir) = setup_store();

        let link = CommitLink::new(
            "abc123".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "main".to_string(),
            "Test".to_string(),
            vec![
                "file1.rs".to_string(),
                "file2.rs".to_string(),
                "file3.rs".to_string(),
            ],
            vec!["prompt-1".to_string(), "prompt-2".to_string()],
            "Test <test@test.com>".to_string(),
        );

        store.add(&link).unwrap();

        let retrieved = store.get("abc123").unwrap().unwrap();
        assert_eq!(retrieved.files_changed.len(), 3);
        assert_eq!(retrieved.prompt_ids.len(), 2);
        assert!(retrieved.files_changed.contains(&"file2.rs".to_string()));
        assert!(retrieved.prompt_ids.contains(&"prompt-2".to_string()));
    }
}
