use crate::Result;
use crate::error::StoreError;
use crate::sqlite::SqliteStore;
use cas_types::{Entry, EntryType, Scope};
use chrono::Utc;
use rusqlite::params;
use std::path::Path;
use std::str::FromStr;

impl SqliteStore {
    pub(crate) fn store_list_pending_index(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }
    pub(crate) fn store_mark_indexed(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn store_mark_indexed_batch(&self, ids: &[&str]) -> Result<()> { todo!() }
    pub(crate) fn store_cas_dir(&self) -> &Path { todo!() }
    pub(crate) fn store_close(&self) -> Result<()> { todo!() }
}
