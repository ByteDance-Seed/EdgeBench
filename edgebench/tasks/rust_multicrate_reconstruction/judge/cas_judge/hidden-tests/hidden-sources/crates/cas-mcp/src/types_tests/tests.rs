#[test]
fn test_memory_request_default() {
    let req: MemoryRequest = serde_json::from_str(r#"{"action": "list"}"#).unwrap();
    assert_eq!(req.action, "list");
    assert!(req.id.is_none());
    assert!(req.content.is_none());
}

#[test]
fn test_task_request_with_options() {
    let req: TaskRequest = serde_json::from_str(
        r#"{
            "action": "create",
            "title": "Test task",
            "priority": 1
        }"#,
    )
    .unwrap();
    assert_eq!(req.action, "create");
    assert_eq!(req.title, Some("Test task".to_string()));
    assert_eq!(req.priority, Some(1));
}
