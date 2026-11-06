//! Prompt queue for supervisor → worker communication in factory sessions
//!
//! Allows supervisor agents to send prompts to workers via MCP.
//! Factory TUI polls this queue and injects prompts into worker PTYs.

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, params};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::recording_store::capture_message_event;

/// A prompt in the queue
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueuedPrompt {
    /// Unique prompt ID
    pub id: i64,
    /// Source agent (who sent the prompt)
    pub source: String,
    /// Target agent name or "all_workers"
    pub target: String,
    /// The prompt text to inject
    pub prompt: String,
    /// When the prompt was queued
    pub created_at: DateTime<Utc>,
    /// When the prompt was processed (None if pending)
    pub processed_at: Option<DateTime<Utc>>,
    /// Short summary for UI display
    pub summary: Option<String>,
}

/// Schema for prompt queue table
const PROMPT_QUEUE_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS prompt_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    source TEXT NOT NULL,
    target TEXT NOT NULL,
    prompt TEXT NOT NULL,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    processed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_prompt_queue_pending ON prompt_queue(target) WHERE processed_at IS NULL;
"#;

/// Add factory_session column for multi-session isolation.
/// Uses IF NOT EXISTS via a safe column-add pattern.
const PROMPT_QUEUE_SESSION_MIGRATION: &str = r#"
ALTER TABLE prompt_queue ADD COLUMN factory_session TEXT;
"#;

/// Add summary column for UI display.
const PROMPT_QUEUE_SUMMARY_MIGRATION: &str = r#"
ALTER TABLE prompt_queue ADD COLUMN summary TEXT;
"#;

/// Trait for prompt queue operations
pub trait PromptQueueStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Queue a prompt for a target agent
    fn enqueue(&self, source: &str, target: &str, prompt: &str) -> Result<i64>;

    /// Queue a prompt tagged with a factory session for isolation
    fn enqueue_with_session(
        &self,
        source: &str,
        target: &str,
        prompt: &str,
        factory_session: &str,
    ) -> Result<i64>;

    /// Queue a prompt with session and summary for UI display
    fn enqueue_with_summary(
        &self,
        source: &str,
        target: &str,
        prompt: &str,
        factory_session: Option<&str>,
        summary: Option<&str>,
    ) -> Result<i64>;

    /// Poll for pending prompts for a specific target (marks as processed)
    fn poll_for_target(&self, target: &str, limit: usize) -> Result<Vec<QueuedPrompt>>;

    /// Poll all pending prompts (for Factory TUI to process)
    fn poll_all(&self, limit: usize) -> Result<Vec<QueuedPrompt>>;

    /// Peek at pending prompts without marking as processed
    fn peek_all(&self, limit: usize) -> Result<Vec<QueuedPrompt>>;

    /// Peek at pending prompts for specific targets only.
    ///
    /// Only returns messages whose target is in `targets`.
    /// When `factory_session` is provided, also returns session-tagged messages
    /// for that session (even if target doesn't match — belt-and-suspenders).
    /// This prevents one factory daemon from consuming messages meant for
    /// another daemon's workers/supervisor in multi-session setups.
    fn peek_for_targets(
        &self,
        targets: &[&str],
        factory_session: Option<&str>,
        limit: usize,
    ) -> Result<Vec<QueuedPrompt>>;

    /// Mark a prompt as processed
    fn mark_processed(&self, prompt_id: i64) -> Result<()>;

    /// Get count of pending prompts
    fn pending_count(&self) -> Result<usize>;

    /// Clear all prompts (for cleanup)
    fn clear(&self) -> Result<usize>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite-based prompt queue store
pub struct SqlitePromptQueueStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqlitePromptQueueStore {
    /// Open or create a SQLite prompt queue store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_datetime(s: &str) -> Option<DateTime<Utc>> { todo!() }

    fn prompt_from_row(row: &rusqlite::Row) -> rusqlite::Result<QueuedPrompt> { todo!() }
}

impl PromptQueueStore for SqlitePromptQueueStore {
    fn init(&self) -> Result<()> { todo!() }

    fn enqueue(&self, source: &str, target: &str, prompt: &str) -> Result<i64> { todo!() }

    fn enqueue_with_session(
        &self,
        source: &str,
        target: &str,
        prompt: &str,
        factory_session: &str,
    ) -> Result<i64> { todo!() }

    fn enqueue_with_summary(
        &self,
        source: &str,
        target: &str,
        prompt: &str,
        factory_session: Option<&str>,
        summary: Option<&str>,
    ) -> Result<i64> { todo!() }

    fn poll_for_target(&self, target: &str, limit: usize) -> Result<Vec<QueuedPrompt>> { todo!() }

    fn poll_all(&self, limit: usize) -> Result<Vec<QueuedPrompt>> { todo!() }

    fn peek_all(&self, limit: usize) -> Result<Vec<QueuedPrompt>> { todo!() }

    fn peek_for_targets(
        &self,
        targets: &[&str],
        factory_session: Option<&str>,
        limit: usize,
    ) -> Result<Vec<QueuedPrompt>> { todo!() }

