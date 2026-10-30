//! Notifying entry store wrapper
//!
//! Emits notification events on entry add/update/delete for TUI display.

use std::path::Path;
use std::sync::Arc;

use crate::config::NotificationConfig;
use crate::notifications::{NotificationEvent, get_global_notifier};
use crate::store::{Result, Store};
use crate::types::Entry;

/// An entry store wrapper that emits notification events
pub struct NotifyingEntryStore {
    inner: Arc<dyn Store>,
    config: NotificationConfig,
}

impl NotifyingEntryStore {
    /// Create a new notifying entry store
    pub fn new(inner: Arc<dyn Store>, config: NotificationConfig) -> Self { todo!() }

    fn notify_added(&self, entry: &Entry) { todo!() }

    fn notify_updated(&self, entry: &Entry) { todo!() }

    fn notify_deleted(&self, id: &str) { todo!() }
}

impl Store for NotifyingEntryStore {
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
    use crate::store::notifying_entry::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, NotifyingEntryStore) {
        let temp = TempDir::new().unwrap();
        let cas_dir = temp.path();

        let inner = SqliteStore::open(cas_dir).unwrap();
        inner.init().unwrap();

        let config = NotificationConfig::default();
        let store = NotifyingEntryStore::new(Arc::new(inner), config);
        (temp, store)
    }

    #[test]
    fn test_store_operations_work() {
        let (_temp, store) = create_test_store();

        // Test add
        let entry = Entry::new("entry-001".to_string(), "Test content".to_string());
        store.add(&entry).unwrap();

        // Test get
        let fetched = store.get("entry-001").unwrap();
        assert_eq!(fetched.content, "Test content");

        // Test update
        let mut updated_entry = entry.clone();
        updated_entry.content = "Updated content".to_string();
        store.update(&updated_entry).unwrap();

        let fetched = store.get("entry-001").unwrap();
        assert_eq!(fetched.content, "Updated content");

        // Test delete
        store.delete("entry-001").unwrap();
        assert!(store.get("entry-001").is_err());
    }
}
