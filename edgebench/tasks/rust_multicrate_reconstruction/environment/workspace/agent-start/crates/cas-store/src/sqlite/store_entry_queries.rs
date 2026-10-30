use crate::Result;
use crate::error::StoreError;
use crate::sqlite::SqliteStore;
use cas_types::{Entry, EntryType, Scope};
use chrono::Utc;
use rusqlite::params;
use std::str::FromStr;

impl SqliteStore {
    pub(crate) fn store_list_pending(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }
    pub(crate) fn store_mark_extracted(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn store_list_pinned(&self) -> Result<Vec<Entry>> { todo!() }
    pub(crate) fn store_list_helpful(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }
    pub(crate) fn store_list_by_session(&self, session_id: &str) -> Result<Vec<Entry>> { todo!() }
    pub(crate) fn store_list_unreviewed_learnings(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }
    pub(crate) fn store_mark_reviewed(&self, id: &str) -> Result<()> { todo!() }
}
