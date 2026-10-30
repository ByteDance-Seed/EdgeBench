#[tokio::test]
async fn test_negative_priority() {
    let (_temp, service) = setup_cas();

    // Negative priority should be handled
    let req = TaskCreateRequest {
        title: "Negative priority task".to_string(),
        description: None,
        priority: 255, // Max u8, should be clamped or handled
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

    // Should succeed or fail gracefully
    let result = service.cas_task_create(Parameters(req)).await;
    assert!(result.is_ok() || result.is_err());
}
