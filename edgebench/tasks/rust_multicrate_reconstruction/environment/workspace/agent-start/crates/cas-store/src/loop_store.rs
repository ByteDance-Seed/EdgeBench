//! Loop storage for iteration loops
//!
//! Stores loop state in SQLite for persistence across hook invocations.

use chrono::{DateTime, Utc};
use rusqlite::{Connection, OptionalExtension, params};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::error::StoreError;
use cas_types::{Loop, LoopStatus};

// Helper to convert lock errors
fn lock_err<T>(_: std::sync::PoisonError<T>) -> StoreError { todo!() }

const LOOP_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS loops (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    prompt TEXT NOT NULL,
    completion_promise TEXT,
    iteration INTEGER NOT NULL DEFAULT 1,
    max_iterations INTEGER NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    task_id TEXT,
    started_at TEXT NOT NULL,
    ended_at TEXT,
    end_reason TEXT,
    cwd TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_loops_session ON loops(session_id);
CREATE INDEX IF NOT EXISTS idx_loops_status ON loops(status);
CREATE INDEX IF NOT EXISTS idx_loops_started ON loops(started_at DESC);
"#;

/// Trait for loop storage operations
pub trait LoopStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Generate a new unique loop ID (e.g., loop-a1b2)
    fn generate_id(&self) -> Result<String>;

    /// Add a new loop
    fn add(&self, loop_state: &Loop) -> Result<()>;

    /// Get a loop by ID
    fn get(&self, id: &str) -> Result<Loop>;

    /// Update an existing loop
    fn update(&self, loop_state: &Loop) -> Result<()>;

    /// Delete a loop
    fn delete(&self, id: &str) -> Result<()>;

    /// Get active loop for a session (if any)
    fn get_active_for_session(&self, session_id: &str) -> Result<Option<Loop>>;

    /// List recent loops
    fn list_recent(&self, limit: usize) -> Result<Vec<Loop>>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite-based loop store
pub struct SqliteLoopStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteLoopStore {
    /// Open or create a SQLite loop store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_loop(row: &rusqlite::Row) -> rusqlite::Result<Loop> { todo!() }
}

impl LoopStore for SqliteLoopStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, loop_state: &Loop) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Loop> { todo!() }

    fn update(&self, loop_state: &Loop) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn get_active_for_session(&self, session_id: &str) -> Result<Option<Loop>> { todo!() }

    fn list_recent(&self, limit: usize) -> Result<Vec<Loop>> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

// Import FromStr for LoopStatus
use std::str::FromStr;

#[cfg(test)]
mod tests {
    use crate::loop_store::*;
    use tempfile::TempDir;

    fn create_test_store() -> (SqliteLoopStore, TempDir) {
        let dir = TempDir::new().unwrap();
        let store = SqliteLoopStore::open(dir.path()).unwrap();
        (store, dir)
    }

    #[test]
    fn test_add_and_get_loop() {
        let (store, _dir) = create_test_store();

        let loop_state = Loop::new(
            "loop-test".to_string(),
            "session-123".to_string(),
            "Build something".to_string(),
            "/project".to_string(),
        );

        store.add(&loop_state).unwrap();

        let retrieved = store.get("loop-test").unwrap();
        assert_eq!(retrieved.id, "loop-test");
        assert_eq!(retrieved.session_id, "session-123");
        assert_eq!(retrieved.prompt, "Build something");
        assert_eq!(retrieved.iteration, 1);
        assert!(retrieved.is_active());
    }

    #[test]
    fn test_update_loop() {
        let (store, _dir) = create_test_store();

        let mut loop_state = Loop::new(
            "loop-test".to_string(),
            "session-123".to_string(),
            "Build something".to_string(),
            "/project".to_string(),
        );

        store.add(&loop_state).unwrap();

        loop_state.increment();
        loop_state.increment();
        store.update(&loop_state).unwrap();

        let retrieved = store.get("loop-test").unwrap();
        assert_eq!(retrieved.iteration, 3);
    }

    #[test]
    fn test_get_active_for_session() {
        let (store, _dir) = create_test_store();

        // No active loop initially
        let result = store.get_active_for_session("session-123").unwrap();
        assert!(result.is_none());

        // Add an active loop
        let loop_state = Loop::new(
            "loop-test".to_string(),
            "session-123".to_string(),
            "Build something".to_string(),
            "/project".to_string(),
        );
        store.add(&loop_state).unwrap();

        let result = store.get_active_for_session("session-123").unwrap();
        assert!(result.is_some());
        assert_eq!(result.unwrap().id, "loop-test");

        // Complete the loop
        let mut completed = store.get("loop-test").unwrap();
        completed.complete("Done");
        store.update(&completed).unwrap();

        // No active loop anymore
        let result = store.get_active_for_session("session-123").unwrap();
        assert!(result.is_none());
    }

    #[test]
    fn test_list_recent() {
        let (store, _dir) = create_test_store();

        for i in 0..5 {
            let loop_state = Loop::new(
                format!("loop-{i}"),
                "session-123".to_string(),
                format!("Task {i}"),
                "/project".to_string(),
            );
            store.add(&loop_state).unwrap();
        }

        let recent = store.list_recent(3).unwrap();
        assert_eq!(recent.len(), 3);
    }


    #[test]
    fn test_generate_id() {
        let (store, _dir) = create_test_store();

        let id1 = store.generate_id().unwrap();
        let id2 = store.generate_id().unwrap();

        assert!(id1.starts_with("loop-"));
        assert!(id2.starts_with("loop-"));
        // IDs should be unique (though in rapid succession might be same)
    }

}
