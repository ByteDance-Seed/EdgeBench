#[tokio::test]
async fn test_task_lifecycle_with_verification() {
    let (temp, service) = setup_cas();
    let cas_dir = temp.path().join(".cas");

    // Initialize verification store
    let verification_store = open_verification_store(&cas_dir).unwrap();

    // Create task
    let req = TaskCreateRequest {
        title: "Lifecycle task".to_string(),
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

    let result = service
        .cas_task_create(Parameters(req))
        .await
        .expect("task_create should succeed");

    let text = extract_text(result);
    let id = extract_task_id(&text).expect("should have task ID");

    // Start task
    let start_req = IdRequest { id: id.to_string() };
    let result = service
        .cas_task_start(Parameters(start_req))
        .await
        .expect("task_start should succeed");

    let text = extract_text(result);
    assert!(text.contains("Started") || text.contains("in_progress"));

    // Create an approved verification record
    let verification = Verification::approved(
        "ver-test".to_string(),
        id.to_string(),
        "All checks passed".to_string(),
    );
    verification_store.add(&verification).unwrap();

    // Close task - should succeed now with verification
    let close_req = TaskCloseRequest {
        id: id.to_string(),
        reason: Some("Completed successfully".to_string()),
    };
    let result = service
        .cas_task_close(Parameters(close_req))
        .await
        .expect("task_close should succeed");

    let text = extract_text(result);
    assert!(
        text.contains("Closed") || text.contains("closed"),
        "Task should close with verification: {text}"
    );
    assert!(
        text.contains("verified"),
        "Should indicate verification: {text}"
    );
}

#[tokio::test]
async fn test_task_close_blocked_with_rejected_verification() {
    use cas::types::VerificationIssue;

    let (temp, service) = setup_cas();
    let cas_dir = temp.path().join(".cas");

    // Initialize verification store
    let verification_store = open_verification_store(&cas_dir).unwrap();

    // Create task
    let req = TaskCreateRequest {
        title: "Task with rejected verification".to_string(),
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

    let result = service
        .cas_task_create(Parameters(req))
        .await
        .expect("task_create should succeed");

    let text = extract_text(result);
    let id = extract_task_id(&text).expect("should have task ID");

    // Start task
    let start_req = IdRequest { id: id.to_string() };
    let _ = service
        .cas_task_start(Parameters(start_req))
        .await
        .expect("task_start should succeed");

    // Create a rejected verification record with issues
    let issues = vec![VerificationIssue::new(
        "src/main.rs".to_string(),
        "todo_comment".to_string(),
        "TODO comment found".to_string(),
    )];
    let verification = Verification::rejected(
        "ver-reject".to_string(),
        id.to_string(),
        "Found incomplete work".to_string(),
        issues,
    );
    verification_store.add(&verification).unwrap();

    // Try to close task - should be blocked due to rejected verification
    let close_req = TaskCloseRequest {
        id: id.to_string(),
        reason: Some("Completed".to_string()),
    };
    let result = service
        .cas_task_close(Parameters(close_req))
        .await
        .expect("task_close should return a result");

    let text = extract_text(result);
    assert!(
        text.contains("VERIFICATION FAILED"),
        "Close should be blocked with rejected verification: {text}"
    );
    assert!(text.contains("1 issue"), "Should show issue count: {text}");
}
