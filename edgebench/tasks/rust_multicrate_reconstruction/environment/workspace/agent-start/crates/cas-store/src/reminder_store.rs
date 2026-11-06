//! Reminder storage for factory "Remind Me" feature
//!
//! Allows agents to schedule one-shot reminders that fire after a time delay
//! or when a specific DirectorEvent occurs. The factory daemon checks pending
//! reminders on each tick and delivers them via the prompt queue for PTY
//! injection into the target agent's session.

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, params};
use serde::{Deserialize, Serialize};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::error::StoreError;

/// How a reminder is triggered
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ReminderTriggerType {
    /// Fire after a time delay
    Time,
    /// Fire when a matching DirectorEvent occurs
    Event,
}

impl std::fmt::Display for ReminderTriggerType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

impl std::str::FromStr for ReminderTriggerType {
    type Err = StoreError;

    fn from_str(s: &str) -> std::result::Result<Self, Self::Err> { todo!() }
}

/// Reminder lifecycle status
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ReminderStatus {
    /// Waiting to fire
    Pending,
    /// Successfully delivered
    Fired,
    /// Cancelled by owner
    Cancelled,
    /// TTL exceeded without firing
    Expired,
}

impl std::fmt::Display for ReminderStatus {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

impl std::str::FromStr for ReminderStatus {
    type Err = StoreError;

    fn from_str(s: &str) -> std::result::Result<Self, Self::Err> { todo!() }
}

/// A scheduled reminder
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Reminder {
    /// Unique reminder ID
    pub id: i64,
    /// Agent ID of whoever created this reminder
    pub owner_id: String,
    /// Agent ID of who should receive the reminder (may differ from owner
    /// when a supervisor sets a reminder for a worker)
    pub target_id: String,
    /// Message to deliver when fired
    pub message: String,
    /// How this reminder is triggered
    pub trigger_type: ReminderTriggerType,
    /// When to fire (time-based triggers only)
    pub trigger_at: Option<DateTime<Utc>>,
    /// Event type to match (event-based triggers only, e.g. "task_completed")
    pub trigger_event: Option<String>,
    /// JSON subset filter for event matching (e.g. {"task_id":"cas-a1b2"})
    pub trigger_filter: Option<serde_json::Value>,
    /// Current status
    pub status: ReminderStatus,
    /// Time-to-live in seconds before auto-expiry
    pub ttl_secs: i64,
    /// When the reminder was created
    pub created_at: DateTime<Utc>,
    /// When the reminder fired (if it did)
    pub fired_at: Option<DateTime<Utc>>,
    /// When the reminder was cancelled (if it was)
    pub cancelled_at: Option<DateTime<Utc>>,
    /// JSON snapshot of the DirectorEvent that triggered this reminder
    /// (only set for event-based reminders after firing)
    pub fired_event: Option<serde_json::Value>,
}

/// Schema for reminders table
const REMINDER_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS reminders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    supervisor_id TEXT NOT NULL,
    message TEXT NOT NULL,
    trigger_type TEXT NOT NULL,
    trigger_at TEXT,
    trigger_event TEXT,
    trigger_filter TEXT,
    status TEXT NOT NULL DEFAULT 'pending',
    ttl_secs INTEGER NOT NULL DEFAULT 3600,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    fired_at TEXT,
    cancelled_at TEXT
);

CREATE INDEX IF NOT EXISTS idx_reminders_pending
    ON reminders(supervisor_id, status) WHERE status = 'pending';
CREATE INDEX IF NOT EXISTS idx_reminders_trigger_at
    ON reminders(trigger_at) WHERE status = 'pending' AND trigger_type = 'time';
"#;

/// Migration to add target_id column (separate from supervisor_id/owner)
const MIGRATION_TARGET_ID: &str = "ALTER TABLE reminders ADD COLUMN target_id TEXT";

/// Migration to add fired_event column (stores triggering event JSON)
const MIGRATION_FIRED_EVENT: &str = "ALTER TABLE reminders ADD COLUMN fired_event TEXT";

