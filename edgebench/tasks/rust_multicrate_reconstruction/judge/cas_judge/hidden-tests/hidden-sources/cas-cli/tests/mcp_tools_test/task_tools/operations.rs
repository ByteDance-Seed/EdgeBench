#[tokio::test]
async fn test_task_update_design_and_acceptance_criteria() {
    let (_temp, service) = setup_cas();

    // Create task
    let req = TaskCreateRequest {
        title: "Spec task".to_string(),
        description: None,
        priority: 2,
        task_type: "epic".to_string(),
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
    let id = extract_task_id(&text).expect("should have task ID");

    // Update design and acceptance_criteria
    let update_req = TaskUpdateRequest {
        id: id.to_string(),
        title: None,
        notes: None,
        priority: None,
        labels: None,
        description: None,
        design: Some("## Technical Spec\nThis is the design.".to_string()),
        acceptance_criteria: Some("- [ ] Criterion 1\n- [ ] Criterion 2".to_string()),
        demo_statement: None,
        external_ref: None,
        assignee: None,
        status: None,
        epic: None,
        epic_verification_owner: None,
    };

    let result = service
        .cas_task_update(Parameters(update_req))
        .await
        .expect("task_update should succeed");

    let text = extract_text(result);
    assert!(
        text.contains("Updated") || text.contains("updated") || text.contains("design"),
        "Update should succeed: {text}"
    );

    // Verify via show
    let show_req = TaskShowRequest {
        id: id.to_string(),
        with_deps: false,
    };

    let result = service
        .cas_task_show(Parameters(show_req))
        .await
        .expect("task_show should succeed");

    let text = extract_text(result);
    assert!(
        text.contains("Technical Spec"),
        "Show should include design: {text}"
    );
    assert!(
        text.contains("Criterion 1"),
        "Show should include acceptance_criteria: {text}"
    );
}

#[tokio::test]
async fn test_task_list() {
    let (_temp, service) = setup_cas();

    // Create tasks
    for i in 0..3 {
        let req = TaskCreateRequest {
            title: format!("List task {i}"),
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
        };
        service
            .cas_task_create(Parameters(req))
            .await
            .expect("task_create should succeed");
    }

    // List tasks
    let list_req = TaskListRequest {
        scope: "all".to_string(),
        limit: Some(10),
        status: None,
        task_type: None,
        label: None,
        assignee: None,
        epic: None,
        sort: None,
        sort_order: None,
    };
    let result = service
        .cas_task_list(Parameters(list_req))
        .await
        .expect("task_list should succeed");

    let text = extract_text(result);
    assert!(text.contains("List task") || text.contains("Tasks"));
}

#[tokio::test]
async fn test_task_dependencies() {
    let (_temp, service) = setup_cas();

    // Create two tasks
    let req1 = TaskCreateRequest {
        title: "Blocker task".to_string(),
        description: None,
        priority: 1,
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
    };

    let result1 = service
        .cas_task_create(Parameters(req1))
        .await
        .expect("task_create should succeed");

    let text1 = extract_text(result1);
    let blocker_id = extract_task_id(&text1).expect("should have task ID");

    let req2 = TaskCreateRequest {
        title: "Blocked task".to_string(),
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
    };

    let result2 = service
        .cas_task_create(Parameters(req2))
        .await
        .expect("task_create should succeed");

    let text2 = extract_text(result2);
    let blocked_id = extract_task_id(&text2).expect("should have task ID");

    // Add dependency
    let dep_req = DependencyRequest {
        from_id: blocked_id.to_string(),
        to_id: blocker_id.to_string(),
        dep_type: "blocks".to_string(),
    };

    let result = service
        .cas_task_dep_add(Parameters(dep_req))
        .await
        .expect("task_dep_add should succeed");

    let text = extract_text(result);
    assert!(text.contains("dependency") || text.contains("Added") || text.contains("blocks"));

    // List dependencies
    let dep_list_req = IdRequest {
        id: blocked_id.to_string(),
    };
    let result = service
        .cas_task_dep_list(Parameters(dep_list_req))
        .await
        .expect("task_dep_list should succeed");

    let text = extract_text(result);
    assert!(text.contains(blocker_id) || text.contains("blocks"));
}

#[tokio::test]
async fn test_task_show_dependency_direction_labels() {
    let (_temp, service) = setup_cas();

    let blocker = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Direction blocker".to_string(),
            description: None,
            priority: 1,
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

    let blocked = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Direction blocked".to_string(),
            description: None,
            priority: 2,
            task_type: "task".to_string(),
            labels: None,
            notes: None,
            blocked_by: Some(blocker_id.clone()),
            design: None,
            acceptance_criteria: None,
            external_ref: None,
            assignee: None,
            demo_statement: None,
            epic: None,
        }))
        .await
        .expect("blocked create should succeed");
    let blocked_id = extract_task_id(&extract_text(blocked))
        .expect("blocked id")
        .to_string();

    let show = service
        .cas_task_show(Parameters(TaskShowRequest {
            id: blocked_id.clone(),
            with_deps: true,
        }))
        .await
        .expect("task_show should succeed");
    let text = extract_text(show);
    assert!(
        text.contains("BlockedBy:") && text.contains(&blocker_id),
        "Blocked task should display inbound blockers clearly: {text}"
    );

    let blocker_show = service
        .cas_task_show(Parameters(TaskShowRequest {
            id: blocker_id.clone(),
            with_deps: true,
        }))
        .await
        .expect("task_show should succeed");
    let blocker_text = extract_text(blocker_show);
    assert!(
        blocker_text.contains("Blocks:") && blocker_text.contains(&blocked_id),
        "Blocker task should show downstream dependent tasks: {blocker_text}"
    );
}
