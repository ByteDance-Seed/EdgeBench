#[tokio::test]
async fn test_task_create_basic() {
    let (_temp, service) = setup_cas();

    let req = TaskCreateRequest {
        title: "Test task".to_string(),
        description: Some("Task description".to_string()),
        priority: 2,
        task_type: "task".to_string(),
        labels: Some("test,task".to_string()),
        notes: None,
        blocked_by: None,
        design: None,
        acceptance_criteria: None,
        external_ref: None,
        assignee: None,
        demo_statement: None,
        epic: None,
    };

    let result = service
        .cas_task_create(Parameters(req))
        .await
        .expect("task_create should succeed");

    let text = extract_text(result);
    assert!(text.contains("Created task"));
    assert!(text.contains("Test task"));
}

#[tokio::test]
async fn test_task_create_and_start() {
    let (_temp, service) = setup_cas();

    // Create task
    let req = TaskCreateRequest {
        title: "Auto-start task".to_string(),
        description: None,
        priority: 1,
        task_type: "feature".to_string(),
        labels: None,
        notes: None,
        blocked_by: None,
        design: None,
        acceptance_criteria: None,
        external_ref: None,
        assignee: None,
        demo_statement: None,
        epic: None,
    };

    let result = service
        .cas_task_create(Parameters(req))
        .await
        .expect("task_create should succeed");

    let text = extract_text(result);
    assert!(text.contains("Created"));
    let task_id = extract_task_id(&text).expect("should have task ID");

    // Start the task separately using the start action
    let start_req = IdRequest {
        id: task_id.to_string(),
    };
    let start_result = service
        .cas_task_start(Parameters(start_req))
        .await
        .expect("task_start should succeed");

    let start_text = extract_text(start_result);
    // After starting, the output includes claim info (e.g., "claimed until HH:MM")
    assert!(
        start_text.contains("claimed"),
        "Task start should show claimed: {start_text}"
    );
    // Workflow guidance should be included when starting a task
    assert!(
        start_text.contains("Workflow Guidance"),
        "Task start should include workflow guidance: {start_text}"
    );
    assert!(
        start_text.contains("mcp__cas__search"),
        "Workflow guidance should mention CAS search: {start_text}"
    );
}

#[tokio::test]
async fn test_task_create_surfaces_dependency_write_failure() {
    let (temp, service) = setup_cas();

    let blocker = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Blocking task".to_string(),
            description: None,
            priority: 2,
            task_type: "task".to_string(),
            labels: None,
            notes: None,
            blocked_by: None,
            design: None,
            acceptance_criteria: None,
            external_ref: None,
            assignee: None,
            demo_statement: None,
            epic: None,
        }))
        .await
        .expect("blocker create should succeed");
    let blocker_id = extract_task_id(&extract_text(blocker))
        .expect("blocker id")
        .to_string();

    let db_path = temp.path().join(".cas").join("cas.db");
    let conn = Connection::open(&db_path).expect("open sqlite db");
    conn.execute(
        "CREATE TRIGGER fail_dependency_insert
         BEFORE INSERT ON dependencies
         BEGIN
             SELECT RAISE(FAIL, 'forced dependency insert failure');
         END;",
        [],
    )
    .expect("create insert failure trigger");

    let create_result = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Should fail dependency write".to_string(),
            description: None,
            priority: 2,
            task_type: "task".to_string(),
            labels: None,
            notes: None,
            blocked_by: Some(blocker_id),
            design: None,
            acceptance_criteria: None,
            external_ref: None,
            assignee: None,
            demo_statement: None,
            epic: None,
        }))
        .await;
    assert!(
        create_result.is_err(),
        "Dependency write failure should be returned to caller"
    );

    let list_text = extract_text(
        service
            .cas_task_list(Parameters(TaskListRequest {
                scope: "all".to_string(),
                limit: Some(20),
                status: None,
                task_type: None,
                label: None,
                assignee: None,
                epic: None,
                sort: None,
                sort_order: None,
            }))
            .await
            .expect("task_list should succeed"),
    );
    assert!(
        !list_text.contains("Should fail dependency write"),
        "create_atomic should roll back task on dependency insert error: {list_text}"
    );
}
