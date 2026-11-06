//! Syncing entry store wrapper
//!
//! Automatically queues entry changes for cloud sync on add/update/delete.

use std::path::Path;
use std::sync::Arc;

use crate::cloud::{EntityType, SyncOperation, SyncQueue};
use crate::store::{Result, Store};
use crate::types::Entry;

/// An entry store wrapper that queues changes for cloud sync
pub struct SyncingEntryStore {
    inner: Arc<dyn Store>,
    queue: Arc<SyncQueue>,
}

impl SyncingEntryStore {
    /// Create a new syncing entry store
    pub fn new(inner: Arc<dyn Store>, queue: Arc<SyncQueue>) -> Self { todo!() }

    fn queue_upsert(&self, entry: &Entry) { todo!() }

    fn queue_delete(&self, id: &str) { todo!() }
}

impl Store for SyncingEntryStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, entry: &Entry) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Entry> { todo!() }

    fn get_archived(&self, id: &str) -> Result<Entry> { todo!() }

    fn update(&self, entry: &Entry) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self) -> Result<Vec<Entry>> { todo!() }

    fn recent(&self, n: usize) -> Result<Vec<Entry>> { todo!() }

    fn archive(&self, id: &str) -> Result<()> { todo!() }

    fn unarchive(&self, id: &str) -> Result<()> { todo!() }

    fn list_archived(&self) -> Result<Vec<Entry>> { todo!() }

    fn list_pending(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }

    fn mark_extracted(&self, id: &str) -> Result<()> { todo!() }

    fn list_pinned(&self) -> Result<Vec<Entry>> { todo!() }

    fn list_helpful(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }

    fn list_by_session(&self, session_id: &str) -> Result<Vec<Entry>> { todo!() }

    fn list_unreviewed_learnings(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }

    fn mark_reviewed(&self, id: &str) -> Result<()> { todo!() }

    fn list_pending_index(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }

    fn mark_indexed(&self, id: &str) -> Result<()> { todo!() }

    fn mark_indexed_batch(&self, ids: &[&str]) -> Result<()> { todo!() }

    fn cas_dir(&self) -> &Path { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::store::SqliteStore;
    use crate::store::syncing_entry::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SyncingEntryStore) {
        let temp = TempDir::new().unwrap();
        let cas_dir = temp.path();

        let inner = SqliteStore::open(cas_dir).unwrap();
        inner.init().unwrap();

        let queue = SyncQueue::open(cas_dir).unwrap();
        queue.init().unwrap();

        let store = SyncingEntryStore::new(Arc::new(inner), Arc::new(queue));
        (temp, store)
    }


    #[test]
    fn test_update_queues_sync() {
        let (temp, store) = create_test_store();
        let queue = SyncQueue::open(temp.path()).unwrap();

        let mut entry = Entry::new("entry-002".to_string(), "Test content".to_string());
        store.add(&entry).unwrap();

        // Clear queue
        queue.clear().unwrap();

        entry.content = "Updated content".to_string();
        store.update(&entry).unwrap();

        let pending = queue.pending(10, 5).unwrap();
        assert_eq!(pending.len(), 1);
        assert!(
            pending[0]
                .payload
                .as_ref()
                .unwrap()
                .contains("Updated content")
        );
    }

    #[test]
    fn test_delete_queues_sync() {
        let (temp, store) = create_test_store();
        let queue = SyncQueue::open(temp.path()).unwrap();

        let entry = Entry::new("entry-003".to_string(), "Test content".to_string());
        store.add(&entry).unwrap();

        // Clear queue
        queue.clear().unwrap();

        store.delete(&entry.id).unwrap();

        let pending = queue.pending(10, 5).unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].operation, SyncOperation::Delete);
    }
}
