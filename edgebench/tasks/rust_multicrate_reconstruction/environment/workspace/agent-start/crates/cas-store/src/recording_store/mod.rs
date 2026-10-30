//! Recording storage backend
//!
//! Stores terminal recording metadata for time-travel playback in factory sessions.

use std::path::Path;
use std::sync::{Arc, Mutex};

use chrono::{DateTime, Utc};
use rusqlite::Connection;

use crate::error::StoreError;
use cas_types::{Recording, RecordingAgent, RecordingEvent, RecordingEventType, RecordingQuery};

type Result<T> = std::result::Result<T, StoreError>;

/// Recording storage operations
pub trait RecordingStore: Send + Sync {
    /// Initialize schema
    fn init(&self) -> Result<()>;

    /// Generate a unique recording ID
    fn generate_id(&self) -> Result<String>;

    /// Add a new recording record
    fn add(&self, recording: &Recording) -> Result<()>;

    /// Get a recording by ID
    fn get(&self, id: &str) -> Result<Recording>;

    /// Update a recording record
    fn update(&self, recording: &Recording) -> Result<()>;

    /// Delete a recording record
    fn delete(&self, id: &str) -> Result<()>;

    /// List all recordings
    fn list(&self) -> Result<Vec<Recording>>;

    /// Query recordings with filters
    fn query(&self, query: &RecordingQuery) -> Result<Vec<Recording>>;

    /// List recordings by session
    fn list_by_session(&self, session_id: &str) -> Result<Vec<Recording>>;

    /// List recordings in a date range
    fn list_by_date_range(&self, from: DateTime<Utc>, to: DateTime<Utc>) -> Result<Vec<Recording>>;

    /// List recordings by agent name
    fn list_by_agent(&self, agent_name: &str) -> Result<Vec<Recording>>;

    // Recording agents

    /// Add an agent to a recording
    fn add_agent(&self, agent: &RecordingAgent) -> Result<i64>;

    /// Get agents for a recording
    fn get_agents(&self, recording_id: &str) -> Result<Vec<RecordingAgent>>;

    /// Delete agents for a recording
    fn delete_agents(&self, recording_id: &str) -> Result<()>;

    // Recording events

    /// Add an event to a recording
    fn add_event(&self, event: &RecordingEvent) -> Result<i64>;

    /// Get events for a recording
    fn get_events(&self, recording_id: &str) -> Result<Vec<RecordingEvent>>;

    /// Get events for a recording in a time range
    fn get_events_in_range(
        &self,
        recording_id: &str,
        from_ms: i64,
        to_ms: i64,
    ) -> Result<Vec<RecordingEvent>>;

    /// Get events linked to a specific CAS entity
    fn get_events_for_entity(
        &self,
        recording_id: &str,
        entity_type: &str,
        entity_id: &str,
    ) -> Result<Vec<RecordingEvent>>;

    /// Delete events for a recording
    fn delete_events(&self, recording_id: &str) -> Result<()>;

    // FTS operations

    /// Add content to FTS index
    fn add_fts_content(
        &self,
        recording_id: &str,
        content: &str,
        content_type: &str,
        timestamp_ms: i64,
    ) -> Result<()>;

    /// Search FTS content
    fn search_fts(&self, query: &str, limit: usize) -> Result<Vec<(String, i64)>>;

    /// Delete FTS content for a recording
    fn delete_fts_content(&self, recording_id: &str) -> Result<()>;

    /// Close connection
    fn close(&self) -> Result<()>;
}

/// SQLite-based recording store
pub struct SqliteRecordingStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteRecordingStore {
    /// Open or create a SQLite recording store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_datetime(s: &str) -> Option<DateTime<Utc>> { todo!() }

    fn recording_from_row(row: &rusqlite::Row) -> rusqlite::Result<Recording> { todo!() }

    fn recording_agent_from_row(row: &rusqlite::Row) -> rusqlite::Result<RecordingAgent> { todo!() }

    fn recording_event_from_row(row: &rusqlite::Row) -> rusqlite::Result<RecordingEvent> { todo!() }
}

mod capture_helpers;
mod store_impl;

pub use capture_helpers::{
    capture_agent_event, capture_memory_event, capture_message_event, capture_recording_event,
    capture_task_event, get_active_recording_with_conn, get_any_active_recording_with_conn,
    record_agent_event_with_conn, record_memory_event_with_conn, record_message_event_with_conn,
    record_recording_event_with_conn, record_task_event_with_conn,
};

#[cfg(test)]
mod tests;
