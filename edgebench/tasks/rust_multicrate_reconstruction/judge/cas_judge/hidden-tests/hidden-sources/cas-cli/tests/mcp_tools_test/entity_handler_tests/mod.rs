#[tokio::test]
async fn test_entity_list_query_filter() {
    let (temp, _core, service) = setup_cas_with_entities();
    let cas_dir = temp.path().join(".cas");
    let entity_store = open_entity_store(&cas_dir).unwrap();

    // Create test entities (Tool is the technology type)
    create_test_entity(
        &*entity_store,
        "Python",
        EntityType::Tool,
        Some("A programming language"),
    );
    create_test_entity(
        &*entity_store,
        "JavaScript",
        EntityType::Tool,
        Some("Web scripting language"),
    );
    create_test_entity(&*entity_store, "John Smith", EntityType::Person, None);

    // Test query filter by name
    let req = EntityListRequest {
        entity_type: None,
        query: Some("Python".to_string()),
        tags: None,
        scope: None,
        sort: None,
        sort_order: None,
        limit: None,
    };
    let result = service
        .inner
        .cas_entity_list(Parameters(req))
        .await
        .unwrap();
    let text = extract_text(result);
    assert!(text.contains("Python"), "Should find Python");
    assert!(!text.contains("JavaScript"), "Should NOT find JavaScript");

    // Test query filter by description
    let req = EntityListRequest {
        entity_type: None,
        query: Some("scripting".to_string()),
        tags: None,
        scope: None,
        sort: None,
        sort_order: None,
        limit: None,
    };
    let result = service
        .inner
        .cas_entity_list(Parameters(req))
        .await
        .unwrap();
    let text = extract_text(result);
    assert!(
        text.contains("JavaScript"),
        "Should find JavaScript via description"
    );
    assert!(!text.contains("Python"), "Should NOT find Python");
}

#[tokio::test]
async fn test_entity_list_sort_by_mentions() {
    let (temp, _core, service) = setup_cas_with_entities();
    let cas_dir = temp.path().join(".cas");
    let entity_store = open_entity_store(&cas_dir).unwrap();

    // Create entities with different mention counts
    let id1 = entity_store.generate_entity_id().unwrap();
    let entity1 = Entity {
        id: id1.clone(),
        name: "LowMentions".to_string(),
        entity_type: EntityType::Tool,
        aliases: vec![],
        description: None,
        created: Utc::now(),
        updated: Utc::now(),
        mention_count: 1,
        confidence: 0.9,
        archived: false,
        metadata: HashMap::new(),
        summary: None,
        summary_updated: None,
    };
    entity_store.add_entity(&entity1).unwrap();

    let id2 = entity_store.generate_entity_id().unwrap();
    let entity2 = Entity {
        id: id2.clone(),
        name: "HighMentions".to_string(),
        entity_type: EntityType::Tool,
        aliases: vec![],
        description: None,
        created: Utc::now(),
        updated: Utc::now(),
        mention_count: 100,
        confidence: 0.9,
        archived: false,
        metadata: HashMap::new(),
        summary: None,
        summary_updated: None,
    };
    entity_store.add_entity(&entity2).unwrap();

    // Test sort by mentions descending
    let req = EntityListRequest {
        entity_type: None,
        query: None,
        tags: None,
        scope: None,
        sort: Some("mentions".to_string()),
        sort_order: Some("desc".to_string()),
        limit: None,
    };
    let result = service
        .inner
        .cas_entity_list(Parameters(req))
        .await
        .unwrap();
    let text = extract_text(result);

    let high_pos = text
        .find("HighMentions")
        .expect("HighMentions should exist");
    let low_pos = text.find("LowMentions").expect("LowMentions should exist");
    assert!(
        high_pos < low_pos,
        "HighMentions should come before LowMentions (desc)"
    );
}

#[tokio::test]
async fn test_entity_extract_query_filter() {
    let (temp, _core, service) = setup_cas_with_entities();
    let cas_dir = temp.path().join(".cas");
    let store = open_store(&cas_dir).unwrap();

    // Create entries with different content
    use cas::types::Entry;
    let id1 = gen_entry_id(&*store);
    let entry1 = Entry::new(id1, "TypeScript is great for web development".to_string());
    store.add(&entry1).unwrap();

    let id2 = gen_entry_id(&*store);
    let entry2 = Entry::new(id2, "Python is excellent for data science".to_string());
    store.add(&entry2).unwrap();

    // Extract entities from entries containing "TypeScript"
    let req = EntityExtractRequest {
        query: Some("TypeScript".to_string()),
        scope: None,
        tags: None,
        entity_type: None,
        limit: None,
    };
    let result = service
        .inner
        .cas_entity_extract(Parameters(req))
        .await
        .unwrap();
    let text = extract_text(result);
    assert!(
        text.contains("Entity extraction complete"),
        "Should complete extraction"
    );
}

#[tokio::test]
async fn test_entity_extract_scope_filter() {
    let (temp, _core, service) = setup_cas_with_entities();
    let cas_dir = temp.path().join(".cas");
    let store = open_store(&cas_dir).unwrap();

    // Create a global entry
    use cas::types::Entry;
    let id1 = gen_entry_id(&*store);
    let mut entry1 = Entry::new(id1, "Global entry mentioning Rust".to_string());
    entry1.scope = Scope::Global;
    store.add(&entry1).unwrap();

    // Create a project entry
    let id2 = gen_entry_id(&*store);
    let mut entry2 = Entry::new(id2, "Project entry mentioning Go".to_string());
    entry2.scope = Scope::Project;
    store.add(&entry2).unwrap();

    // Extract from global scope only
    let req = EntityExtractRequest {
        query: None,
        scope: Some("global".to_string()),
        tags: None,
        entity_type: None,
        limit: None,
    };
    let result = service
        .inner
        .cas_entity_extract(Parameters(req))
        .await
        .unwrap();
    let text = extract_text(result);
    assert!(
        text.contains("Entity extraction complete"),
        "Should complete extraction"
    );
}
