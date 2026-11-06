//! Worktree storage backend
//!
//! Stores worktree records for tracking git worktrees associated with epics.

use std::path::Path;
use std::sync::{Arc, Mutex};

use chrono::{DateTime, Utc};
use rusqlite::{Connection, OptionalExtension, params};

use crate::error::StoreError;
use cas_types::{Worktree, WorktreeStatus};

type Result<T> = std::result::Result<T, StoreError>;

/// Worktree storage operations
pub trait WorktreeStore: Send + Sync {
    /// Initialize schema
    fn init(&self) -> Result<()>;

    /// Generate a unique worktree ID
    fn generate_id(&self) -> Result<String>;

    /// Add a new worktree record
    fn add(&self, worktree: &Worktree) -> Result<()>;

    /// Get a worktree by ID
    fn get(&self, id: &str) -> Result<Worktree>;

    /// Get worktree by epic ID (active only)
    fn get_by_epic(&self, epic_id: &str) -> Result<Option<Worktree>>;

    /// Get worktree by branch name
    fn get_by_branch(&self, branch: &str) -> Result<Option<Worktree>>;

    /// Get worktree by path
    fn get_by_path(&self, path: &Path) -> Result<Option<Worktree>>;

    /// Update a worktree record
    fn update(&self, worktree: &Worktree) -> Result<()>;

    /// List all worktrees
    fn list(&self) -> Result<Vec<Worktree>>;

    /// List active worktrees
    fn list_active(&self) -> Result<Vec<Worktree>>;

    /// List worktrees by status
    fn list_by_status(&self, status: WorktreeStatus) -> Result<Vec<Worktree>>;

    /// Delete a worktree record
    fn delete(&self, id: &str) -> Result<()>;

    /// Close connection
    fn close(&self) -> Result<()>;
}

/// SQLite-based worktree store
pub struct SqliteWorktreeStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteWorktreeStore {
    /// Open or create a SQLite worktree store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_datetime(s: &str) -> Option<DateTime<Utc>> { todo!() }

    // Column order: id, epic_id, branch, parent_branch, path, status,
    //               created_at, merged_at, removed_at, created_by_agent, merge_commit
    fn worktree_from_row(row: &rusqlite::Row) -> rusqlite::Result<Worktree> { todo!() }
}

impl WorktreeStore for SqliteWorktreeStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, worktree: &Worktree) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Worktree> { todo!() }

    fn get_by_epic(&self, epic_id: &str) -> Result<Option<Worktree>> { todo!() }

    fn get_by_branch(&self, branch: &str) -> Result<Option<Worktree>> { todo!() }

    fn get_by_path(&self, path: &Path) -> Result<Option<Worktree>> { todo!() }

    fn update(&self, worktree: &Worktree) -> Result<()> { todo!() }

    fn list(&self) -> Result<Vec<Worktree>> { todo!() }

    fn list_active(&self) -> Result<Vec<Worktree>> { todo!() }

    fn list_by_status(&self, status: WorktreeStatus) -> Result<Vec<Worktree>> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::worktree_store::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SqliteWorktreeStore) {
        let temp = TempDir::new().unwrap();
        let conn = Connection::open(temp.path().join("cas.db")).unwrap();

        // Create worktrees table with epic_id (no task_id)
        conn.execute_batch(
            "CREATE TABLE IF NOT EXISTS worktrees (
                id TEXT PRIMARY KEY,
                epic_id TEXT,
                branch TEXT NOT NULL,
                parent_branch TEXT NOT NULL,
                path TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'active',
                created_at TEXT NOT NULL,
                merged_at TEXT,
                removed_at TEXT,
                created_by_agent TEXT,
                merge_commit TEXT
            )",
        )
        .unwrap();

        drop(conn);

        let store = SqliteWorktreeStore::open(temp.path()).unwrap();
        (temp, store)
    }


    #[test]
    fn test_get_by_epic() {
        let (_temp, store) = create_test_store();

        let worktree = Worktree::for_epic(
            Worktree::generate_id(),
            "cas-epic-5678".to_string(),
            "cas/cas-epic-5678".to_string(),
            "main".to_string(),
            std::path::PathBuf::from("/tmp/wt1"),
            None,
        );
        store.add(&worktree).unwrap();

        let found = store.get_by_epic("cas-epic-5678").unwrap();
        assert!(found.is_some());
        assert_eq!(found.unwrap().id, worktree.id);

        let not_found = store.get_by_epic("cas-epic-9999").unwrap();
        assert!(not_found.is_none());
    }

}
