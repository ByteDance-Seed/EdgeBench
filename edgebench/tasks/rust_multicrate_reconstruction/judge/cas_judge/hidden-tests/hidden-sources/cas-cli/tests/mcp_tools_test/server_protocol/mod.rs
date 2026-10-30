#[test]
fn test_server_capabilities() {
    let (_temp, service) = setup_service();

    let info = service.get_info();

    // Server should enable tools, resources, and prompts
    assert!(info.capabilities.tools.is_some());
    assert!(info.capabilities.resources.is_some());
    assert!(info.capabilities.prompts.is_some());
}

#[test]
fn test_server_protocol_version() {
    let (_temp, service) = setup_service();

    let info = service.get_info();

    // Should use the expected protocol version
    assert_eq!(info.protocol_version, rmcp::model::ProtocolVersion::LATEST);
}

#[tokio::test]
async fn test_task_list_epic_filter() {
    let (_temp, service) = setup_cas();

    // Create an epic
    let epic_req = TaskCreateRequest {
        title: "My Test Epic".to_string(),
        description: Some("An epic to test filtering".to_string()),
        notes: None,
        priority: 1,
        task_type: "epic".to_string(),
        labels: None,
        blocked_by: None,
        design: None,
        acceptance_criteria: None,
        external_ref: None,
        assignee: None,
        demo_statement: None,
        epic: None,
    };
    let result = service
        .cas_task_create(Parameters(epic_req))
        .await
        .expect("create epic");
    let text = extract_text(result);
    // Extract epic ID from creation result
    let epic_id = text
        .split_whitespace()
        .find(|s| s.starts_with("cas-"))
        .map(|s| s.trim_end_matches([':', ')', '.']))
        .expect("Should find epic ID in output");

    // Create a subtask linked to the epic
    let subtask_req = TaskCreateRequest {
        title: "Subtask of Epic".to_string(),
        description: None,
        notes: None,
        priority: 2,
        task_type: "task".to_string(),
        labels: None,
        blocked_by: None,
        design: None,
        acceptance_criteria: None,
        external_ref: None,
        assignee: None,
        demo_statement: None,
        epic: Some(epic_id.to_string()),
    };
    service
        .cas_task_create(Parameters(subtask_req))
        .await
        .expect("create subtask");

    // Create an unrelated task (NOT linked to the epic)
    let unrelated_req = TaskCreateRequest {
        title: "Unrelated Task".to_string(),
        description: None,
        notes: None,
        priority: 2,
        task_type: "task".to_string(),
        labels: None,
        blocked_by: None,
        design: None,
        acceptance_criteria: None,
        external_ref: None,
        assignee: None,
        demo_statement: None,
        epic: None,
    };
    service
        .cas_task_create(Parameters(unrelated_req))
        .await
        .expect("create unrelated task");

    // List tasks filtered by epic - should only show subtask
    let list_req = TaskListRequest {
        scope: "all".to_string(),
        limit: Some(10),
        status: None,
        task_type: None,
        label: None,
        assignee: None,
        epic: Some(epic_id.to_string()),
        sort: None,
        sort_order: None,
    };
    let result = service
        .cas_task_list(Parameters(list_req))
        .await
        .expect("list tasks by epic");
    let text = extract_text(result);

    // Should contain the subtask
    assert!(
        text.contains("Subtask of Epic"),
        "Should contain subtask of epic: {text}"
    );
    // Should NOT contain the unrelated task
    assert!(
        !text.contains("Unrelated Task"),
        "Should NOT contain unrelated task: {text}"
    );
    // Should NOT contain the epic itself (only its children)
    assert!(
        !text.contains("My Test Epic"),
        "Should NOT contain the epic itself: {text}"
    );
}
