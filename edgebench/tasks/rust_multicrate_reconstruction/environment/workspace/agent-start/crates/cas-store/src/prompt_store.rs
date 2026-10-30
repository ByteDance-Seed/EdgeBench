//! SQLite-based prompt storage for tracking user prompts in AI sessions
//!
//! This module provides storage for prompts that enables code attribution:
//! tracing any line of code back to the prompt that triggered its creation.

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, OptionalExtension, params};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::error::StoreError;
use cas_types::{Message, Prompt, Scope};

/// Helper to convert mutex poison error to StoreError
fn lock_error<T>(_: std::sync::PoisonError<T>) -> StoreError { todo!() }

/// Schema for prompts table (also defined in migration m141)
pub const PROMPT_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS prompts (
    id TEXT PRIMARY KEY,
    session_id TEXT NOT NULL,
    agent_id TEXT NOT NULL,
    content TEXT NOT NULL,
    content_hash TEXT NOT NULL,
    timestamp TEXT NOT NULL,
    response_started TEXT,
    task_id TEXT,
    scope TEXT NOT NULL DEFAULT 'project',
    -- Blame v2 fields
    messages_json TEXT,
    model TEXT,
    tool_version TEXT,
    UNIQUE(content_hash, session_id)
);

CREATE INDEX IF NOT EXISTS idx_prompts_session ON prompts(session_id);
CREATE INDEX IF NOT EXISTS idx_prompts_timestamp ON prompts(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_prompts_task ON prompts(task_id);
CREATE INDEX IF NOT EXISTS idx_prompts_content_hash ON prompts(content_hash);
"#;

/// Trait for prompt storage operations
pub trait PromptStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Add a new prompt
    fn add(&self, prompt: &Prompt) -> Result<()>;

    /// Get a prompt by ID
    fn get(&self, id: &str) -> Result<Option<Prompt>>;

    /// Get prompt by content hash and session (for deduplication)
    fn get_by_hash(&self, content_hash: &str, session_id: &str) -> Result<Option<Prompt>>;

    /// Get prompts for a session
    fn list_by_session(&self, session_id: &str, limit: usize) -> Result<Vec<Prompt>>;

    /// Get prompts for a task
    fn list_by_task(&self, task_id: &str, limit: usize) -> Result<Vec<Prompt>>;

    /// Get recent prompts (most recent first)
    fn list_recent(&self, limit: usize) -> Result<Vec<Prompt>>;

    /// Get prompts since a specific timestamp
    fn list_since(&self, since: DateTime<Utc>, limit: usize) -> Result<Vec<Prompt>>;

    /// Update response_started timestamp
    fn mark_response_started(&self, id: &str) -> Result<()>;

    /// Update messages, model, and tool_version for a prompt (blame v2)
    fn update_blame_fields(
        &self,
        id: &str,
        messages: &[Message],
        model: Option<&str>,
        tool_version: Option<&str>,
    ) -> Result<()>;

    /// Delete old prompts (keep last N days)
    fn prune(&self, days: i64) -> Result<usize>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite implementation of PromptStore
pub struct SqlitePromptStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqlitePromptStore {
    /// Open or create a prompt store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    /// Create from an existing connection (for use within other stores)
    pub fn from_connection(conn: Connection) -> Result<Self> { todo!() }

    /// Parse a row into a Prompt
    fn row_to_prompt(row: &rusqlite::Row) -> rusqlite::Result<Prompt> { todo!() }

    /// Parse a row into a Prompt for queries that include blame v2 columns
    pub fn row_to_prompt_with_blame(row: &rusqlite::Row) -> rusqlite::Result<Prompt> { todo!() }
}

impl PromptStore for SqlitePromptStore {
    fn init(&self) -> Result<()> { todo!() }

    fn add(&self, prompt: &Prompt) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Option<Prompt>> { todo!() }

    fn get_by_hash(&self, content_hash: &str, session_id: &str) -> Result<Option<Prompt>> { todo!() }

    fn list_by_session(&self, session_id: &str, limit: usize) -> Result<Vec<Prompt>> { todo!() }

    fn list_by_task(&self, task_id: &str, limit: usize) -> Result<Vec<Prompt>> { todo!() }

    fn list_recent(&self, limit: usize) -> Result<Vec<Prompt>> { todo!() }

    fn list_since(&self, since: DateTime<Utc>, limit: usize) -> Result<Vec<Prompt>> { todo!() }

    fn mark_response_started(&self, id: &str) -> Result<()> { todo!() }

    fn update_blame_fields(
        &self,
        id: &str,
        messages: &[Message],
        model: Option<&str>,
        tool_version: Option<&str>,
    ) -> Result<()> { todo!() }

    fn prune(&self, days: i64) -> Result<usize> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

/// Parse a datetime string, with fallback to current time
fn parse_datetime(s: &str) -> DateTime<Utc> { todo!() }

/// Helper to add a prompt using the connection from another store
pub fn add_prompt_with_conn(
    conn: &Connection,
    prompt: &Prompt,
) -> std::result::Result<(), rusqlite::Error> { todo!() }

/// Helper to get the most recent prompt for a session (for linking to file changes)
pub fn get_current_prompt_for_session(
    conn: &Connection,
    session_id: &str,
) -> std::result::Result<Option<Prompt>, rusqlite::Error> { todo!() }

#[cfg(test)]
mod tests {
    use crate::prompt_store::*;
    use tempfile::TempDir;

    fn setup_store() -> (SqlitePromptStore, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let store = SqlitePromptStore::open(temp_dir.path()).unwrap();
        (store, temp_dir)
    }


    #[test]
    fn test_get_by_hash() {
        let (store, _dir) = setup_store();

        let prompt = Prompt::new(
            "prompt-1".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "Test prompt".to_string(),
        );
        let hash = prompt.content_hash.clone();

        store.add(&prompt).unwrap();

        let retrieved = store.get_by_hash(&hash, "session-1").unwrap();
        assert!(retrieved.is_some());
        assert_eq!(retrieved.unwrap().id, "prompt-1");

        // Different session should not find it
        let not_found = store.get_by_hash(&hash, "session-2").unwrap();
        assert!(not_found.is_none());
    }


    #[test]
    fn test_list_by_task() {
        let (store, _dir) = setup_store();

        store
            .add(&Prompt::with_task(
                "prompt-1".to_string(),
                "session-1".to_string(),
                "agent-1".to_string(),
                "Working on task".to_string(),
                Some("cas-abc".to_string()),
            ))
            .unwrap();

        store
            .add(&Prompt::with_task(
                "prompt-2".to_string(),
                "session-1".to_string(),
                "agent-1".to_string(),
                "Still on task".to_string(),
                Some("cas-abc".to_string()),
            ))
            .unwrap();

        store
            .add(&Prompt::new(
                "prompt-3".to_string(),
                "session-1".to_string(),
                "agent-1".to_string(),
                "No task".to_string(),
            ))
            .unwrap();

        let task_prompts = store.list_by_task("cas-abc", 10).unwrap();
        assert_eq!(task_prompts.len(), 2);
    }

    #[test]
    fn test_list_recent() {
        let (store, _dir) = setup_store();

        for i in 0..5 {
            store
                .add(&Prompt::new(
                    format!("prompt-{i}"),
                    "session-1".to_string(),
                    "agent-1".to_string(),
                    format!("Prompt {i}"),
                ))
                .unwrap();
        }

        let recent = store.list_recent(3).unwrap();
        assert_eq!(recent.len(), 3);
    }

    #[test]
    fn test_mark_response_started() {
        let (store, _dir) = setup_store();

        let prompt = Prompt::new(
            "prompt-1".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "Test".to_string(),
        );

        store.add(&prompt).unwrap();

        // Initially no response_started
        let retrieved = store.get("prompt-1").unwrap().unwrap();
        assert!(retrieved.response_started.is_none());

        // Mark response started
        store.mark_response_started("prompt-1").unwrap();

        let retrieved = store.get("prompt-1").unwrap().unwrap();
        assert!(retrieved.response_started.is_some());
    }

    #[test]
    fn test_prune() {
        let (store, _dir) = setup_store();

        // Add a prompt
        store
            .add(&Prompt::new(
                "prompt-1".to_string(),
                "session-1".to_string(),
                "agent-1".to_string(),
                "Test".to_string(),
            ))
            .unwrap();

        // Prune prompts older than 30 days (should delete nothing)
        let deleted = store.prune(30).unwrap();
        assert_eq!(deleted, 0);

        let prompts = store.list_recent(10).unwrap();
        assert_eq!(prompts.len(), 1);
    }


}
