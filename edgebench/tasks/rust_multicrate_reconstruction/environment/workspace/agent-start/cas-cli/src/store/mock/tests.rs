use crate::store::mock::fixtures::*;
use crate::store::mock::{MockRuleStore, MockSkillStore, MockStore, MockTaskStore};
use crate::store::{RuleStore, SkillStore, Store, TaskStore};
use cas_store::StoreError;

#[test]
fn test_mock_store_add_and_get() {
    let store = MockStore::new();
    let value = entry("test-001", "Test content");
    store.add(&value).unwrap();

    let retrieved = store.get("test-001").unwrap();
    assert_eq!(retrieved.content, "Test content");
}

#[test]
fn test_mock_store_list() {
    let store = MockStore::with_entries(vec![
        entry("a", "First"),
        entry("b", "Second"),
        entry("c", "Third"),
    ]);

    let list = store.list().unwrap();
    assert_eq!(list.len(), 3);
}

#[test]
fn test_mock_store_archive() {
    let store = MockStore::with_entries(vec![entry("test-001", "Content")]);

    store.archive("test-001").unwrap();
    assert!(store.get("test-001").is_err());

    let archived = store.get_archived("test-001").unwrap();
    assert_eq!(archived.content, "Content");
}

#[test]
fn test_mock_store_error_injection() {
    let store = MockStore::new();
    store.inject_error(StoreError::NotFound("injected".to_string()));

    let result = store.list();
    assert!(result.is_err());
}


#[test]
fn test_mock_store_duplicate() {
    let store = MockStore::new();
    let value = entry("test-001", "Content");
    store.add(&value).unwrap();

    let result = store.add(&value);
    assert!(matches!(result, Err(StoreError::EntryExists(_))));
}

#[test]
fn test_mock_rule_store_crud() {
    let store = MockRuleStore::new();
    let value = rule("rule-001", "Always test your code");

    store.add(&value).unwrap();
    let retrieved = store.get("rule-001").unwrap();
    assert_eq!(retrieved.content, "Always test your code");

    let mut updated = retrieved.clone();
    updated.content = "Updated rule".to_string();
    store.update(&updated).unwrap();

    let after_update = store.get("rule-001").unwrap();
    assert_eq!(after_update.content, "Updated rule");

    store.delete("rule-001").unwrap();
    assert!(store.get("rule-001").is_err());
}

#[test]
fn test_mock_rule_store_list() {
    let store = MockRuleStore::with_rules(vec![rule("r1", "Rule 1"), proven_rule("r2", "Rule 2")]);

    let list = store.list().unwrap();
    assert_eq!(list.len(), 2);
}

#[test]
fn test_mock_task_store_crud() {
    let store = MockTaskStore::new();
    let value = task("cas-0001", "Test task");

    store.add(&value).unwrap();
    let retrieved = store.get("cas-0001").unwrap();
    assert_eq!(retrieved.title, "Test task");
}

#[test]
fn test_mock_task_store_list_ready() {
    let store = MockTaskStore::with_tasks(vec![
        task("t1", "Task 1"),
        task("t2", "Task 2"),
        in_progress_task("t3", "Task 3"),
    ]);

    store.add_dependency(&blocks("t1", "t2")).unwrap();

    let ready = store.list_ready().unwrap();
    assert_eq!(ready.len(), 2);
    assert!(ready.iter().any(|task| task.id == "t2"));
    assert!(ready.iter().any(|task| task.id == "t3"));
}

#[test]
fn test_mock_task_store_dependencies() {
    let store = MockTaskStore::with_tasks(vec![task("t1", "Task 1"), task("t2", "Task 2")]);

    store.add_dependency(&blocks("t1", "t2")).unwrap();

    let deps = store.get_dependencies("t1").unwrap();
    assert_eq!(deps.len(), 1);
    assert_eq!(deps[0].to_id, "t2");

    let blockers = store.get_blockers("t1").unwrap();
    assert_eq!(blockers.len(), 1);
    assert_eq!(blockers[0].id, "t2");
}

#[test]
fn test_mock_task_store_cycle_detection() {
    let store = MockTaskStore::with_tasks(vec![
        task("t1", "Task 1"),
        task("t2", "Task 2"),
        task("t3", "Task 3"),
    ]);

    store.add_dependency(&blocks("t1", "t2")).unwrap();
    store.add_dependency(&blocks("t2", "t3")).unwrap();

    let result = store.add_dependency(&blocks("t3", "t1"));
    assert!(matches!(result, Err(StoreError::CyclicDependency(_, _))));
}

#[test]
fn test_mock_skill_store_crud() {
    let store = MockSkillStore::new();
    let value = skill("cas-sk01", "TestSkill");

    store.add(&value).unwrap();
    let retrieved = store.get("cas-sk01").unwrap();
    assert_eq!(retrieved.name, "TestSkill");
}

#[test]
fn test_mock_skill_store_list_enabled() {
    let store = MockSkillStore::with_skills(vec![
        skill("s1", "Enabled Skill"),
        disabled_skill("s2", "Disabled Skill"),
    ]);

    let enabled = store.list_enabled().unwrap();
    assert_eq!(enabled.len(), 1);
    assert_eq!(enabled[0].name, "Enabled Skill");
}

#[test]
fn test_mock_skill_store_search() {
    let store =
        MockSkillStore::with_skills(vec![skill("s1", "Git Commit"), skill("s2", "PR Review")]);

    let results = store.search("git").unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].name, "Git Commit");
}

#[test]
fn test_fixtures_entry() {
    let value = entry("test", "content");
    assert_eq!(value.id, "test");
    assert_eq!(value.content, "content");
}

#[test]
fn test_fixtures_entry_with_tags() {
    let value = entry_with_tags("test", "content", vec!["tag1", "tag2"]);
    assert_eq!(value.tags.len(), 2);
}

#[test]
fn test_fixtures_task_priority() {
    let value = task_with_priority("t1", "High priority", 0);
    assert_eq!(value.priority.0, 0);
}
