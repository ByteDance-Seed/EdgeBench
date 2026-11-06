//! Spawn queue for worker lifecycle commands in factory sessions
//!
//! Allows CLI commands and supervisor agents to request worker spawn/shutdown.
//! Factory TUI polls this queue and processes the requests.

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, params};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;

/// Action type for spawn queue
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SpawnAction {
    /// Spawn new workers
    Spawn,
    /// Shutdown existing workers
    Shutdown,
    /// Respawn crashed workers (reuse existing clone)
    Respawn,
}

impl SpawnAction {
    pub fn as_str(&self) -> &'static str { todo!() }

    #[allow(clippy::should_implement_trait)]
    pub fn from_str(s: &str) -> Option<Self> { todo!() }
}

/// A request in the spawn queue
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SpawnRequest {
    /// Unique request ID
    pub id: i64,
    /// Action type (spawn or shutdown)
    pub action: SpawnAction,
    /// Number of workers (for spawn: how many to create; for shutdown: how many to remove, 0 = all)
    pub count: Option<i32>,
    /// Specific worker names (comma-separated in DB, Vec here)
    pub worker_names: Vec<String>,
    /// Force operation even with dirty worktree (for shutdown)
    pub force: bool,
    /// Whether spawned workers should be isolated in their own git worktrees
    pub isolate: bool,
    /// When the request was queued
    pub created_at: DateTime<Utc>,
    /// When the request was processed (None if pending)
    pub processed_at: Option<DateTime<Utc>>,
}

/// Schema for spawn queue table
const SPAWN_QUEUE_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS spawn_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    action TEXT NOT NULL,
    count INTEGER,
    worker_names TEXT,
    force INTEGER NOT NULL DEFAULT 0,
    isolate INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    processed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_spawn_queue_pending ON spawn_queue(action) WHERE processed_at IS NULL;
"#;

/// Migration to add force column
const SPAWN_QUEUE_MIGRATION_FORCE: &str = r#"
ALTER TABLE spawn_queue ADD COLUMN force INTEGER NOT NULL DEFAULT 0;
"#;

/// Migration to add isolate column
const SPAWN_QUEUE_MIGRATION_ISOLATE: &str = r#"
ALTER TABLE spawn_queue ADD COLUMN isolate INTEGER NOT NULL DEFAULT 0;
"#;

/// Trait for spawn queue operations
pub trait SpawnQueueStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Queue a spawn request
    fn enqueue_spawn(&self, count: i32, worker_names: &[String], isolate: bool) -> Result<i64>;

    /// Queue a shutdown request
    fn enqueue_shutdown(
        &self,
        count: Option<i32>,
        worker_names: &[String],
        force: bool,
    ) -> Result<i64>;

    /// Queue a respawn request (for crashed workers)
    fn enqueue_respawn(&self, worker_names: &[String]) -> Result<i64>;

    /// Poll for pending requests (marks as processed)
    fn poll(&self, limit: usize) -> Result<Vec<SpawnRequest>>;

    /// Peek at pending requests without marking as processed
    fn peek(&self, limit: usize) -> Result<Vec<SpawnRequest>>;

    /// Mark a request as processed
    fn mark_processed(&self, request_id: i64) -> Result<()>;

    /// Get count of pending requests
    fn pending_count(&self) -> Result<usize>;

    /// Clear all requests (for cleanup)
    fn clear(&self) -> Result<usize>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite-based spawn queue store
pub struct SqliteSpawnQueueStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSpawnQueueStore {
    /// Open or create a SQLite spawn queue store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_datetime(s: &str) -> Option<DateTime<Utc>> { todo!() }

    fn parse_worker_names(s: Option<String>) -> Vec<String> { todo!() }

    fn request_from_row(row: &rusqlite::Row) -> rusqlite::Result<SpawnRequest> { todo!() }

    fn enqueue(
        &self,
        action: SpawnAction,
        count: Option<i32>,
        worker_names: &[String],
        force: bool,
        isolate: bool,
    ) -> Result<i64> { todo!() }
}

impl SpawnQueueStore for SqliteSpawnQueueStore {
    fn init(&self) -> Result<()> { todo!() }

    fn enqueue_spawn(&self, count: i32, worker_names: &[String], isolate: bool) -> Result<i64> { todo!() }

