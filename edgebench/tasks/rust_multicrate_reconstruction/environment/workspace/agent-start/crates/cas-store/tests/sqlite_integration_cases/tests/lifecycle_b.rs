use crate::*;


// =============================================================================
// SqliteEntityStore Integration Tests
// =============================================================================

#[test]
fn test_sqlite_entity_store_full_lifecycle() {
    let temp = setup_temp_dir();
    let store = SqliteEntityStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create and add entity
    let id = store.generate_entity_id().expect("Failed to generate ID");
    let mut entity = Entity::new(id.clone(), "Rust".to_string(), EntityType::Tool);
    entity.description = Some("Systems programming language".to_string());
    entity.aliases = vec!["rust-lang".to_string()];
    store.add_entity(&entity).expect("Failed to add entity");

    // Get entity
    let retrieved = store.get_entity(&id).expect("Failed to get entity");
    assert_eq!(retrieved.name, "Rust");
    assert_eq!(retrieved.entity_type, EntityType::Tool);

    // Get by name
    let by_name = store
        .get_entity_by_name("Rust", None)
        .expect("Failed to get by name");
    assert!(by_name.is_some());
    assert_eq!(by_name.unwrap().id, id);

    // Get by alias
    let by_alias = store
        .get_entity_by_name("rust-lang", None)
        .expect("Failed to get by alias");
    assert!(by_alias.is_some());

    // Update entity
    let mut updated = retrieved.clone();
    updated.description = Some("Updated description".to_string());
    store
        .update_entity(&updated)
        .expect("Failed to update entity");

    // List entities
    let all = store.list_entities(None).expect("Failed to list entities");
    assert_eq!(all.len(), 1);

    let tech_only = store
        .list_entities(Some(EntityType::Tool))
        .expect("Failed to list tech");
    assert_eq!(tech_only.len(), 1);

    // Search entities
    let search = store
        .search_entities("rust", None)
        .expect("Failed to search");
    assert_eq!(search.len(), 1);

    // Delete entity
    store.delete_entity(&id).expect("Failed to delete entity");
    assert!(store.get_entity(&id).is_err());

    store.close().expect("Failed to close store");
}


// =============================================================================
// Incremental Indexing Integration Tests
// =============================================================================

#[test]
fn test_sqlite_store_pending_index_tracking() {
    let temp = setup_temp_dir();
    let store = SqliteStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Initially no pending entries
    let pending = store
        .list_pending_index(100)
        .expect("Failed to list pending");
    assert_eq!(pending.len(), 0, "Should start with no pending entries");

    // Add entries - they should be pending immediately
    let entry1 = Entry::new(
        "idx-001".to_string(),
        "First entry for indexing".to_string(),
    );
    let entry2 = Entry::new(
        "idx-002".to_string(),
        "Second entry for indexing".to_string(),
    );
    store.add(&entry1).expect("Failed to add entry1");
    store.add(&entry2).expect("Failed to add entry2");

    // Verify entries are pending (updated_at set, indexed_at NULL)
    let pending = store
        .list_pending_index(100)
        .expect("Failed to list pending");
    assert_eq!(pending.len(), 2, "Both entries should be pending");

    // Mark first entry as indexed
    store
        .mark_indexed("idx-001")
        .expect("Failed to mark indexed");

    // Now only second entry should be pending
    let pending = store
        .list_pending_index(100)
        .expect("Failed to list pending");
    assert_eq!(pending.len(), 1, "Only one entry should be pending");
    assert_eq!(pending[0].id, "idx-002");

    // Mark second entry as indexed
    store
        .mark_indexed("idx-002")
        .expect("Failed to mark indexed");

    // No entries pending
    let pending = store
        .list_pending_index(100)
        .expect("Failed to list pending");
    assert_eq!(pending.len(), 0, "No entries should be pending");

    store.close().expect("Failed to close store");
}