/// Trait for reminder storage operations
#[allow(clippy::too_many_arguments)]
pub trait ReminderStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Create a new reminder, returns its ID.
    /// `target_id` is the agent who should receive the reminder. If `None`,
    /// defaults to `owner_id` (self-reminder).
    fn create(
        &self,
        owner_id: &str,
        target_id: Option<&str>,
        message: &str,
        trigger_type: ReminderTriggerType,
        trigger_at: Option<DateTime<Utc>>,
        trigger_event: Option<&str>,
        trigger_filter: Option<&serde_json::Value>,
        ttl_secs: i64,
    ) -> Result<i64>;

    /// List pending reminders owned by a specific agent
    fn list_pending(&self, owner_id: &str) -> Result<Vec<Reminder>>;

    /// List pending reminders targeting a specific agent (set by others)
    fn list_pending_for_target(&self, target_id: &str) -> Result<Vec<Reminder>>;

    /// List all pending reminders (across all agents)
    fn list_all_pending(&self) -> Result<Vec<Reminder>>;

    /// List reminders fired within the last N seconds (across all agents)
    fn list_recently_fired(&self, within_secs: i64) -> Result<Vec<Reminder>>;

    /// Get pending time-based reminders that are due (trigger_at <= now)
    fn get_due_time_reminders(&self) -> Result<Vec<Reminder>>;

    /// Get pending event-based reminders matching a specific event type
    fn get_event_reminders(&self, event_type: &str) -> Result<Vec<Reminder>>;

    /// Mark a reminder as fired, optionally recording the triggering event
    fn mark_fired(&self, id: i64, fired_event: Option<&serde_json::Value>) -> Result<()>;

    /// Cancel a reminder (must belong to the given owner)
    fn cancel(&self, id: i64, owner_id: &str) -> Result<()>;

    /// Expire reminders past their TTL, returns count expired
    fn expire_stale(&self) -> Result<usize>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite-based reminder store
pub struct SqliteReminderStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteReminderStore {
    /// Open or create a SQLite reminder store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_datetime(s: &str) -> Option<DateTime<Utc>> { todo!() }

    fn reminder_from_row(row: &rusqlite::Row) -> rusqlite::Result<Reminder> { todo!() }

    /// Run migrations to add new columns if missing
    fn migrate(&self, conn: &Connection) -> Result<()> { todo!() }

    const SELECT_COLUMNS: &str = "id, supervisor_id, message, trigger_type, trigger_at, trigger_event, trigger_filter, status, ttl_secs, created_at, fired_at, cancelled_at, target_id, fired_event";
}

impl ReminderStore for SqliteReminderStore {
    fn init(&self) -> Result<()> { todo!() }

    fn create(
        &self,
        owner_id: &str,
        target_id: Option<&str>,
        message: &str,
        trigger_type: ReminderTriggerType,
        trigger_at: Option<DateTime<Utc>>,
        trigger_event: Option<&str>,
        trigger_filter: Option<&serde_json::Value>,
        ttl_secs: i64,
    ) -> Result<i64> { todo!() }

    fn list_pending(&self, owner_id: &str) -> Result<Vec<Reminder>> { todo!() }

    fn list_pending_for_target(&self, target_id: &str) -> Result<Vec<Reminder>> { todo!() }

    fn list_all_pending(&self) -> Result<Vec<Reminder>> { todo!() }

    fn list_recently_fired(&self, within_secs: i64) -> Result<Vec<Reminder>> { todo!() }

    fn get_due_time_reminders(&self) -> Result<Vec<Reminder>> { todo!() }

    fn get_event_reminders(&self, event_type: &str) -> Result<Vec<Reminder>> { todo!() }

    fn mark_fired(&self, id: i64, fired_event: Option<&serde_json::Value>) -> Result<()> { todo!() }

    fn cancel(&self, id: i64, owner_id: &str) -> Result<()> { todo!() }

