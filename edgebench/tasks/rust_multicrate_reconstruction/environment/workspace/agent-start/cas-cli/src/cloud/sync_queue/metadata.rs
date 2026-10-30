use rusqlite::{OptionalExtension, params};

use crate::cloud::sync_queue::SyncQueue;
use crate::error::CasError;

impl SyncQueue {
    /// Get sync metadata value.
    pub fn get_metadata(&self, key: &str) -> Result<Option<String>, CasError> { todo!() }

    /// Set sync metadata value.
    pub fn set_metadata(&self, key: &str, value: &str) -> Result<(), CasError> { todo!() }

    /// Delete sync metadata value.
    pub fn delete_metadata(&self, key: &str) -> Result<(), CasError> { todo!() }
}
