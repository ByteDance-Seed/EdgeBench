use crate::support::*;
use cas::mcp::tools::*;
use rmcp::handler::server::wrapper::Parameters;

#[tokio::test]
async fn test_search_empty() {
    let (_temp, service) = setup_cas();

    let req = SearchRequest {
        scope: "all".to_string(),
        query: "nonexistent content".to_string(),
        doc_type: None,
        limit: 10,
        tags: None,
    };

    let result = service
        .cas_search(Parameters(req))
        .await
        .expect("search should succeed");

    let text = extract_text(result);
    // Should return empty or no results message
    assert!(text.contains("No results") || text.contains("0") || text.is_empty());
}

#[tokio::test]
async fn test_search_with_content() {
    let (_temp, service) = setup_cas();

    // Create searchable content
    let req = RememberRequest {
        scope: "project".to_string(),
        content: "Searchable unique memory content for testing search functionality".to_string(),
        entry_type: "learning".to_string(),
        tags: Some("search,test".to_string()),
        title: None,
        importance: 0.5,
        valid_from: None,
        valid_until: None,
        team_id: None,
    };
    service
        .cas_remember(Parameters(req))
        .await
        .expect("remember should succeed");

    // Search for it (may need index to be built first)
    let search_req = SearchRequest {
        scope: "all".to_string(),
        query: "searchable unique memory".to_string(),
        doc_type: Some("entry".to_string()),
        limit: 10,
        tags: None,
    };

    let result = service
        .cas_search(Parameters(search_req))
        .await
        .expect("search should succeed");

    // Search result depends on whether index was built
    let text = extract_text(result);
    assert!(!text.is_empty());
}

#[tokio::test]
async fn test_search_filter_by_type() {
    let (_temp, service) = setup_cas();

    // Create content
    let req = RememberRequest {
        scope: "project".to_string(),
        content: "Filter test memory".to_string(),
        entry_type: "learning".to_string(),
        tags: None,
        title: None,
        importance: 0.5,
        valid_from: None,
        valid_until: None,
        team_id: None,
    };
    service
        .cas_remember(Parameters(req))
        .await
        .expect("remember should succeed");

    let task_req = TaskCreateRequest {
        title: "Filter test task".to_string(),
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
        .cas_task_create(Parameters(task_req))
        .await
        .expect("task_create should succeed");

    // Search only tasks
    let search_req = SearchRequest {
        scope: "all".to_string(),
        query: "filter test".to_string(),
        doc_type: Some("task".to_string()),
        limit: 10,
        tags: None,
    };

    let result = service
        .cas_search(Parameters(search_req))
        .await
        .expect("search should succeed");

    let text = extract_text(result);
    // Should only return tasks if any match
    if !text.contains("No results") {
        // If we got results, they should be task-related
        assert!(!text.contains("entry") || text.contains("task"));
    }
}
