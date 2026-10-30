use crate::*;


// =============================================================================
// SqliteSpecStore Integration Tests
// =============================================================================


#[test]
fn test_sqlite_spec_store_list_approved() {
    let temp = setup_temp_dir();
    let store = SqliteSpecStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create specs with different statuses
    let draft = Spec {
        id: store.generate_id().unwrap(),
        title: "Draft Spec".to_string(),
        status: SpecStatus::Draft,
        ..Default::default()
    };
    let approved = Spec {
        id: store.generate_id().unwrap(),
        title: "Approved Spec".to_string(),
        status: SpecStatus::Approved,
        approved_at: Some(chrono::Utc::now()),
        approved_by: Some("reviewer-001".to_string()),
        ..Default::default()
    };
    let rejected = Spec {
        id: store.generate_id().unwrap(),
        title: "Rejected Spec".to_string(),
        status: SpecStatus::Rejected,
        ..Default::default()
    };

    store.add(&draft).expect("Failed to add draft");
    store.add(&approved).expect("Failed to add approved");
    store.add(&rejected).expect("Failed to add rejected");

    // List approved only
    let approved_list = store.list_approved().expect("Failed to list approved");
    assert_eq!(approved_list.len(), 1);
    assert_eq!(approved_list[0].title, "Approved Spec");
    assert!(approved_list[0].approved_at.is_some());
    assert_eq!(
        approved_list[0].approved_by,
        Some("reviewer-001".to_string())
    );

    // List all
    let all = store.list(None).expect("Failed to list all");
    assert_eq!(all.len(), 3);
}


#[test]
fn test_sqlite_spec_store_version_chain() {
    let temp = setup_temp_dir();
    let store = SqliteSpecStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create version chain: v1 -> v2 -> v3
    let id1 = store.generate_id().unwrap();
    let id2 = store.generate_id().unwrap();
    let id3 = store.generate_id().unwrap();

    let spec_v1 = Spec {
        id: id1.clone(),
        title: "API Design v1".to_string(),
        version: 1,
        previous_version_id: None,
        status: SpecStatus::Superseded,
        ..Default::default()
    };
    let spec_v2 = Spec {
        id: id2.clone(),
        title: "API Design v2".to_string(),
        version: 2,
        previous_version_id: Some(id1.clone()),
        status: SpecStatus::Superseded,
        ..Default::default()
    };
    let spec_v3 = Spec {
        id: id3.clone(),
        title: "API Design v3".to_string(),
        version: 3,
        previous_version_id: Some(id2.clone()),
        status: SpecStatus::Approved,
        ..Default::default()
    };

    store.add(&spec_v1).unwrap();
    store.add(&spec_v2).unwrap();
    store.add(&spec_v3).unwrap();

    // Get versions from any point in chain
    let from_v1 = store
        .get_versions(&id1)
        .expect("Failed to get versions from v1");
    assert_eq!(from_v1.len(), 3);
    assert_eq!(from_v1[0].version, 1);
    assert_eq!(from_v1[1].version, 2);
    assert_eq!(from_v1[2].version, 3);

    let from_v3 = store
        .get_versions(&id3)
        .expect("Failed to get versions from v3");
    assert_eq!(from_v3.len(), 3);
    assert_eq!(from_v3[0].id, id1);
    assert_eq!(from_v3[2].id, id3);

    let from_v2 = store
        .get_versions(&id2)
        .expect("Failed to get versions from v2");
    assert_eq!(from_v2.len(), 3);
}

