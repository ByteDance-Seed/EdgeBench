use crate::search::*;
use cas_types::{Entry, Task};

fn create_test_entry(id: &str, content: &str) -> Entry { todo!() }



#[test]
fn test_extract_id_patterns() {
    // Single ID
    let (ids, remaining) = extract_id_patterns("cas-8cb5");
    assert_eq!(ids, vec!["cas-8cb5"]);
    assert_eq!(remaining, "");

    // Multiple IDs
    let (ids, remaining) = extract_id_patterns("cas-8cb5 cas-4a23 cas-c6a3");
    assert_eq!(ids.len(), 3);
    assert!(ids.contains(&"cas-8cb5".to_string()));
    assert!(ids.contains(&"cas-4a23".to_string()));
    assert!(ids.contains(&"cas-c6a3".to_string()));
    assert_eq!(remaining, "");

    // Mixed query with IDs and text
    let (ids, remaining) = extract_id_patterns("find cas-1234 and cas-5678 about rust");
    assert_eq!(ids.len(), 2);
    assert!(ids.contains(&"cas-1234".to_string()));
    assert!(ids.contains(&"cas-5678".to_string()));
    assert_eq!(remaining, "find and about rust");

    // Rule IDs
    let (ids, _remaining) = extract_id_patterns("rule-041 rule-003");
    assert_eq!(ids.len(), 2);
    assert!(ids.contains(&"rule-041".to_string()));
    assert!(ids.contains(&"rule-003".to_string()));

    // No IDs
    let (ids, remaining) = extract_id_patterns("search for rust programming");
    assert!(ids.is_empty());
    assert_eq!(remaining, "search for rust programming");

    // Case insensitive
    let (ids, _) = extract_id_patterns("CAS-ABCD cas-1234");
    assert_eq!(ids.len(), 2);
    assert!(ids.contains(&"cas-abcd".to_string()));
    assert!(ids.contains(&"cas-1234".to_string()));
}

#[test]
fn test_unified_search_with_id_patterns() {
    let index = SearchIndex::in_memory().unwrap();

    // Create test tasks
    let task1 = Task {
        id: "cas-1234".to_string(),
        title: "Test task one".to_string(),
        description: "First task description".to_string(),
        ..Default::default()
    };
    let task2 = Task {
        id: "cas-5678".to_string(),
        title: "Test task two".to_string(),
        description: "Second task description".to_string(),
        ..Default::default()
    };

    index.index_task(&task1).unwrap();
    index.index_task(&task2).unwrap();

    // Search by single ID
    let opts = SearchOptions {
        query: "cas-1234".to_string(),
        limit: 10,
        ..Default::default()
    };
    let results = index.search_unified(&opts).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].id, "cas-1234");
    assert_eq!(results[0].score, 1.0); // Exact ID match

    // Search by multiple IDs
    let opts = SearchOptions {
        query: "cas-1234 cas-5678".to_string(),
        limit: 10,
        ..Default::default()
    };
    let results = index.search_unified(&opts).unwrap();
    assert_eq!(results.len(), 2);

    // Search by ID with doc_type filter
    let opts = SearchOptions {
        query: "cas-1234".to_string(),
        limit: 10,
        doc_types: vec![DocType::Task],
        ..Default::default()
    };
    let results = index.search_unified(&opts).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].doc_type, DocType::Task);
}
