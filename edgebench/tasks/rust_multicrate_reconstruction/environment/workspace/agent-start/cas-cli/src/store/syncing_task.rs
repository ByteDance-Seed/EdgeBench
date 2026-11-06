//! Syncing task store wrapper
//!
//! Automatically queues task changes for cloud sync on add/update/delete.

use std::sync::Arc;

use crate::cloud::{EntityType, SyncOperation, SyncQueue};
use crate::store::{Result, TaskStore};
use crate::types::{Dependency, DependencyType, Task, TaskStatus};

/// A task store wrapper that queues changes for cloud sync
pub struct SyncingTaskStore {
    inner: Arc<dyn TaskStore>,
    queue: Arc<SyncQueue>,
}

impl SyncingTaskStore {
    /// Create a new syncing task store
    pub fn new(inner: Arc<dyn TaskStore>, queue: Arc<SyncQueue>) -> Self { todo!() }

    fn queue_upsert(&self, task: &Task) { todo!() }

    fn queue_delete(&self, id: &str) { todo!() }
}

impl TaskStore for SyncingTaskStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, task: &Task) -> Result<()> { todo!() }

    fn create_atomic(
        &self,
        task: &Task,
        blocked_by: &[String],
        epic_id: Option<&str>,
        created_by: Option<&str>,
    ) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Task> { todo!() }

    fn update(&self, task: &Task) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self, status: Option<TaskStatus>) -> Result<Vec<Task>> { todo!() }

    fn list_ready(&self) -> Result<Vec<Task>> { todo!() }

    fn list_blocked(&self) -> Result<Vec<(Task, Vec<Task>)>> { todo!() }

    fn close(&self) -> Result<()> { todo!() }

    // Dependency operations - don't sync these as they're derived from task relationships
    fn add_dependency(&self, dep: &Dependency) -> Result<()> { todo!() }

    fn remove_dependency(&self, from_id: &str, to_id: &str) -> Result<()> { todo!() }

    fn get_dependencies(&self, task_id: &str) -> Result<Vec<Dependency>> { todo!() }

    fn get_dependents(&self, task_id: &str) -> Result<Vec<Dependency>> { todo!() }

    fn get_blockers(&self, task_id: &str) -> Result<Vec<Task>> { todo!() }

    fn would_create_cycle(&self, from_id: &str, to_id: &str) -> Result<bool> { todo!() }

    fn list_dependencies(&self, dep_type: Option<DependencyType>) -> Result<Vec<Dependency>> { todo!() }

    fn get_subtasks(&self, parent_id: &str) -> Result<Vec<Task>> { todo!() }

    fn get_sibling_notes(
        &self,
        epic_id: &str,
        exclude_task_id: &str,
    ) -> Result<Vec<(String, String, String)>> { todo!() }

    fn get_parent_epic(&self, task_id: &str) -> Result<Option<Task>> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::store::SqliteTaskStore;
    use crate::store::syncing_task::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SyncingTaskStore) {
        let temp = TempDir::new().unwrap();
        let cas_dir = temp.path();

        let inner = SqliteTaskStore::open(cas_dir).unwrap();
        inner.init().unwrap();

        let queue = SyncQueue::open(cas_dir).unwrap();
        queue.init().unwrap();

        let store = SyncingTaskStore::new(Arc::new(inner), Arc::new(queue));
        (temp, store)
    }


    #[test]
    fn test_update_queues_sync() {
        let (temp, store) = create_test_store();
        let queue = SyncQueue::open(temp.path()).unwrap();

        let mut task = Task::new("task-002".to_string(), "Test task".to_string());
        store.add(&task).unwrap();

        // Clear queue
        queue.clear().unwrap();

        task.title = "Updated title".to_string();
        store.update(&task).unwrap();

        let pending = queue.pending(10, 5).unwrap();
        assert_eq!(pending.len(), 1);
        assert!(
            pending[0]
                .payload
                .as_ref()
                .unwrap()
                .contains("Updated title")
        );
    }

    #[test]
    fn test_delete_queues_sync() {
        let (temp, store) = create_test_store();
        let queue = SyncQueue::open(temp.path()).unwrap();

        let task = Task::new("task-003".to_string(), "Test task".to_string());
        store.add(&task).unwrap();

        // Clear queue
        queue.clear().unwrap();

        store.delete(&task.id).unwrap();

        let pending = queue.pending(10, 5).unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].operation, SyncOperation::Delete);
    }
}
