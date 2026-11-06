use crate::*;


#[test]
fn test_sqlite_store_helpful_entries() {
    let temp = setup_temp_dir();
    let store = SqliteStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Add entries with different helpful counts
    for i in 0..5 {
        let mut entry = Entry::new(format!("entry-{i}"), format!("Content {i}"));
        entry.helpful_count = i;
        entry.harmful_count = 0;
        store.add(&entry).expect("Failed to add entry");
    }

    let helpful = store.list_helpful(3).expect("Failed to list helpful");
    assert_eq!(helpful.len(), 3);
    // Should be sorted by helpful_count descending (excluding 0)
    assert!(helpful[0].helpful_count >= helpful[1].helpful_count);
}


// =============================================================================
// SqliteRuleStore Integration Tests
// =============================================================================

#[test]
fn test_sqlite_rule_store_full_lifecycle() {
    let temp = setup_temp_dir();
    let store = SqliteRuleStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Generate ID
    let id = store.generate_id().expect("Failed to generate ID");
    assert!(id.starts_with("rule-"));

    // Create and add rule
    let mut rule = Rule::new(id.clone(), "Always write tests".to_string());
    rule.scope = Scope::Project;
    rule.tags = vec!["testing".to_string()];
    store.add(&rule).expect("Failed to add rule");

    // Get rule
    let retrieved = store.get(&id).expect("Failed to get rule");
    assert_eq!(retrieved.content, "Always write tests");
    assert_eq!(retrieved.scope, Scope::Project);

    // Update rule
    let mut updated = retrieved.clone();
    updated.status = RuleStatus::Proven;
    updated.helpful_count = 3;
    store.update(&updated).expect("Failed to update rule");

    let after_update = store.get(&id).expect("Failed to get after update");
    assert_eq!(after_update.status, RuleStatus::Proven);
    assert_eq!(after_update.helpful_count, 3);

    // List rules
    let list = store.list().expect("Failed to list rules");
    assert_eq!(list.len(), 1);

    // Delete
    store.delete(&id).expect("Failed to delete rule");
    assert!(store.get(&id).is_err());

    store.close().expect("Failed to close store");
}

// =============================================================================
// SqliteTaskStore Integration Tests
// =============================================================================



#[test]
fn test_sqlite_task_store_cycle_detection() {
    let temp = setup_temp_dir();
    let store = SqliteTaskStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create tasks
    let t1 = Task::new("t1".to_string(), "Task 1".to_string());
    let t2 = Task::new("t2".to_string(), "Task 2".to_string());
    let t3 = Task::new("t3".to_string(), "Task 3".to_string());

    store.add(&t1).unwrap();
    store.add(&t2).unwrap();
    store.add(&t3).unwrap();

    // Create chain: t1 -> t2 -> t3
    store
        .add_dependency(&Dependency::new(
            "t1".to_string(),
            "t2".to_string(),
            DependencyType::Blocks,
        ))
        .unwrap();
    store
        .add_dependency(&Dependency::new(
            "t2".to_string(),
            "t3".to_string(),
            DependencyType::Blocks,
        ))
        .unwrap();

    // Would create cycle check
    // t1→t2→t3 exists, so:
    // - t3→t1 would create t1→t2→t3→t1 cycle
    // - t3→t2 would create t2→t3→t2 cycle
    // - A new task t4 blocked by t3 would NOT create a cycle
    assert!(store.would_create_cycle("t3", "t1").unwrap());
    assert!(store.would_create_cycle("t3", "t2").unwrap()); // t2→t3 exists, adding t3→t2 = cycle

    // Adding t3 -> t1 should fail
    let result = store.add_dependency(&Dependency::new(
        "t3".to_string(),
        "t1".to_string(),
        DependencyType::Blocks,
    ));
    assert!(result.is_err());
}
