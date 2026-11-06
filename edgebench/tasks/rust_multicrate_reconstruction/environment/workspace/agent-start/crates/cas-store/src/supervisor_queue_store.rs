//! Supervisor queue storage for factory session Director → Supervisor communication
//!
//! The supervisor queue allows the Director (TUI) to batch notifications and
//! send them to the Supervisor agent. This enables asynchronous, prioritized
//! event delivery in multi-agent factory sessions.

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, params};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::error::StoreError;

/// Priority levels for supervisor queue notifications
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[repr(u8)]
pub enum NotificationPriority {
    /// Critical - agent died, blocking error
    Critical = 0,
    /// High - task completed, needs review
    High = 1,
    /// Normal - status update, informational
    Normal = 2,
}

impl From<u8> for NotificationPriority {
    fn from(value: u8) -> Self { todo!() }
}

impl From<NotificationPriority> for i32 {
    fn from(value: NotificationPriority) -> Self { todo!() }
}

/// A notification in the supervisor queue
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SupervisorNotification {
    /// Unique notification ID
    pub id: i64,
    /// Target supervisor agent ID
    pub supervisor_id: String,
    /// Type of event (e.g., "task_completed", "worker_died", "task_blocked")
    pub event_type: String,
    /// JSON payload with event details
    pub payload: String,
    /// Notification priority
    pub priority: NotificationPriority,
    /// When the notification was created
    pub created_at: DateTime<Utc>,
    /// When the notification was processed (None if pending)
    pub processed_at: Option<DateTime<Utc>>,
}

