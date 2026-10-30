#[test]
fn test_director_data_load_empty_stores() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    // Initialize stores (creates tables)
    init_task_store(cas_dir);
    init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Load DirectorData from empty stores
    let result = DirectorData::load(cas_dir, None);
    assert!(
        result.is_ok(),
        "Should load from empty stores: {:?}",
        result.err()
    );

    let data = result.unwrap();
    assert!(data.ready_tasks.is_empty());
    assert!(data.in_progress_tasks.is_empty());
    assert!(data.epic_tasks.is_empty());
    assert!(data.agents.is_empty());
    assert!(data.activity.is_empty());
}

#[test]
fn test_director_data_loads_ready_tasks() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    let task_store = init_task_store(cas_dir);
    init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Add some open (ready) tasks
    let task1 = create_test_task(
        "cas-0001",
        "Task 1",
        TaskStatus::Open,
        TaskType::Task,
        Priority::HIGH,
        None,
    );
    let task2 = create_test_task(
        "cas-0002",
        "Task 2",
        TaskStatus::Open,
        TaskType::Feature,
        Priority::MEDIUM,
        None,
    );

    task_store.add(&task1).expect("Failed to add task1");
    task_store.add(&task2).expect("Failed to add task2");

    // Load DirectorData
    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");

    assert_eq!(data.ready_tasks.len(), 2, "Should have 2 ready tasks");
    assert!(data.ready_tasks.iter().any(|t| t.id == "cas-0001"));
    assert!(data.ready_tasks.iter().any(|t| t.id == "cas-0002"));
}

#[test]
fn test_director_data_loads_in_progress_tasks() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    let task_store = init_task_store(cas_dir);
    init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Add an in-progress task
    let task = create_test_task(
        "cas-0001",
        "In Progress Task",
        TaskStatus::InProgress,
        TaskType::Task,
        Priority::HIGH,
        Some("agent-1"),
    );

    task_store.add(&task).expect("Failed to add task");

    // Load DirectorData
    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");

    assert_eq!(data.in_progress_tasks.len(), 1);
    assert_eq!(data.in_progress_tasks[0].id, "cas-0001");
    assert_eq!(
        data.in_progress_tasks[0].assignee,
        Some("agent-1".to_string())
    );
}

#[test]
fn test_tasks_by_epic_standalone_tasks() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    let task_store = init_task_store(cas_dir);
    init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Add tasks without epic association
    let task1 = create_test_task(
        "cas-0001",
        "Standalone Task 1",
        TaskStatus::Open,
        TaskType::Task,
        Priority::HIGH,
        None,
    );
    let task2 = create_test_task(
        "cas-0002",
        "Standalone Task 2",
        TaskStatus::InProgress,
        TaskType::Task,
        Priority::MEDIUM,
        None,
    );

    task_store.add(&task1).expect("Failed to add task1");
    task_store.add(&task2).expect("Failed to add task2");

    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");
    let (groups, standalone) = data.tasks_by_epic();

    // No epic groups (no epics in the test data)
    assert!(groups.is_empty());

    // Both tasks should be standalone
    assert_eq!(standalone.len(), 2);
}

#[test]
fn test_tasks_by_epic_with_parent_child_dependency() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    let task_store = init_task_store(cas_dir);
    init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Create an epic
    let epic = create_test_task(
        "cas-epic",
        "Test Epic",
        TaskStatus::InProgress,
        TaskType::Epic,
        Priority::CRITICAL,
        None,
    );

    // Create subtasks
    let subtask1 = create_test_task(
        "cas-0001",
        "Subtask 1",
        TaskStatus::Open,
        TaskType::Task,
        Priority::HIGH,
        None,
    );
    let subtask2 = create_test_task(
        "cas-0002",
        "Subtask 2",
        TaskStatus::InProgress,
        TaskType::Task,
        Priority::HIGH,
        None,
    );

    task_store.add(&epic).expect("Failed to add epic");
    task_store.add(&subtask1).expect("Failed to add subtask1");
    task_store.add(&subtask2).expect("Failed to add subtask2");

    // Create parent-child dependencies
    let dep1 = Dependency {
        from_id: "cas-0001".to_string(),
        to_id: "cas-epic".to_string(),
        dep_type: DependencyType::ParentChild,
        created_at: chrono::Utc::now(),
        created_by: None,
    };
    let dep2 = Dependency {
        from_id: "cas-0002".to_string(),
        to_id: "cas-epic".to_string(),
        dep_type: DependencyType::ParentChild,
        created_at: chrono::Utc::now(),
        created_by: None,
    };

    task_store
        .add_dependency(&dep1)
        .expect("Failed to add dep1");
    task_store
        .add_dependency(&dep2)
        .expect("Failed to add dep2");

    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");
    let (groups, standalone) = data.tasks_by_epic();

    // Should have one epic group with 2 subtasks
    assert_eq!(groups.len(), 1, "Should have one epic group");
    assert_eq!(groups[0].epic.id, "cas-epic");
    assert_eq!(groups[0].subtasks.len(), 2, "Epic should have 2 subtasks");
    assert!(groups[0].has_active, "Epic should have active subtasks");

    // No standalone tasks
    assert!(standalone.is_empty(), "All tasks belong to epic");
}
