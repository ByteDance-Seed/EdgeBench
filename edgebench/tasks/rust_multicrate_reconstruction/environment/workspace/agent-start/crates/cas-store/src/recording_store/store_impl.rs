use crate::Result;
use crate::error::StoreError;
use crate::recording_store::{RecordingStore, SqliteRecordingStore};
use cas_types::{Recording, RecordingAgent, RecordingEvent, RecordingQuery};
use chrono::{DateTime, Utc};
use rusqlite::{OptionalExtension, params};

impl RecordingStore for SqliteRecordingStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, recording: &Recording) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Recording> { todo!() }

    fn update(&self, recording: &Recording) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self) -> Result<Vec<Recording>> { todo!() }

    fn query(&self, query: &RecordingQuery) -> Result<Vec<Recording>> { todo!() }

    fn list_by_session(&self, session_id: &str) -> Result<Vec<Recording>> { todo!() }

    fn list_by_date_range(&self, from: DateTime<Utc>, to: DateTime<Utc>) -> Result<Vec<Recording>> { todo!() }

    fn list_by_agent(&self, agent_name: &str) -> Result<Vec<Recording>> { todo!() }

    fn add_agent(&self, agent: &RecordingAgent) -> Result<i64> { todo!() }

    fn get_agents(&self, recording_id: &str) -> Result<Vec<RecordingAgent>> { todo!() }

    fn delete_agents(&self, recording_id: &str) -> Result<()> { todo!() }

    fn add_event(&self, event: &RecordingEvent) -> Result<i64> { todo!() }

    fn get_events(&self, recording_id: &str) -> Result<Vec<RecordingEvent>> { todo!() }

    fn get_events_in_range(
        &self,
        recording_id: &str,
        from_ms: i64,
        to_ms: i64,
    ) -> Result<Vec<RecordingEvent>> { todo!() }

    fn get_events_for_entity(
        &self,
        recording_id: &str,
        entity_type: &str,
        entity_id: &str,
    ) -> Result<Vec<RecordingEvent>> { todo!() }

    fn delete_events(&self, recording_id: &str) -> Result<()> { todo!() }

    fn add_fts_content(
        &self,
        recording_id: &str,
        content: &str,
        content_type: &str,
        timestamp_ms: i64,
    ) -> Result<()> { todo!() }

    fn search_fts(&self, query: &str, limit: usize) -> Result<Vec<(String, i64)>> { todo!() }

    fn delete_fts_content(&self, recording_id: &str) -> Result<()> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}