    fn enqueue_shutdown(
        &self,
        count: Option<i32>,
        worker_names: &[String],
        force: bool,
    ) -> Result<i64> { todo!() }

    fn enqueue_respawn(&self, worker_names: &[String]) -> Result<i64> { todo!() }

    fn poll(&self, limit: usize) -> Result<Vec<SpawnRequest>> { todo!() }

    fn peek(&self, limit: usize) -> Result<Vec<SpawnRequest>> { todo!() }

    fn mark_processed(&self, request_id: i64) -> Result<()> { todo!() }

    fn pending_count(&self) -> Result<usize> { todo!() }

    fn clear(&self) -> Result<usize> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::spawn_queue_store::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SqliteSpawnQueueStore) {
        let temp = TempDir::new().unwrap();
        let store = SqliteSpawnQueueStore::open(temp.path()).unwrap();
        store.init().unwrap();
        (temp, store)
    }

    #[test]
    fn test_enqueue_spawn_and_poll() {
        let (_temp, store) = create_test_store();

        // Queue a spawn request
        let id = store.enqueue_spawn(2, &[], false).unwrap();
        assert!(id > 0);

        // Poll should return it
        let requests = store.poll(10).unwrap();
        assert_eq!(requests.len(), 1);
        assert_eq!(requests[0].action, SpawnAction::Spawn);
        assert_eq!(requests[0].count, Some(2));
        assert!(requests[0].worker_names.is_empty());

        // Polling again should return empty (already processed)
        let requests = store.poll(10).unwrap();
        assert!(requests.is_empty());
    }

    #[test]
    fn test_enqueue_shutdown_with_names() {
        let (_temp, store) = create_test_store();

        // Queue a shutdown request with specific workers
        let names = vec!["swift-fox".to_string(), "calm-owl".to_string()];
        store.enqueue_shutdown(None, &names, false).unwrap();

        let requests = store.poll(10).unwrap();
        assert_eq!(requests.len(), 1);
        assert_eq!(requests[0].action, SpawnAction::Shutdown);
        assert_eq!(requests[0].count, None);
        assert_eq!(requests[0].worker_names, names);
        assert!(!requests[0].force);
    }

    #[test]
    fn test_enqueue_shutdown_with_force() {
        let (_temp, store) = create_test_store();

        // Queue a shutdown request with force=true
        store.enqueue_shutdown(Some(1), &[], true).unwrap();

        let requests = store.poll(10).unwrap();
        assert_eq!(requests.len(), 1);
        assert_eq!(requests[0].action, SpawnAction::Shutdown);
        assert!(requests[0].force);
    }

    #[test]
    fn test_peek_does_not_process() {
        let (_temp, store) = create_test_store();

        store.enqueue_spawn(3, &[], false).unwrap();

        // Peek should return request
        let requests = store.peek(10).unwrap();
        assert_eq!(requests.len(), 1);

        // Peek again should still return it
        let requests = store.peek(10).unwrap();
        assert_eq!(requests.len(), 1);

        // Pending count should be 1
        assert_eq!(store.pending_count().unwrap(), 1);
    }

    #[test]
    fn test_fifo_ordering() {
        let (_temp, store) = create_test_store();

        store.enqueue_spawn(1, &[], false).unwrap();
        store.enqueue_spawn(2, &[], false).unwrap();
        store
            .enqueue_shutdown(None, &["worker-1".to_string()], false)
            .unwrap();

        let requests = store.poll(10).unwrap();
        assert_eq!(requests.len(), 3);
        assert_eq!(requests[0].action, SpawnAction::Spawn);
        assert_eq!(requests[0].count, Some(1));
        assert_eq!(requests[1].action, SpawnAction::Spawn);
        assert_eq!(requests[1].count, Some(2));
        assert_eq!(requests[2].action, SpawnAction::Shutdown);
    }


    #[test]
    fn test_enqueue_respawn() {
        let (_temp, store) = create_test_store();

        // Queue a respawn request
        let names = vec!["crashed-worker".to_string()];
        store.enqueue_respawn(&names).unwrap();

        let requests = store.poll(10).unwrap();
        assert_eq!(requests.len(), 1);
        assert_eq!(requests[0].action, SpawnAction::Respawn);
        assert_eq!(requests[0].count, None);
        assert_eq!(requests[0].worker_names, names);
    }

}