    fn expire_stale(&self) -> Result<usize> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SqliteReminderStore) {
        let temp = TempDir::new().unwrap();
        let store = SqliteReminderStore::open(temp.path()).unwrap();
        store.init().unwrap();
        (temp, store)
    }

    #[test]
    fn test_create_time_reminder() {
        let (_temp, store) = create_test_store();

        let fire_at = Utc::now() + chrono::Duration::seconds(300);
        let id = store
            .create(
                "supervisor-1",
                None,
                "Check worker-3 progress",
                ReminderTriggerType::Time,
                Some(fire_at),
                None,
                None,
                3600,
            )
            .unwrap();

        assert!(id > 0);

        let pending = store.list_pending("supervisor-1").unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].message, "Check worker-3 progress");
        assert_eq!(pending[0].trigger_type, ReminderTriggerType::Time);
        assert!(pending[0].trigger_at.is_some());
        // Self-reminder: target defaults to owner
        assert_eq!(pending[0].owner_id, "supervisor-1");
        assert_eq!(pending[0].target_id, "supervisor-1");
    }

    #[test]
    fn test_create_targeted_reminder() {
        let (_temp, store) = create_test_store();

        let fire_at = Utc::now() + chrono::Duration::seconds(60);
        let id = store
            .create(
                "supervisor-1",
                Some("worker-fox"),
                "Sync your branch",
                ReminderTriggerType::Time,
                Some(fire_at),
                None,
                None,
                3600,
            )
            .unwrap();

        assert!(id > 0);

        let pending = store.list_pending("supervisor-1").unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].owner_id, "supervisor-1");
        assert_eq!(pending[0].target_id, "worker-fox");
        assert_eq!(pending[0].message, "Sync your branch");
    }


    #[test]
    fn test_get_due_time_reminders() {
        let (_temp, store) = create_test_store();

        // Create a reminder that is already due (fire_at in the past)
        let past = Utc::now() - chrono::Duration::seconds(10);
        store
            .create(
                "supervisor-1",
                None,
                "Past reminder",
                ReminderTriggerType::Time,
                Some(past),
                None,
                None,
                3600,
            )
            .unwrap();

        // Create a reminder that is not yet due (fire_at in the future)
        let future = Utc::now() + chrono::Duration::seconds(300);
        store
            .create(
                "supervisor-1",
                None,
                "Future reminder",
                ReminderTriggerType::Time,
                Some(future),
                None,
                None,
                3600,
            )
            .unwrap();

        let due = store.get_due_time_reminders().unwrap();
        assert_eq!(due.len(), 1);
        assert_eq!(due[0].message, "Past reminder");
    }


    #[test]
    fn test_mark_fired() {
        let (_temp, store) = create_test_store();

        let past = Utc::now() - chrono::Duration::seconds(10);
        let id = store
            .create(
                "supervisor-1",
                None,
                "Fire me",
                ReminderTriggerType::Time,
                Some(past),
                None,
                None,
                3600,
            )
            .unwrap();

        let event = serde_json::json!({
            "event_type": "task_completed",
            "data": {"task_id": "cas-123", "worker": "swift-fox"},
            "description": "swift-fox completed task cas-123",
        });
        store.mark_fired(id, Some(&event)).unwrap();

        // Should no longer appear in pending
        let pending = store.list_pending("supervisor-1").unwrap();
        assert!(pending.is_empty());

        // Should no longer appear in due
        let due = store.get_due_time_reminders().unwrap();
        assert!(due.is_empty());

        // Fired event should be persisted in recently fired list
        let fired = store.list_recently_fired(60).unwrap();
        assert_eq!(fired.len(), 1);
        assert_eq!(
            fired[0].fired_event.as_ref().unwrap()["event_type"],
            "task_completed"
        );

        // Double-fire should fail
        assert!(store.mark_fired(id, None).is_err());
    }


    #[test]
    fn test_expire_stale() {
        let (_temp, store) = create_test_store();

        // Create with very short TTL (1 second)
        let future = Utc::now() + chrono::Duration::seconds(9999);
        store
            .create(
                "supervisor-1",
                None,
                "Will expire",
                ReminderTriggerType::Time,
                Some(future),
                None,
                None,
                1, // 1 second TTL
            )
            .unwrap();

        // Create with long TTL
        store
            .create(
                "supervisor-1",
                None,
                "Will not expire",
                ReminderTriggerType::Time,
                Some(future),
                None,
                None,
                99999,
            )
            .unwrap();

        // Sleep briefly so the short-TTL reminder expires
        std::thread::sleep(std::time::Duration::from_secs(2));

        let expired = store.expire_stale().unwrap();
        assert_eq!(expired, 1);

        let pending = store.list_pending("supervisor-1").unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].message, "Will not expire");
    }

    #[test]
    fn test_owner_scoping() {
        let (_temp, store) = create_test_store();

        store
            .create(
                "supervisor-1",
                None,
                "For sup 1",
                ReminderTriggerType::Event,
                None,
                Some("task_completed"),
                None,
                3600,
            )
            .unwrap();

        store
            .create(
                "supervisor-2",
                None,
                "For sup 2",
                ReminderTriggerType::Event,
                None,
                Some("task_completed"),
                None,
                3600,
            )
            .unwrap();

        let pending1 = store.list_pending("supervisor-1").unwrap();
        assert_eq!(pending1.len(), 1);
        assert_eq!(pending1[0].message, "For sup 1");

        let pending2 = store.list_pending("supervisor-2").unwrap();
        assert_eq!(pending2.len(), 1);
        assert_eq!(pending2[0].message, "For sup 2");

        // get_event_reminders returns all owners (daemon processes all)
        let all = store.get_event_reminders("task_completed").unwrap();
        assert_eq!(all.len(), 2);
    }
}
