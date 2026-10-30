#[test]
fn test_layered_store_with_sqlite() {
    use cas_store::layered::LayeredEntryStore;

    let global_temp = setup_temp_dir();
    let project_temp = setup_temp_dir();

    let global_store = Arc::new(SqliteStore::open(global_temp.path()).unwrap());
    let project_store = Arc::new(SqliteStore::open(project_temp.path()).unwrap());

    global_store.init().unwrap();
    project_store.init().unwrap();

    let layered = LayeredEntryStore::new(global_store, Some(project_store));

    // Add global entry
    let mut g_entry = Entry::new("g-001".to_string(), "Global entry".to_string());
    g_entry.scope = Scope::Global;
    layered.add(&g_entry).unwrap();

    // Add project entry
    let mut p_entry = Entry::new("p-001".to_string(), "Project entry".to_string());
    p_entry.scope = Scope::Project;
    layered.add(&p_entry).unwrap();

    // List all
    let all = layered.list(ScopeFilter::All).unwrap();
    assert_eq!(all.len(), 2);

    // List global only (note: scope field isn't persisted by SqliteStore,
    // but layered store correctly routes to the right underlying store)
    let global_only = layered.list(ScopeFilter::Global).unwrap();
    assert_eq!(global_only.len(), 1);
    assert_eq!(global_only[0].id, "g-001");

    // List project only
    let project_only = layered.list(ScopeFilter::Project).unwrap();
    assert_eq!(project_only.len(), 1);
    assert_eq!(project_only[0].id, "p-001");

    // Get by ID works across both
    assert!(layered.get("g-001").is_ok());
    assert!(layered.get("p-001").is_ok());
}

#[test]
fn test_sqlite_spec_store_full_lifecycle() {
    let temp = setup_temp_dir();
    let store = SqliteSpecStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Generate ID
    let id = store.generate_id().expect("Failed to generate ID");
    assert!(id.starts_with("spec-"));
    assert!(id.len() >= 9); // spec- + at least 4 chars

    // Create and add spec
    let mut spec = Spec::new(id.clone(), "User Authentication System".to_string());
    spec.summary = "Implement OAuth 2.0 login flow".to_string();
    spec.spec_type = SpecType::Feature;
    spec.goals = vec!["Secure login".to_string(), "Token management".to_string()];
    spec.acceptance_criteria = vec![
        "Users can log in".to_string(),
        "Tokens expire correctly".to_string(),
    ];
    spec.tags = vec!["auth".to_string(), "security".to_string()];
    store.add(&spec).expect("Failed to add spec");

    // Get spec
    let retrieved = store.get(&id).expect("Failed to get spec");
    assert_eq!(retrieved.title, "User Authentication System");
    assert_eq!(retrieved.summary, "Implement OAuth 2.0 login flow");
    assert_eq!(retrieved.spec_type, SpecType::Feature);
    assert_eq!(retrieved.goals.len(), 2);
    assert_eq!(retrieved.acceptance_criteria.len(), 2);
    assert_eq!(retrieved.tags.len(), 2);
    assert_eq!(retrieved.status, SpecStatus::Draft);

    // Update spec
    let mut updated = retrieved.clone();
    updated.status = SpecStatus::UnderReview;
    updated.summary = "Updated summary".to_string();
    store.update(&updated).expect("Failed to update spec");

    let after_update = store.get(&id).expect("Failed to get after update");
    assert_eq!(after_update.status, SpecStatus::UnderReview);
    assert_eq!(after_update.summary, "Updated summary");

    // List specs
    let all_specs = store.list(None).expect("Failed to list specs");
    assert_eq!(all_specs.len(), 1);

    let under_review = store
        .list(Some(SpecStatus::UnderReview))
        .expect("Failed to list by status");
    assert_eq!(under_review.len(), 1);

    // Delete spec
    store.delete(&id).expect("Failed to delete spec");
    assert!(store.get(&id).is_err());

    store.close().expect("Failed to close store");
}

#[test]
fn test_sqlite_spec_store_get_for_task() {
    let temp = setup_temp_dir();
    let store = SqliteSpecStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create specs associated with tasks
    let spec1 = Spec {
        id: store.generate_id().unwrap(),
        title: "Epic Spec 1".to_string(),
        task_id: Some("cas-1234".to_string()),
        ..Default::default()
    };
    let spec2 = Spec {
        id: store.generate_id().unwrap(),
        title: "Epic Spec 2".to_string(),
        task_id: Some("cas-1234".to_string()),
        ..Default::default()
    };
    let spec3 = Spec {
        id: store.generate_id().unwrap(),
        title: "Unrelated Spec".to_string(),
        task_id: Some("cas-5678".to_string()),
        ..Default::default()
    };

    store.add(&spec1).unwrap();
    store.add(&spec2).unwrap();
    store.add(&spec3).unwrap();

    // Get specs for task cas-1234
    let task_specs = store
        .get_for_task("cas-1234")
        .expect("Failed to get for task");
    assert_eq!(task_specs.len(), 2);
    assert!(
        task_specs
            .iter()
            .all(|s| s.task_id == Some("cas-1234".to_string()))
    );

    // Get specs for task cas-5678
    let other_specs = store
        .get_for_task("cas-5678")
        .expect("Failed to get for task");
    assert_eq!(other_specs.len(), 1);
    assert_eq!(other_specs[0].title, "Unrelated Spec");

    // Non-existent task
    let empty = store
        .get_for_task("cas-9999")
        .expect("Failed to get for task");
    assert!(empty.is_empty());
}

#[test]
fn test_sqlite_spec_store_spec_types() {
    let temp = setup_temp_dir();
    let store = SqliteSpecStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create specs with different types
    for spec_type in [
        SpecType::Epic,
        SpecType::Feature,
        SpecType::Api,
        SpecType::Component,
        SpecType::Migration,
    ]
    .iter()
    {
        let spec = Spec {
            id: store.generate_id().unwrap(),
            title: format!("{spec_type:?} Spec"),
            spec_type: *spec_type,
            ..Default::default()
        };
        store.add(&spec).unwrap();
    }

    // Verify all were created
    let all = store.list(None).expect("Failed to list");
    assert_eq!(all.len(), 5);

    // Verify types are preserved
    let types: Vec<_> = all.iter().map(|s| s.spec_type).collect();
    assert!(types.contains(&SpecType::Epic));
    assert!(types.contains(&SpecType::Feature));
    assert!(types.contains(&SpecType::Api));
    assert!(types.contains(&SpecType::Component));
    assert!(types.contains(&SpecType::Migration));
}