#[test]
fn test_sqlite_spec_store_search() {
    let temp = setup_temp_dir();
    let store = SqliteSpecStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create specs with varied content
    let spec1 = Spec {
        id: store.generate_id().unwrap(),
        title: "REST API Design".to_string(),
        summary: "Design RESTful endpoints for user management".to_string(),
        tags: vec!["api".to_string(), "backend".to_string()],
        design_notes: "Use JSON:API format".to_string(),
        ..Default::default()
    };
    let spec2 = Spec {
        id: store.generate_id().unwrap(),
        title: "Database Migration Plan".to_string(),
        summary: "Migrate from PostgreSQL to CockroachDB".to_string(),
        tags: vec!["database".to_string(), "migration".to_string()],
        ..Default::default()
    };
    let spec3 = Spec {
        id: store.generate_id().unwrap(),
        title: "Mobile App Architecture".to_string(),
        summary: "Cross-platform mobile app design".to_string(),
        tags: vec!["mobile".to_string(), "frontend".to_string()],
        ..Default::default()
    };

    store.add(&spec1).unwrap();
    store.add(&spec2).unwrap();
    store.add(&spec3).unwrap();

    // Search by title
    let by_title = store.search("REST").expect("Failed to search");
    assert_eq!(by_title.len(), 1);
    assert_eq!(by_title[0].title, "REST API Design");

    // Search by summary
    let by_summary = store.search("PostgreSQL").expect("Failed to search");
    assert_eq!(by_summary.len(), 1);
    assert_eq!(by_summary[0].title, "Database Migration Plan");

    // Search by tag
    let by_tag = store.search("backend").expect("Failed to search");
    assert_eq!(by_tag.len(), 1);

    // Search by design notes
    let by_design = store.search("JSON:API").expect("Failed to search");
    assert_eq!(by_design.len(), 1);

    // Search with no results
    let empty = store.search("nonexistent").expect("Failed to search");
    assert!(empty.is_empty());
}


#[test]
fn test_sqlite_spec_store_full_fields() {
    let temp = setup_temp_dir();
    let store = SqliteSpecStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create a spec with all fields populated
    let full_spec = Spec {
        id: store.generate_id().unwrap(),
        scope: Scope::Global,
        title: "Complete Spec".to_string(),
        summary: "Full summary".to_string(),
        goals: vec!["Goal 1".to_string(), "Goal 2".to_string()],
        in_scope: vec!["Feature A".to_string()],
        out_of_scope: vec!["Feature B".to_string()],
        users: vec!["Developers".to_string(), "Admins".to_string()],
        technical_requirements: vec!["Rust 1.70+".to_string()],
        acceptance_criteria: vec!["All tests pass".to_string()],
        design_notes: "Use builder pattern".to_string(),
        additional_notes: "See related docs".to_string(),
        spec_type: SpecType::Feature,
        status: SpecStatus::Approved,
        version: 2,
        previous_version_id: Some("spec-prev".to_string()),
        task_id: Some("cas-1234".to_string()),
        source_ids: vec!["source-1".to_string(), "source-2".to_string()],
        created_at: chrono::Utc::now(),
        updated_at: chrono::Utc::now(),
        approved_at: Some(chrono::Utc::now()),
        approved_by: Some("admin".to_string()),
        team_id: Some("team-dev".to_string()),
        tags: vec!["important".to_string(), "v2".to_string()],
    };

    store.add(&full_spec).unwrap();

    // Retrieve and verify all fields
    let retrieved = store.get(&full_spec.id).expect("Failed to get spec");
    assert_eq!(retrieved.scope, Scope::Global);
    assert_eq!(retrieved.title, "Complete Spec");
    assert_eq!(retrieved.summary, "Full summary");
    assert_eq!(retrieved.goals, vec!["Goal 1", "Goal 2"]);
    assert_eq!(retrieved.in_scope, vec!["Feature A"]);
    assert_eq!(retrieved.out_of_scope, vec!["Feature B"]);
    assert_eq!(retrieved.users, vec!["Developers", "Admins"]);
    assert_eq!(retrieved.technical_requirements, vec!["Rust 1.70+"]);
    assert_eq!(retrieved.acceptance_criteria, vec!["All tests pass"]);
    assert_eq!(retrieved.design_notes, "Use builder pattern");
    assert_eq!(retrieved.additional_notes, "See related docs");
    assert_eq!(retrieved.spec_type, SpecType::Feature);
    assert_eq!(retrieved.status, SpecStatus::Approved);
    assert_eq!(retrieved.version, 2);
    assert_eq!(retrieved.previous_version_id, Some("spec-prev".to_string()));
    assert_eq!(retrieved.task_id, Some("cas-1234".to_string()));
    assert_eq!(retrieved.source_ids, vec!["source-1", "source-2"]);
    assert!(retrieved.approved_at.is_some());
    assert_eq!(retrieved.approved_by, Some("admin".to_string()));
    assert_eq!(retrieved.team_id, Some("team-dev".to_string()));
    assert_eq!(retrieved.tags, vec!["important", "v2"]);
}
