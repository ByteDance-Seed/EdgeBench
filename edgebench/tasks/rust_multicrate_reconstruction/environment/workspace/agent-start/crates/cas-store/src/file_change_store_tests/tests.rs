use crate::PROMPT_SCHEMA;
use crate::file_change_store::*;
use tempfile::TempDir;

fn setup_store() -> (SqliteFileChangeStore, TempDir) { todo!() }

/// Helper to create a test prompt in the database
fn create_test_prompt(dir: &TempDir, prompt_id: &str) { todo!() }

fn create_test_change(id: &str, session_id: &str, file_path: &str) -> FileChange { todo!() }



#[test]
fn test_list_by_prompt() {
    let (store, dir) = setup_store();

    // Create the prompt first (FK constraint)
    create_test_prompt(&dir, "prompt-abc");

    let mut change1 = create_test_change("fc-001", "session-1", "file1.rs");
    change1.prompt_id = Some("prompt-abc".to_string());

    let mut change2 = create_test_change("fc-002", "session-1", "file2.rs");
    change2.prompt_id = Some("prompt-abc".to_string());

    let change3 = create_test_change("fc-003", "session-1", "file3.rs");
    // No prompt_id

    store.add(&change1).unwrap();
    store.add(&change2).unwrap();
    store.add(&change3).unwrap();

    let prompt_changes = store.list_by_prompt("prompt-abc", 10).unwrap();
    assert_eq!(prompt_changes.len(), 2);
}


#[test]
fn test_uncommitted_and_link() {
    let (store, _dir) = setup_store();

    store
        .add(&create_test_change("fc-001", "session-1", "file1.rs"))
        .unwrap();
    store
        .add(&create_test_change("fc-002", "session-1", "file2.rs"))
        .unwrap();

    // Both should be uncommitted
    let uncommitted = store.list_uncommitted("session-1").unwrap();
    assert_eq!(uncommitted.len(), 2);

    // Link to commit
    let ids: Vec<String> = uncommitted.iter().map(|c| c.id.clone()).collect();
    let updated = store.link_to_commit(&ids, "abc123def").unwrap();
    assert_eq!(updated, 2);

    // Should be none uncommitted now
    let uncommitted = store.list_uncommitted("session-1").unwrap();
    assert_eq!(uncommitted.len(), 0);

    // Should be findable by commit
    let committed = store.list_by_commit("abc123def").unwrap();
    assert_eq!(committed.len(), 2);
    assert!(committed[0].commit_hash.is_some());
    assert!(committed[0].committed_at.is_some());
}

#[test]
fn test_list_recent() {
    let (store, _dir) = setup_store();

    for i in 0..5 {
        store
            .add(&create_test_change(
                &format!("fc-{i}"),
                "session-1",
                &format!("file{i}.rs"),
            ))
            .unwrap();
    }

    let recent = store.list_recent(3).unwrap();
    assert_eq!(recent.len(), 3);
}

#[test]
fn test_prune() {
    let (store, _dir) = setup_store();

    store
        .add(&create_test_change("fc-001", "session-1", "file.rs"))
        .unwrap();

    // Prune changes older than 30 days (should delete nothing)
    let deleted = store.prune(30).unwrap();
    assert_eq!(deleted, 0);

    let changes = store.list_recent(10).unwrap();
    assert_eq!(changes.len(), 1);
}

#[test]
fn test_change_with_prompt() {
    let (store, dir) = setup_store();

    // Create the prompt first (FK constraint)
    create_test_prompt(&dir, "prompt-xyz");

    let change = FileChange::with_prompt(
        "fc-001".to_string(),
        "session-1".to_string(),
        "agent-1".to_string(),
        Some("prompt-xyz".to_string()),
        "repo".to_string(),
        "file.rs".to_string(),
        ChangeType::Created,
        "Write".to_string(),
        None,
        "newhash".to_string(),
    );

    store.add(&change).unwrap();

    let retrieved = store.get("fc-001").unwrap().unwrap();
    assert_eq!(retrieved.prompt_id, Some("prompt-xyz".to_string()));
    assert_eq!(retrieved.change_type, ChangeType::Created);
    assert!(retrieved.old_content_hash.is_none());
}
