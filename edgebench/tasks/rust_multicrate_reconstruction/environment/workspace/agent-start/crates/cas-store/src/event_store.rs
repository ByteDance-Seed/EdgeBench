//! SQLite-based event storage for activity tracking
//!
//! This module provides storage for events that track significant actions in CAS,
//! powering the sidecar activity feed.

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, params};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::error::StoreError;
use cas_types::{Event, EventEntityType, EventType};

/// Helper to convert mutex poison error to StoreError
fn lock_error<T>(_: std::sync::PoisonError<T>) -> StoreError { todo!() }

/// Schema for events table
pub const EVENT_SCHEMA: &str = r#"
-- Events table: activity log for sidecar feed
CREATE TABLE IF NOT EXISTS events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    event_type TEXT NOT NULL,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    summary TEXT NOT NULL,
    metadata TEXT,
    created_at TEXT NOT NULL DEFAULT (datetime('now')),
    session_id TEXT
);

CREATE INDEX IF NOT EXISTS idx_events_created ON events(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_events_type ON events(event_type);
CREATE INDEX IF NOT EXISTS idx_events_entity ON events(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_events_session ON events(session_id);
"#;

/// Trait for event storage operations
pub trait EventStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Record a new event
    fn record(&self, event: &Event) -> Result<i64>;

    /// Get recent events (most recent first)
    fn list_recent(&self, limit: usize) -> Result<Vec<Event>>;

    /// Get events for a specific entity
    fn list_for_entity(
        &self,
        entity_type: EventEntityType,
        entity_id: &str,
        limit: usize,
    ) -> Result<Vec<Event>>;

    /// Get events by type
    fn list_by_type(&self, event_type: EventType, limit: usize) -> Result<Vec<Event>>;

    /// Get events since a specific timestamp
    fn list_since(&self, since: DateTime<Utc>, limit: usize) -> Result<Vec<Event>>;

    /// Get events for a specific session
    fn list_by_session(&self, session_id: &str, limit: usize) -> Result<Vec<Event>>;

    /// Get event count by type (for stats)
    fn count_by_type(&self) -> Result<Vec<(EventType, i64)>>;

    /// Prune old events (keep last N days)
    fn prune(&self, days: i64) -> Result<usize>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite implementation of EventStore
pub struct SqliteEventStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteEventStore {
    /// Open or create an event store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    /// Create from an existing connection (for use within other stores)
    pub fn from_connection(conn: Connection) -> Result<Self> { todo!() }

    /// Parse a row into an Event
    fn row_to_event(row: &rusqlite::Row) -> rusqlite::Result<Event> { todo!() }
}

impl EventStore for SqliteEventStore {
    fn init(&self) -> Result<()> { todo!() }

    fn record(&self, event: &Event) -> Result<i64> { todo!() }

    fn list_recent(&self, limit: usize) -> Result<Vec<Event>> { todo!() }

    fn list_for_entity(
        &self,
        entity_type: EventEntityType,
        entity_id: &str,
        limit: usize,
    ) -> Result<Vec<Event>> { todo!() }

    fn list_by_type(&self, event_type: EventType, limit: usize) -> Result<Vec<Event>> { todo!() }

    fn list_since(&self, since: DateTime<Utc>, limit: usize) -> Result<Vec<Event>> { todo!() }

    fn list_by_session(&self, session_id: &str, limit: usize) -> Result<Vec<Event>> { todo!() }

    fn count_by_type(&self) -> Result<Vec<(EventType, i64)>> { todo!() }

    fn prune(&self, days: i64) -> Result<usize> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

/// Parse a datetime string, with fallback to current time
fn parse_datetime(s: &str) -> DateTime<Utc> { todo!() }

/// Helper to record an event using the connection from another store
pub fn record_event_with_conn(
    conn: &Connection,
    event: &Event,
) -> std::result::Result<i64, rusqlite::Error> { todo!() }

#[cfg(test)]
mod tests {
    use crate::event_store::*;
    use tempfile::TempDir;

    fn setup_store() -> (SqliteEventStore, TempDir) {
        let temp_dir = TempDir::new().unwrap();
        let store = SqliteEventStore::open(temp_dir.path()).unwrap();
        (store, temp_dir)
    }

    #[test]
    fn test_record_and_list() {
        let (store, _dir) = setup_store();

        let event = Event::new(
            EventType::TaskStarted,
            EventEntityType::Task,
            "cas-abc1",
            "Task started: Fix the bug",
        );

        let id = store.record(&event).unwrap();
        assert!(id > 0);

        let events = store.list_recent(10).unwrap();
        assert_eq!(events.len(), 1);
        assert_eq!(events[0].entity_id, "cas-abc1");
        assert_eq!(events[0].event_type, EventType::TaskStarted);
    }

    #[test]
    fn test_list_by_type() {
        let (store, _dir) = setup_store();

        store
            .record(&Event::new(
                EventType::TaskStarted,
                EventEntityType::Task,
                "cas-1",
                "Started task 1",
            ))
            .unwrap();

        store
            .record(&Event::new(
                EventType::MemoryStored,
                EventEntityType::Entry,
                "entry-1",
                "Stored memory",
            ))
            .unwrap();

        store
            .record(&Event::new(
                EventType::TaskStarted,
                EventEntityType::Task,
                "cas-2",
                "Started task 2",
            ))
            .unwrap();

        let task_events = store.list_by_type(EventType::TaskStarted, 10).unwrap();
        assert_eq!(task_events.len(), 2);

        let memory_events = store.list_by_type(EventType::MemoryStored, 10).unwrap();
        assert_eq!(memory_events.len(), 1);
    }



    #[test]
    fn test_prune() {
        let (store, _dir) = setup_store();

        // Record an event
        store
            .record(&Event::new(
                EventType::TaskStarted,
                EventEntityType::Task,
                "task",
                "Started",
            ))
            .unwrap();

        // Prune events older than 30 days (should delete nothing)
        let deleted = store.prune(30).unwrap();
        assert_eq!(deleted, 0);

        let events = store.list_recent(10).unwrap();
        assert_eq!(events.len(), 1);
    }

}
