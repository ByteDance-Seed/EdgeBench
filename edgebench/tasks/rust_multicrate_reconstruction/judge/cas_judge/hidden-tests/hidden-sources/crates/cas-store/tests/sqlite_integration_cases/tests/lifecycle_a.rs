#[test]
fn test_sqlite_store_full_lifecycle() {
    let temp = setup_temp_dir();
    let store = SqliteStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Generate ID (format: YYYY-MM-DD-N)
    let id = store.generate_id().expect("Failed to generate ID");
    assert!(id.contains("-"), "ID should be date-based: {id}");

    // Create and add entry
    let mut entry = Entry::new(id.clone(), "Test entry content".to_string());
    entry.entry_type = EntryType::Learning;
    entry.tags = vec!["test".to_string(), "integration".to_string()];
    store.add(&entry).expect("Failed to add entry");

    // Get entry
    let retrieved = store.get(&id).expect("Failed to get entry");
    assert_eq!(retrieved.content, "Test entry content");
    assert_eq!(retrieved.tags.len(), 2);

    // Update entry
    let mut updated = retrieved.clone();
    updated.content = "Updated content".to_string();
    updated.helpful_count = 5;
    store.update(&updated).expect("Failed to update entry");

    let after_update = store.get(&id).expect("Failed to get after update");
    assert_eq!(after_update.content, "Updated content");
    assert_eq!(after_update.helpful_count, 5);

    // List entries
    let list = store.list().expect("Failed to list entries");
    assert_eq!(list.len(), 1);

    // Recent entries
    let recent = store.recent(10).expect("Failed to get recent");
    assert_eq!(recent.len(), 1);

    // Archive
    store.archive(&id).expect("Failed to archive");
    assert!(store.get(&id).is_err());

    let archived_list = store.list_archived().expect("Failed to list archived");
    assert_eq!(archived_list.len(), 1);

    // Unarchive
    store.unarchive(&id).expect("Failed to unarchive");
    assert!(store.get(&id).is_ok());

    // Delete
    store.delete(&id).expect("Failed to delete");
    assert!(store.get(&id).is_err());

    store.close().expect("Failed to close store");
}

#[test]
fn test_sqlite_store_session_entries() {
    let temp = setup_temp_dir();
    let store = SqliteStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Add entries with different sessions
    let mut e1 = Entry::new("e1".to_string(), "Session A entry".to_string());
    e1.session_id = Some("session-a".to_string());
    store.add(&e1).expect("Failed to add e1");

    let mut e2 = Entry::new("e2".to_string(), "Session B entry".to_string());
    e2.session_id = Some("session-b".to_string());
    store.add(&e2).expect("Failed to add e2");

    let mut e3 = Entry::new("e3".to_string(), "Session A entry 2".to_string());
    e3.session_id = Some("session-a".to_string());
    store.add(&e3).expect("Failed to add e3");

    let session_a = store
        .list_by_session("session-a")
        .expect("Failed to list by session");
    assert_eq!(session_a.len(), 2);
}

#[test]
fn test_sqlite_task_store_full_lifecycle() {
    let temp = setup_temp_dir();
    let store = SqliteTaskStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Generate ID
    let id = store.generate_id().expect("Failed to generate ID");
    assert!(id.starts_with("cas-"));

    // Create and add task
    let mut task = Task::new(id.clone(), "Implement feature X".to_string());
    task.description = "Detailed description".to_string();
    task.priority = Priority(1);
    task.labels = vec!["feature".to_string()];
    store.add(&task).expect("Failed to add task");

    // Get task
    let retrieved = store.get(&id).expect("Failed to get task");
    assert_eq!(retrieved.title, "Implement feature X");
    assert_eq!(retrieved.priority.0, 1);

    // Update task
    let mut updated = retrieved.clone();
    updated.status = TaskStatus::InProgress;
    store.update(&updated).expect("Failed to update task");

    let after_update = store.get(&id).expect("Failed to get after update");
    assert_eq!(after_update.status, TaskStatus::InProgress);

    // Ready tasks (before updating to InProgress - list_ready only returns 'open' tasks)
    // Reset task to Open for this test
    let mut open_task = after_update.clone();
    open_task.status = TaskStatus::Open;
    store.update(&open_task).expect("Failed to reset to open");

    let ready = store.list_ready().expect("Failed to list ready");
    assert_eq!(ready.len(), 1);

    // Update back to InProgress
    let mut updated = open_task.clone();
    updated.status = TaskStatus::InProgress;
    store
        .update(&updated)
        .expect("Failed to update to in_progress");

    // List tasks
    let all = store.list(None).expect("Failed to list all tasks");
    assert_eq!(all.len(), 1);

    let in_progress = store
        .list(Some(TaskStatus::InProgress))
        .expect("Failed to list in_progress");
    assert_eq!(in_progress.len(), 1);

    // Delete
    store.delete(&id).expect("Failed to delete task");
    assert!(store.get(&id).is_err());

    store.close().expect("Failed to close store");
}

#[test]
fn test_sqlite_task_store_dependencies() {
    let temp = setup_temp_dir();
    let store = SqliteTaskStore::open(temp.path()).expect("Failed to create store");
    store.init().expect("Failed to init store");

    // Create tasks
    let t1 = Task::new("task-1".to_string(), "Task 1".to_string());
    let t2 = Task::new("task-2".to_string(), "Task 2".to_string());
    let t3 = Task::new("task-3".to_string(), "Task 3".to_string());

    store.add(&t1).expect("Failed to add t1");
    store.add(&t2).expect("Failed to add t2");
    store.add(&t3).expect("Failed to add t3");

    // Add dependencies: t1 is blocked by t2
    let dep = Dependency::new(
        "task-1".to_string(),
        "task-2".to_string(),
        DependencyType::Blocks,
    );
    store
        .add_dependency(&dep)
        .expect("Failed to add dependency");

    // Check dependencies
    let deps = store
        .get_dependencies("task-1")
        .expect("Failed to get dependencies");
    assert_eq!(deps.len(), 1);
    assert_eq!(deps[0].to_id, "task-2");

    // Check blockers
    let blockers = store
        .get_blockers("task-1")
        .expect("Failed to get blockers");
    assert_eq!(blockers.len(), 1);
    assert_eq!(blockers[0].id, "task-2");

    // Ready tasks (t1 should not be ready, t2 and t3 should be)
    let ready = store.list_ready().expect("Failed to list ready");
    assert_eq!(ready.len(), 2);
    assert!(ready.iter().all(|t| t.id != "task-1"));

    // Blocked tasks
    let blocked = store.list_blocked().expect("Failed to list blocked");
    assert_eq!(blocked.len(), 1);
    assert_eq!(blocked[0].0.id, "task-1");

    // Remove dependency
    store
        .remove_dependency("task-1", "task-2")
        .expect("Failed to remove dependency");

    let deps_after = store
        .get_dependencies("task-1")
        .expect("Failed to get dependencies after");
    assert_eq!(deps_after.len(), 0);
}
