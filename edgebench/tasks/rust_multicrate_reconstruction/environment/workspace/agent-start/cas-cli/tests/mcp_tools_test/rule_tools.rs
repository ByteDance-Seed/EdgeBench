use crate::support::*;
use cas::mcp::tools::*;
use rmcp::handler::server::wrapper::Parameters;

#[tokio::test]
async fn test_rule_create() {
    let (_temp, service) = setup_cas();

    let req = RuleCreateRequest {
        scope: "project".to_string(),
        content: "Always use snake_case for function names".to_string(),
        paths: Some("**/*.rs".to_string()),
        tags: Some("style,naming".to_string()),
        auto_approve_tools: None,
        auto_approve_paths: None,
    };

    let result = service
        .cas_rule_create(Parameters(req))
        .await
        .expect("rule_create should succeed");

    let text = extract_text(result);
    assert!(text.contains("Created rule") || text.contains("rule"));
}


#[tokio::test]
async fn test_rule_list() {
    let (_temp, service) = setup_cas();

    // Create rules
    for i in 0..3 {
        let req = RuleCreateRequest {
            scope: "project".to_string(),
            content: format!("List rule {i}"),
            paths: None,
            tags: None,
            auto_approve_tools: None,
            auto_approve_paths: None,
        };
        service
            .cas_rule_create(Parameters(req))
            .await
            .expect("rule_create should succeed");
    }

    // List all rules
    let list_req = LimitRequest {
        scope: "all".to_string(),
        limit: Some(10),
        sort: None,
        sort_order: None,
        team_id: None,
    };
    let result = service
        .cas_rule_list_all(Parameters(list_req))
        .await
        .expect("rule_list_all should succeed");

    let text = extract_text(result);
    assert!(text.contains("List rule") || text.contains("Rules") || text.contains("rule"));
}

#[tokio::test]
async fn test_rule_update() {
    let (_temp, service) = setup_cas();

    // Create rule
    let req = RuleCreateRequest {
        scope: "project".to_string(),
        content: "Original rule content".to_string(),
        paths: None,
        tags: None,
        auto_approve_tools: None,
        auto_approve_paths: None,
    };

    let result = service
        .cas_rule_create(Parameters(req))
        .await
        .expect("rule_create should succeed");

    let text = extract_text(result);
    let id = extract_rule_id(&text).expect("should have rule ID");

    // Update rule
    let update_req = RuleUpdateRequest {
        id: id.clone(),
        content: Some("Updated rule content".to_string()),
        paths: Some("**/*.ts".to_string()),
        tags: None,
        auto_approve_tools: None,
        auto_approve_paths: None,
    };

    let result = service
        .cas_rule_update(Parameters(update_req))
        .await
        .expect("rule_update should succeed");

    let text = extract_text(result);
    assert!(text.contains("Updated") || text.contains("updated"));
}


