use crate::Result;
use crate::error::StoreError;
use crate::event_store::record_event_with_conn;
use crate::recording_store::capture_memory_event;
use crate::sqlite::{SCHEMA, SqliteStore};
use crate::tracing::{DevTracer, TraceTimer};
use cas_types::{Entry, EntryType, Event, EventEntityType, EventType, Scope};
use chrono::Utc;
use rusqlite::{OptionalExtension, params};
use std::str::FromStr;

impl SqliteStore {
    pub(crate) fn store_init(&self) -> Result<()> { todo!() }
    pub(crate) fn store_generate_id(&self) -> Result<String> { todo!() }
    pub(crate) fn store_add(&self, entry: &Entry) -> Result<()> { todo!() }
    pub(crate) fn store_get(&self, id: &str) -> Result<Entry> { todo!() }
    pub(crate) fn store_get_archived(&self, id: &str) -> Result<Entry> { todo!() }
    pub(crate) fn store_update(&self, entry: &Entry) -> Result<()> { todo!() }
    pub(crate) fn store_delete(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn store_list(&self) -> Result<Vec<Entry>> { todo!() }
    pub(crate) fn store_recent(&self, n: usize) -> Result<Vec<Entry>> { todo!() }
    pub(crate) fn store_archive(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn store_unarchive(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn store_list_archived(&self) -> Result<Vec<Entry>> { todo!() }
}
