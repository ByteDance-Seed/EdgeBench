use crate::entity_store::*;
use tempfile::TempDir;

fn create_test_store() -> (TempDir, SqliteEntityStore) { todo!() }



#[test]
fn test_relationship_crud() {
    let (_temp, store) = create_test_store();

    // Create entities first
    let alice = Entity::new(
        "ent-001".to_string(),
        "Alice".to_string(),
        EntityType::Person,
    );
    let project = Entity::new(
        "ent-002".to_string(),
        "CAS".to_string(),
        EntityType::Project,
    );
    store.add_entity(&alice).unwrap();
    store.add_entity(&project).unwrap();

    // Create relationship
    let rel_id = store.generate_relationship_id().unwrap();
    let rel = Relationship::new(
        rel_id.clone(),
        "ent-001".to_string(),
        "ent-002".to_string(),
        RelationType::WorksOn,
    );
    store.add_relationship(&rel).unwrap();

    // Get relationship
    let retrieved = store.get_relationship(&rel_id).unwrap();
    assert_eq!(retrieved.relation_type, RelationType::WorksOn);

    // Get by entities
    let found = store
        .get_relationship_between("ent-001", "ent-002", Some(RelationType::WorksOn))
        .unwrap();
    assert!(found.is_some());

    // Update
    let mut updated = retrieved;
    updated.weight = 0.9;
    updated.observation_count = 3;
    store.update_relationship(&updated).unwrap();

    let retrieved = store.get_relationship(&rel_id).unwrap();
    assert!((retrieved.weight - 0.9).abs() < 0.01);

    // Get entity relationships
    let rels = store.get_entity_relationships("ent-001").unwrap();
    assert_eq!(rels.len(), 1);

    // Delete
    store.delete_relationship(&rel_id).unwrap();
    assert!(store.get_relationship(&rel_id).is_err());
}

#[test]
fn test_entity_mentions() {
    let (_temp, store) = create_test_store();

    // Create entity
    let entity = Entity::new("ent-001".to_string(), "Rust".to_string(), EntityType::Tool);
    store.add_entity(&entity).unwrap();

    // Add mentions
    let mention1 = EntityMention::new("ent-001".to_string(), "entry-001".to_string());
    let mention2 = EntityMention::new("ent-001".to_string(), "entry-002".to_string());
    store.add_mention(&mention1).unwrap();
    store.add_mention(&mention2).unwrap();

    // Get entity mentions
    let mentions = store.get_entity_mentions("ent-001").unwrap();
    assert_eq!(mentions.len(), 2);

    // Get entry mentions
    let mentions = store.get_entry_mentions("entry-001").unwrap();
    assert_eq!(mentions.len(), 1);

    // Get entity entries
    let entries = store.get_entity_entries("ent-001", 10).unwrap();
    assert_eq!(entries.len(), 2);

    // Delete entry mentions
    store.delete_entry_mentions("entry-001").unwrap();
    let mentions = store.get_entity_mentions("ent-001").unwrap();
    assert_eq!(mentions.len(), 1);
}

#[test]
fn test_connected_entities() {
    let (_temp, store) = create_test_store();

    // Create entities
    let alice = Entity::new(
        "ent-001".to_string(),
        "Alice".to_string(),
        EntityType::Person,
    );
    let bob = Entity::new("ent-002".to_string(), "Bob".to_string(), EntityType::Person);
    let project = Entity::new(
        "ent-003".to_string(),
        "CAS".to_string(),
        EntityType::Project,
    );
    store.add_entity(&alice).unwrap();
    store.add_entity(&bob).unwrap();
    store.add_entity(&project).unwrap();

    // Create relationships
    let rel1 = Relationship::new(
        "rel-001".to_string(),
        "ent-001".to_string(),
        "ent-003".to_string(),
        RelationType::WorksOn,
    );
    let rel2 = Relationship::new(
        "rel-002".to_string(),
        "ent-001".to_string(),
        "ent-002".to_string(),
        RelationType::Knows,
    );
    store.add_relationship(&rel1).unwrap();
    store.add_relationship(&rel2).unwrap();

    // Get connected entities
    let connected = store.get_connected_entities("ent-001").unwrap();
    assert_eq!(connected.len(), 2);

    // Check the connections
    let names: Vec<&str> = connected.iter().map(|(e, _)| e.name.as_str()).collect();
    assert!(names.contains(&"Bob"));
    assert!(names.contains(&"CAS"));
}

#[test]
fn test_search_entities_matches_description() {
    let (_temp, store) = create_test_store();

    let mut entity = Entity::new(
        "ent-100".to_string(),
        "JavaScript".to_string(),
        EntityType::Tool,
    );
    entity.description = Some("Web scripting language".to_string());
    store.add_entity(&entity).unwrap();

    let results = store
        .search_entities("scripting", Some(EntityType::Tool))
        .unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].name, "JavaScript");
}
