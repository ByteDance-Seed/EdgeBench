use crate::support::*;
use cas::mcp::CasCore;
use cas::mcp::tools::*;
use cas::store::{open_entity_store, open_store};
use cas::types::{Entity, EntityType, Scope};
use chrono::Utc;
use rmcp::handler::server::wrapper::Parameters;
use std::collections::HashMap;
use tempfile::TempDir;

/// Helper to setup CAS with entity store initialized
fn setup_cas_with_entities() -> (TempDir, CasCore, CasService) { todo!() }

/// Helper to create a test entity
fn create_test_entity(
    entity_store: &dyn cas_store::EntityStore,
    name: &str,
    entity_type: EntityType,
    description: Option<&str>,
) -> String { todo!() }

/// Helper to generate entry ID
fn gen_entry_id(store: &dyn cas_store::Store) -> String { todo!() }


#[tokio::test]
async fn test_entity_list_sort_by_name() {
    let (temp, _core, service) = setup_cas_with_entities();
    let cas_dir = temp.path().join(".cas");
    let entity_store = open_entity_store(&cas_dir).unwrap();

    // Create entities with different names
    create_test_entity(&*entity_store, "Zebra", EntityType::Concept, None);
    create_test_entity(&*entity_store, "Alpha", EntityType::Concept, None);
    create_test_entity(&*entity_store, "Middle", EntityType::Concept, None);

    // Test sort by name ascending
    let req = EntityListRequest {
        entity_type: None,
        query: None,
        tags: None,
        scope: None,
        sort: Some("name".to_string()),
        sort_order: Some("asc".to_string()),
        limit: None,
    };
    let result = service
        .inner
        .cas_entity_list(Parameters(req))
        .await
        .unwrap();
    let text = extract_text(result);

    // Verify order: Alpha should appear before Middle, Middle before Zebra
    let alpha_pos = text.find("Alpha").expect("Alpha should exist");
    let middle_pos = text.find("Middle").expect("Middle should exist");
    let zebra_pos = text.find("Zebra").expect("Zebra should exist");
    assert!(
        alpha_pos < middle_pos,
        "Alpha should come before Middle (asc)"
    );
    assert!(
        middle_pos < zebra_pos,
        "Middle should come before Zebra (asc)"
    );

    // Test sort by name descending
    let req = EntityListRequest {
        entity_type: None,
        query: None,
        tags: None,
        scope: None,
        sort: Some("name".to_string()),
        sort_order: Some("desc".to_string()),
        limit: None,
    };
    let result = service
        .inner
        .cas_entity_list(Parameters(req))
        .await
        .unwrap();
    let text = extract_text(result);

    let alpha_pos = text.find("Alpha").expect("Alpha should exist");
    let zebra_pos = text.find("Zebra").expect("Zebra should exist");
    assert!(
        zebra_pos < alpha_pos,
        "Zebra should come before Alpha (desc)"
    );
}




#[tokio::test]
async fn test_entity_extract_tags_filter() {
    let (temp, _core, service) = setup_cas_with_entities();
    let cas_dir = temp.path().join(".cas");
    let store = open_store(&cas_dir).unwrap();

    // Create entry with tags
    use cas::types::Entry;
    let id1 = gen_entry_id(&*store);
    let mut entry1 = Entry::new(id1, "Entry about Java programming".to_string());
    entry1.tags = vec!["programming".to_string(), "backend".to_string()];
    store.add(&entry1).unwrap();

    // Create entry without tags
    let id2 = gen_entry_id(&*store);
    let entry2 = Entry::new(id2, "Entry about C++ programming".to_string());
    store.add(&entry2).unwrap();

    // Extract from entries with "programming" tag
    let req = EntityExtractRequest {
        query: None,
        scope: None,
        tags: Some("programming".to_string()),
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
async fn test_entity_extract_entity_type_filter() {
    let (temp, _core, service) = setup_cas_with_entities();
    let cas_dir = temp.path().join(".cas");
    let store = open_store(&cas_dir).unwrap();

    // Create entry mentioning both a person and technology
    use cas::types::Entry;
    let id = gen_entry_id(&*store);
    let entry = Entry::new(id, "Alice uses Kubernetes for deployment".to_string());
    store.add(&entry).unwrap();

    // Extract only Tool (technology) entities
    let req = EntityExtractRequest {
        query: None,
        scope: None,
        tags: None,
        entity_type: Some("tool".to_string()),
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
async fn test_entity_list_combined_filters() {
    let (temp, _core, service) = setup_cas_with_entities();
    let cas_dir = temp.path().join(".cas");
    let entity_store = open_entity_store(&cas_dir).unwrap();

    // Create multiple entities (Tool is the technology type)
    create_test_entity(
        &*entity_store,
        "React Framework",
        EntityType::Tool,
        Some("Frontend library"),
    );
    create_test_entity(
        &*entity_store,
        "Vue Framework",
        EntityType::Tool,
        Some("Frontend framework"),
    );
    create_test_entity(
        &*entity_store,
        "Django Framework",
        EntityType::Tool,
        Some("Backend framework"),
    );

    // Filter by type AND query
    let req = EntityListRequest {
        entity_type: Some("tool".to_string()),
        query: Some("Frontend".to_string()),
        tags: None,
        scope: None,
        sort: Some("name".to_string()),
        sort_order: Some("asc".to_string()),
        limit: Some(10),
    };
    let result = service
        .inner
        .cas_entity_list(Parameters(req))
        .await
        .unwrap();
    let text = extract_text(result);

    assert!(text.contains("React"), "Should find React (frontend)");
    assert!(text.contains("Vue"), "Should find Vue (frontend)");
    assert!(!text.contains("Django"), "Should NOT find Django (backend)");

    // Verify sort order
    let react_pos = text.find("React").expect("React should exist");
    let vue_pos = text.find("Vue").expect("Vue should exist");
    assert!(
        react_pos < vue_pos,
        "React should come before Vue (alphabetically)"
    );
}