    fn mark_processed(&self, prompt_id: i64) -> Result<()> { todo!() }

    fn pending_count(&self) -> Result<usize> { todo!() }

    fn clear(&self) -> Result<usize> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::prompt_queue_store::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SqlitePromptQueueStore) {
        let temp = TempDir::new().unwrap();
        let store = SqlitePromptQueueStore::open(temp.path()).unwrap();
        store.init().unwrap();
        (temp, store)
    }

    #[test]
    fn test_enqueue_and_poll() {
        let (_temp, store) = create_test_store();

        // Queue a prompt
        let id = store
            .enqueue("supervisor", "swift-fox", "Hello worker!")
            .unwrap();
        assert!(id > 0);

        // Poll should return it
        let prompts = store.poll_all(10).unwrap();
        assert_eq!(prompts.len(), 1);
        assert_eq!(prompts[0].target, "swift-fox");
        assert_eq!(prompts[0].prompt, "Hello worker!");

        // Polling again should return empty (already processed)
        let prompts = store.poll_all(10).unwrap();
        assert!(prompts.is_empty());
    }

    #[test]
    fn test_all_workers_target() {
        let (_temp, store) = create_test_store();

        // Queue to all_workers
        store
            .enqueue("supervisor", "all_workers", "Everyone listen up!")
            .unwrap();

        // Any worker should see it
        let prompts = store.poll_for_target("swift-fox", 10).unwrap();
        assert_eq!(prompts.len(), 1);
        assert_eq!(prompts[0].target, "all_workers");
    }

    #[test]
    fn test_peek_does_not_process() {
        let (_temp, store) = create_test_store();

        store.enqueue("supervisor", "worker-1", "Test").unwrap();

        // Peek should return prompt
        let prompts = store.peek_all(10).unwrap();
        assert_eq!(prompts.len(), 1);

        // Peek again should still return it
        let prompts = store.peek_all(10).unwrap();
        assert_eq!(prompts.len(), 1);

        // Pending count should be 1
        assert_eq!(store.pending_count().unwrap(), 1);
    }

    #[test]
    fn test_fifo_ordering() {
        let (_temp, store) = create_test_store();

        store.enqueue("supervisor", "worker", "First").unwrap();
        store.enqueue("supervisor", "worker", "Second").unwrap();
        store.enqueue("supervisor", "worker", "Third").unwrap();

        let prompts = store.poll_all(10).unwrap();
        assert_eq!(prompts.len(), 3);
        assert_eq!(prompts[0].prompt, "First");
        assert_eq!(prompts[1].prompt, "Second");
        assert_eq!(prompts[2].prompt, "Third");
    }


    #[test]
    fn test_session_isolation_peek_for_targets() {
        let (_temp, store) = create_test_store();

        // Session A messages
        store
            .enqueue_with_session("supervisor-a", "worker-a1", "Task for A1", "session-a")
            .unwrap();
        store
            .enqueue_with_session("supervisor-a", "worker-a2", "Task for A2", "session-a")
            .unwrap();

        // Session B messages
        store
            .enqueue_with_session("supervisor-b", "worker-b1", "Task for B1", "session-b")
            .unwrap();

        // Legacy message (no session tag)
        store
            .enqueue("supervisor-a", "worker-a1", "Legacy msg")
            .unwrap();

        // Session A should only see its own messages + legacy for its targets
        let targets_a = &["supervisor-a", "worker-a1", "worker-a2", "all_workers"];
        let prompts_a = store
            .peek_for_targets(targets_a, Some("session-a"), 10)
            .unwrap();
        assert_eq!(prompts_a.len(), 3); // 2 session-tagged + 1 legacy by target match
        assert!(prompts_a.iter().all(|p| p.target != "worker-b1"));

        // Session B should only see its own messages
        let targets_b = &["supervisor-b", "worker-b1", "all_workers"];
        let prompts_b = store
            .peek_for_targets(targets_b, Some("session-b"), 10)
            .unwrap();
        assert_eq!(prompts_b.len(), 1);
        assert_eq!(prompts_b[0].target, "worker-b1");
    }

    #[test]
    fn test_enqueue_with_session_tags_correctly() {
        let (_temp, store) = create_test_store();

        store
            .enqueue_with_session("sup", "worker-1", "Hello", "my-session")
            .unwrap();

        // peek_all still sees it (no session filter)
        let all = store.peek_all(10).unwrap();
        assert_eq!(all.len(), 1);

        // peek_for_targets with wrong session but matching target still sees it
        let by_target = store
            .peek_for_targets(&["worker-1"], Some("other-session"), 10)
            .unwrap();
        assert_eq!(by_target.len(), 1); // target match

        // peek_for_targets with wrong target but matching session still sees it
        let by_session = store
            .peek_for_targets(&["nonexistent"], Some("my-session"), 10)
            .unwrap();
        assert_eq!(by_session.len(), 1); // session match
    }
}
