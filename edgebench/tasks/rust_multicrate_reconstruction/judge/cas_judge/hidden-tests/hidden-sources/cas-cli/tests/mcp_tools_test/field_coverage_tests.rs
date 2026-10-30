#[test]
fn task_list_field_coverage() {
    // Fields from TaskRequest that action=list should support:
    let expected_list_fields = [
        "limit",
        "scope",
        "status",
        "task_type",
        "labels", // mapped as "label" in TaskListRequest
        "assignee",
        "epic", // Added 2026-01-27 - was missing!
        "sort",
        "sort_order",
    ];

    // This test serves as documentation. If you add a field to TaskRequest
    // with a description mentioning "list", ensure it's:
    // 1. Added to TaskListRequest in types.rs
    // 2. Passed in task_list() in service/mod.rs
    // 3. Implemented in cas_task_list() in mod.rs
    // 4. Added to this list

    // Verify the mapping exists by checking the struct has these fields
    // (compile-time check via unused variable warnings)
    let _ = cas::mcp::tools::TaskListRequest {
        limit: None,
        scope: "all".to_string(),
        status: None,
        task_type: None,
        label: None, // Note: "labels" in TaskRequest -> "label" in TaskListRequest
        assignee: None,
        epic: None,
        sort: None,
        sort_order: None,
    };

    assert_eq!(
        expected_list_fields.len(),
        9,
        "Update this test when adding task list fields"
    );
}
