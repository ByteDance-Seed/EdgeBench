//! Notifying skill store wrapper
//!
//! Emits notification events on skill add/update for TUI display.

use std::sync::Arc;

use crate::config::NotificationConfig;
use crate::notifications::{NotificationEvent, get_global_notifier};
use crate::store::{Result, SkillStore};
use crate::types::{Skill, SkillStatus};

/// A skill store wrapper that emits notification events
pub struct NotifyingSkillStore {
    inner: Arc<dyn SkillStore>,
    config: NotificationConfig,
}

impl NotifyingSkillStore {
    /// Create a new notifying skill store
    pub fn new(inner: Arc<dyn SkillStore>, config: NotificationConfig) -> Self { todo!() }

    fn notify_created(&self, skill: &Skill) { todo!() }

    fn notify_status_change(&self, skill: &Skill, old_status: Option<SkillStatus>) { todo!() }
}

impl SkillStore for NotifyingSkillStore {
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
    use crate::store::notifying_skill::*;
    use crate::types::SkillType;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, NotifyingSkillStore) {
        let temp = TempDir::new().unwrap();
        let cas_dir = temp.path();

        let inner = SqliteSkillStore::open(cas_dir).unwrap();
        inner.init().unwrap();

        let config = NotificationConfig::default();
        let store = NotifyingSkillStore::new(Arc::new(inner), config);
        (temp, store)
    }

    #[test]
    fn test_store_operations_work() {
        let (_temp, store) = create_test_store();

        // Test add
        let mut skill = Skill::new("skill-001".to_string(), "Test Skill".to_string());
        skill.description = "A test skill".to_string();
        skill.invocation = "test".to_string();
        skill.skill_type = SkillType::Command;
        skill.status = SkillStatus::Disabled;
        store.add(&skill).unwrap();

        // Test get
        let fetched = store.get("skill-001").unwrap();
        assert_eq!(fetched.name, "Test Skill");
        assert_eq!(fetched.status, SkillStatus::Disabled);

        // Test update (enable the skill)
        skill.status = SkillStatus::Enabled;
        store.update(&skill).unwrap();

        let fetched = store.get("skill-001").unwrap();
        assert_eq!(fetched.status, SkillStatus::Enabled);

        // Test delete
        store.delete("skill-001").unwrap();
        assert!(store.get("skill-001").is_err());
    }
}
