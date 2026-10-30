/// Documents expected field mappings for TaskRequest -> TaskListRequest
/// If you add a field to TaskRequest that should work with action=list,
/// add it here and ensure service/mod.rs passes it through.

/// Documents expected field mappings for SearchContextRequest code_search
#[test]
fn code_search_field_coverage() {
    // Fields from SearchContextRequest that action=code_search should support:
    let expected_fields = ["query", "limit", "kind", "language", "include_source"];

    // If you add a field for code_search, ensure it's used in
    // code_search_impl() in service/mod.rs

    assert_eq!(
        expected_fields.len(),
        5,
        "Update this test when adding code_search fields"
    );
}