/// Schema for supervisor queue table
const SUPERVISOR_QUEUE_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS supervisor_queue (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    supervisor_id TEXT NOT NULL,
    event_type TEXT NOT NULL,
    payload TEXT NOT NULL,
    priority INTEGER NOT NULL DEFAULT 2,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    processed_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_supervisor_queue_supervisor ON supervisor_queue(supervisor_id);
CREATE INDEX IF NOT EXISTS idx_supervisor_queue_pending ON supervisor_queue(supervisor_id, priority) WHERE processed_at IS NULL;
"#;

/// Trait for supervisor queue operations
pub trait SupervisorQueueStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Queue a notification for a supervisor
    fn notify(
        &self,
        supervisor_id: &str,
        event_type: &str,
        payload: &str,
        priority: NotificationPriority,
    ) -> Result<i64>;

    /// Poll for pending notifications (ordered by priority, then created_at)
    /// Returns up to `limit` notifications and marks them as processed
    fn poll(&self, supervisor_id: &str, limit: usize) -> Result<Vec<SupervisorNotification>>;

    /// Peek at pending notifications without marking them as processed
    fn peek(&self, supervisor_id: &str, limit: usize) -> Result<Vec<SupervisorNotification>>;

    /// Acknowledge a specific notification (mark as processed)
    fn ack(&self, notification_id: i64) -> Result<()>;

    /// Get count of pending notifications for a supervisor
    fn pending_count(&self, supervisor_id: &str) -> Result<usize>;

    /// Get all pending notifications for a supervisor (without processing)
    fn list_pending(&self, supervisor_id: &str) -> Result<Vec<SupervisorNotification>>;

    /// Clear all notifications for a supervisor (processed and pending)
    fn clear(&self, supervisor_id: &str) -> Result<usize>;

    /// Clear old processed notifications (cleanup)
    fn cleanup_old(&self, older_than_secs: i64) -> Result<usize>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite-based supervisor queue store
pub struct SqliteSupervisorQueueStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSupervisorQueueStore {
    /// Open or create a SQLite supervisor queue store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_datetime(s: &str) -> Option<DateTime<Utc>> { todo!() }

    fn notification_from_row(row: &rusqlite::Row) -> rusqlite::Result<SupervisorNotification> { todo!() }
}

impl SupervisorQueueStore for SqliteSupervisorQueueStore {
    fn init(&self) -> Result<()> { todo!() }

    fn notify(
        &self,
        supervisor_id: &str,
        event_type: &str,
        payload: &str,
        priority: NotificationPriority,
    ) -> Result<i64> { todo!() }

    fn poll(&self, supervisor_id: &str, limit: usize) -> Result<Vec<SupervisorNotification>> { todo!() }

    fn peek(&self, supervisor_id: &str, limit: usize) -> Result<Vec<SupervisorNotification>> { todo!() }

    fn ack(&self, notification_id: i64) -> Result<()> { todo!() }

    fn pending_count(&self, supervisor_id: &str) -> Result<usize> { todo!() }

    fn list_pending(&self, supervisor_id: &str) -> Result<Vec<SupervisorNotification>> { todo!() }

    fn clear(&self, supervisor_id: &str) -> Result<usize> { todo!() }

    fn cleanup_old(&self, older_than_secs: i64) -> Result<usize> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::supervisor_queue_store::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SqliteSupervisorQueueStore) {
        let temp = TempDir::new().unwrap();
        let store = SqliteSupervisorQueueStore::open(temp.path()).unwrap();
        store.init().unwrap();
        (temp, store)
    }

    #[test]
    fn test_notify_and_poll() {
        let (_temp, store) = create_test_store();

        // Queue some notifications
        let id1 = store
            .notify(
                "supervisor-1",
                "task_completed",
                r#"{"task_id": "task-1"}"#,
                NotificationPriority::Normal,
            )
            .unwrap();
        let id2 = store
            .notify(
                "supervisor-1",
                "worker_died",
                r#"{"worker_id": "worker-1"}"#,
                NotificationPriority::Critical,
            )
            .unwrap();

        assert!(id1 > 0);
        assert!(id2 > id1);

        // Poll should return critical first
        let notifications = store.poll("supervisor-1", 10).unwrap();
        assert_eq!(notifications.len(), 2);
        assert_eq!(notifications[0].event_type, "worker_died"); // Critical
        assert_eq!(notifications[1].event_type, "task_completed"); // Normal

        // Polling again should return empty (already processed)
        let notifications = store.poll("supervisor-1", 10).unwrap();
        assert!(notifications.is_empty());
    }

    #[test]
    fn test_peek_does_not_process() {
        let (_temp, store) = create_test_store();

        store
            .notify(
                "supervisor-1",
                "task_completed",
                "{}",
                NotificationPriority::Normal,
            )
            .unwrap();

        // Peek should return notification
        let notifications = store.peek("supervisor-1", 10).unwrap();
        assert_eq!(notifications.len(), 1);

        // Peek again should still return it (not processed)
        let notifications = store.peek("supervisor-1", 10).unwrap();
        assert_eq!(notifications.len(), 1);

        // Pending count should be 1
        let count = store.pending_count("supervisor-1").unwrap();
        assert_eq!(count, 1);
    }

    #[test]
    fn test_ack() {
        let (_temp, store) = create_test_store();

        let id = store
            .notify(
                "supervisor-1",
                "task_completed",
                "{}",
                NotificationPriority::Normal,
            )
            .unwrap();

        // Ack the notification
        store.ack(id).unwrap();

        // Should now be processed
        let count = store.pending_count("supervisor-1").unwrap();
        assert_eq!(count, 0);

        // Ack again should fail
        assert!(store.ack(id).is_err());
    }


    #[test]
    fn test_priority_ordering() {
        let (_temp, store) = create_test_store();

        // Queue in reverse priority order
        store
            .notify("supervisor-1", "normal", "{}", NotificationPriority::Normal)
            .unwrap();
        store
            .notify("supervisor-1", "high", "{}", NotificationPriority::High)
            .unwrap();
        store
            .notify(
                "supervisor-1",
                "critical",
                "{}",
                NotificationPriority::Critical,
            )
            .unwrap();

        // Poll should return in priority order
        let notifications = store.poll("supervisor-1", 10).unwrap();
        assert_eq!(notifications.len(), 3);
        assert_eq!(notifications[0].event_type, "critical");
        assert_eq!(notifications[1].event_type, "high");
        assert_eq!(notifications[2].event_type, "normal");
    }

    #[test]
    fn test_different_supervisors() {
        let (_temp, store) = create_test_store();

        store
            .notify("supervisor-1", "event1", "{}", NotificationPriority::Normal)
            .unwrap();
        store
            .notify("supervisor-2", "event2", "{}", NotificationPriority::Normal)
            .unwrap();

        // Each supervisor should only see their own notifications
        let notifications = store.poll("supervisor-1", 10).unwrap();
        assert_eq!(notifications.len(), 1);
        assert_eq!(notifications[0].event_type, "event1");

        let notifications = store.poll("supervisor-2", 10).unwrap();
        assert_eq!(notifications.len(), 1);
        assert_eq!(notifications[0].event_type, "event2");
    }
}
