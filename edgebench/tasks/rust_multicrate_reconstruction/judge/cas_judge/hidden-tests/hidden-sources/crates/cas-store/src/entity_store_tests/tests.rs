#[test]
fn test_entity_crud() {
    let (_temp, store) = create_test_store();

    // Create entity
    let id = store.generate_entity_id().unwrap();
    let mut entity = Entity::new(id.clone(), "Alice".to_string(), EntityType::Person);
    entity.add_alias("alice@example.com".to_string());
    store.add_entity(&entity).unwrap();

    // Get entity
    let retrieved = store.get_entity(&id).unwrap();
    assert_eq!(retrieved.name, "Alice");
    assert_eq!(retrieved.entity_type, EntityType::Person);
    assert_eq!(retrieved.aliases, vec!["alice@example.com"]);

    // Update entity
    let mut updated = retrieved;
    updated.description = Some("Software developer".to_string());
    updated.mention_count = 5;
    store.update_entity(&updated).unwrap();

    let retrieved = store.get_entity(&id).unwrap();
    assert_eq!(
        retrieved.description,
        Some("Software developer".to_string())
    );
    assert_eq!(retrieved.mention_count, 5);

    // List entities
    let entities = store.list_entities(Some(EntityType::Person)).unwrap();
    assert_eq!(entities.len(), 1);

    // Delete entity
    store.delete_entity(&id).unwrap();
    assert!(store.get_entity(&id).is_err());
}

#[test]
fn test_entity_by_name() {
    let (_temp, store) = create_test_store();

    let mut entity = Entity::new(
        "ent-001".to_string(),
        "CAS".to_string(),
        EntityType::Project,
    );
    entity.add_alias("Coding Agent System".to_string());
    store.add_entity(&entity).unwrap();

    // Find by exact name
    let found = store.get_entity_by_name("CAS", None).unwrap();
    assert!(found.is_some());
    assert_eq!(found.unwrap().name, "CAS");

    // Find by alias
    let found = store
        .get_entity_by_name("Coding Agent System", None)
        .unwrap();
    assert!(found.is_some());

    // Case insensitive
    let found = store.get_entity_by_name("cas", None).unwrap();
    assert!(found.is_some());

    // Not found
    let found = store.get_entity_by_name("unknown", None).unwrap();
    assert!(found.is_none());
}
