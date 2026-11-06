#[test]
fn test_add_and_get() {
    let (store, _dir) = setup_store();

    let change = create_test_change("fc-001", "session-1", "src/main.rs");
    store.add(&change).unwrap();

    let retrieved = store.get("fc-001").unwrap();
    assert!(retrieved.is_some());
    let retrieved = retrieved.unwrap();
    assert_eq!(retrieved.id, "fc-001");
    assert_eq!(retrieved.file_path, "src/main.rs");
    assert_eq!(retrieved.change_type, ChangeType::Modified);
}

#[test]
fn test_list_by_session() {
    let (store, _dir) = setup_store();

    store
        .add(&create_test_change("fc-001", "session-A", "file1.rs"))
        .unwrap();
    store
        .add(&create_test_change("fc-002", "session-A", "file2.rs"))
        .unwrap();
    store
        .add(&create_test_change("fc-003", "session-B", "file3.rs"))
        .unwrap();

    let session_a = store.list_by_session("session-A", 10).unwrap();
    assert_eq!(session_a.len(), 2);

    let session_b = store.list_by_session("session-B", 10).unwrap();
    assert_eq!(session_b.len(), 1);
}

#[test]
fn test_list_by_file() {
    let (store, _dir) = setup_store();

    store
        .add(&create_test_change("fc-001", "session-1", "src/main.rs"))
        .unwrap();
    store
        .add(&create_test_change("fc-002", "session-2", "src/main.rs"))
        .unwrap();
    store
        .add(&create_test_change("fc-003", "session-1", "src/lib.rs"))
        .unwrap();

    let main_changes = store.list_by_file("test-repo", "src/main.rs", 10).unwrap();
    assert_eq!(main_changes.len(), 2);

    let lib_changes = store.list_by_file("test-repo", "src/lib.rs", 10).unwrap();
    assert_eq!(lib_changes.len(), 1);
}
