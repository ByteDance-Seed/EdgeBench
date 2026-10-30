use crate::Store;
use crate::sqlite::SqliteStore;
use cas_types::Entry;
use tempfile::TempDir;

#[test]
fn test_sqlite_store_crud() {
    let temp = TempDir::new().unwrap();
    let store = SqliteStore::open(temp.path()).unwrap();
    store.init().unwrap();

    // Generate ID and add entry
    let id = store.generate_id().unwrap();
    let entry = Entry {
        id: id.clone(),
        content: "Test content".to_string(),
        ..Default::default()
    };
    store.add(&entry).unwrap();

    // Get entry
    let retrieved = store.get(&id).unwrap();
    assert_eq!(retrieved.content, "Test content");

    // Update entry
    let mut updated = retrieved;
    updated.content = "Updated content".to_string();
    updated.helpful_count = 5;
    store.update(&updated).unwrap();

    let retrieved = store.get(&id).unwrap();
    assert_eq!(retrieved.content, "Updated content");
    assert_eq!(retrieved.helpful_count, 5);

    // List entries
    let entries = store.list().unwrap();
    assert_eq!(entries.len(), 1);

    // Archive entry
    store.archive(&id).unwrap();
    assert!(store.get(&id).is_err());

    let archived = store.list_archived().unwrap();
    assert_eq!(archived.len(), 1);

    // Unarchive entry
    store.unarchive(&id).unwrap();
    assert!(store.get(&id).is_ok());

    // Delete entry
    store.delete(&id).unwrap();
    assert!(store.get(&id).is_err());
}

/// Helper to add session signal columns for testing
/// These columns are normally added by migrations m042-m044
fn add_session_signal_columns(store: &SqliteStore) { todo!() }

#[test]
fn test_signals_outcome_summary() {
    let temp = TempDir::new().unwrap();
    let store = SqliteStore::open(temp.path()).unwrap();
    store.init().unwrap();
    add_session_signal_columns(&store);

    // Create sessions with different outcomes
    let session1 = cas_types::Session::new(
        "session-1".to_string(),
        "/test".to_string(),
        Some("default".to_string()),
    );
    store.start_session(&session1).unwrap();
    store.end_session("session-1").unwrap();
    store
        .update_session_outcome("session-1", cas_types::SessionOutcome::TasksCompleted)
        .unwrap();

    let session2 = cas_types::Session::new(
        "session-2".to_string(),
        "/test".to_string(),
        Some("default".to_string()),
    );
    store.start_session(&session2).unwrap();
    store.end_session("session-2").unwrap();
    store
        .update_session_outcome("session-2", cas_types::SessionOutcome::TasksCompleted)
        .unwrap();

    let session3 = cas_types::Session::new(
        "session-3".to_string(),
        "/test".to_string(),
        Some("default".to_string()),
    );
    store.start_session(&session3).unwrap();
    store.end_session("session-3").unwrap();
    store
        .update_session_outcome("session-3", cas_types::SessionOutcome::Abandoned)
        .unwrap();

    // Query outcome summary
    let results = store.outcome_summary(30).unwrap();
    assert_eq!(results.len(), 2);

    // Find tasks_completed
    let completed = results
        .iter()
        .find(|(o, _, _)| o == "tasks_completed")
        .unwrap();
    assert_eq!(completed.1, 2); // count
    assert!((completed.2 - 66.67).abs() < 0.1); // ~66.67%

    // Find abandoned
    let abandoned = results.iter().find(|(o, _, _)| o == "abandoned").unwrap();
    assert_eq!(abandoned.1, 1); // count
    assert!((abandoned.2 - 33.33).abs() < 0.1); // ~33.33%
}
