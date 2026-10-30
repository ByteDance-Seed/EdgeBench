use crate::support::*;
use cas::mcp::tools::*;
use rmcp::handler::server::wrapper::Parameters;

#[tokio::test]
async fn test_context() {
    let (_temp, service) = setup_cas();

    // Create some content first
    let req = RememberRequest {
        scope: "project".to_string(),
        content: "Context test memory".to_string(),
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

    // Get context
    let ctx_req = LimitRequest {
        scope: "all".to_string(),
        limit: Some(5),
        sort: None,
        sort_order: None,
        team_id: None,
    };
    let result = service
        .cas_context(Parameters(ctx_req))
        .await
        .expect("context should succeed");

    let text = extract_text(result);
    // Context should return something (may be empty if no helpful memories)
    assert!(!text.is_empty() || text.contains("No context"));
}




