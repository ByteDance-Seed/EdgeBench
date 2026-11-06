//! Syncing skill store wrapper
//!
//! Automatically queues skill changes for cloud sync on add/update/delete.

use std::sync::Arc;

use crate::cloud::{EntityType, SyncOperation, SyncQueue};
use crate::store::{Result, SkillStore};
use crate::types::{Skill, SkillStatus};

/// A skill store wrapper that queues changes for cloud sync
pub struct SyncingSkillStore {
    inner: Arc<dyn SkillStore>,
    queue: Arc<SyncQueue>,
}

impl SyncingSkillStore {
    /// Create a new syncing skill store
    pub fn new(inner: Arc<dyn SkillStore>, queue: Arc<SyncQueue>) -> Self { todo!() }

    fn queue_upsert(&self, skill: &Skill) { todo!() }

    fn queue_delete(&self, id: &str) { todo!() }
}

impl SkillStore for SyncingSkillStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, skill: &Skill) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Skill> { todo!() }

    fn update(&self, skill: &Skill) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self, status: Option<SkillStatus>) -> Result<Vec<Skill>> { todo!() }

    fn list_enabled(&self) -> Result<Vec<Skill>> { todo!() }

    fn search(&self, query: &str) -> Result<Vec<Skill>> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::store::SqliteSkillStore;
    use crate::store::syncing_skill::*;
    use crate::types::SkillType;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SyncingSkillStore) {
        let temp = TempDir::new().unwrap();
        let cas_dir = temp.path();

        let inner = SqliteSkillStore::open(cas_dir).unwrap();
        inner.init().unwrap();

        let queue = SyncQueue::open(cas_dir).unwrap();
        queue.init().unwrap();

        let store = SyncingSkillStore::new(Arc::new(inner), Arc::new(queue));
        (temp, store)
    }


    #[test]
    fn test_delete_queues_sync() {
        let (temp, store) = create_test_store();
        let queue = SyncQueue::open(temp.path()).unwrap();

        let mut skill = Skill::new("test-skill-2".to_string(), "Test Skill".to_string());
        skill.description = "A test skill".to_string();
        skill.invocation = "test".to_string();
        skill.skill_type = SkillType::Command;
        store.add(&skill).unwrap();

        // Clear queue
        queue.clear().unwrap();

        store.delete(&skill.id).unwrap();

        let pending = queue.pending(10, 5).unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].operation, SyncOperation::Delete);
    }
}
