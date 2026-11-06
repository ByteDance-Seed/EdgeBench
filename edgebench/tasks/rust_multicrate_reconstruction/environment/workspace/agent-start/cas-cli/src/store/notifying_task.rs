//! Notifying task store wrapper
//!
//! Emits notification events on task add/update/close for TUI display.

use std::sync::Arc;

use crate::config::NotificationConfig;
use crate::notifications::{NotificationEvent, get_global_notifier};
use crate::store::{Result, TaskStore};
use crate::types::{Dependency, DependencyType, Task, TaskStatus};

/// A task store wrapper that emits notification events
pub struct NotifyingTaskStore {
    inner: Arc<dyn TaskStore>,
    config: NotificationConfig,
}

impl NotifyingTaskStore {
    /// Create a new notifying task store
    pub fn new(inner: Arc<dyn TaskStore>, config: NotificationConfig) -> Self { todo!() }

    fn notify_created(&self, task: &Task) { todo!() }

    fn notify_updated(&self, task: &Task, old_status: Option<TaskStatus>) { todo!() }
}

impl TaskStore for NotifyingTaskStore {
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

    // Dependency operations - delegate without notifications
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
    use crate::store::notifying_task::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, NotifyingTaskStore) {
        let temp = TempDir::new().unwrap();
        let cas_dir = temp.path();

        let inner = SqliteTaskStore::open(cas_dir).unwrap();
        inner.init().unwrap();

        let config = NotificationConfig::default();
        let store = NotifyingTaskStore::new(Arc::new(inner), config);
        (temp, store)
    }

    #[test]
    fn test_store_operations_work() {
        let (_temp, store) = create_test_store();

        // Test add
        let task = Task::new("task-001".to_string(), "Test task".to_string());
        store.add(&task).unwrap();

        // Test get
        let fetched = store.get("task-001").unwrap();
        assert_eq!(fetched.title, "Test task");

        // Test update (status change)
        let mut updated_task = task.clone();
        updated_task.status = TaskStatus::InProgress;
        store.update(&updated_task).unwrap();

        let fetched = store.get("task-001").unwrap();
        assert_eq!(fetched.status, TaskStatus::InProgress);

        // Test close
        updated_task.status = TaskStatus::Closed;
        store.update(&updated_task).unwrap();

        let fetched = store.get("task-001").unwrap();
        assert_eq!(fetched.status, TaskStatus::Closed);

        // Test delete
        store.delete("task-001").unwrap();
        assert!(store.get("task-001").is_err());
    }
}
