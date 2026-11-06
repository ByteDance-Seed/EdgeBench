#[tokio::test]
async fn test_rule_show() {
    let (_temp, service) = setup_cas();

    // Create rule
    let req = RuleCreateRequest {
        scope: "project".to_string(),
        content: "Test rule for show".to_string(),
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
    let id = text
        .split('[')
        .nth(1)
        .and_then(|s| s.split(']').next())
        .or_else(|| {
            text.split("rule-")
                .nth(1)
                .and_then(|s| s.split(|c: char| !c.is_alphanumeric()).next())
        })
        .expect("should have rule ID");

    let rule_id = if id.starts_with("rule-") {
        id.to_string()
    } else {
        format!("rule-{id}")
    };

    // Show rule
    let show_req = IdRequest {
        id: rule_id.clone(),
    };
    let result = service
        .cas_rule_show(Parameters(show_req))
        .await
        .expect("rule_show should succeed");

    let text = extract_text(result);
    assert!(text.contains("Test rule for show") || text.contains(&rule_id));
}

#[tokio::test]
async fn test_rule_helpful_and_harmful() {
    let (_temp, service) = setup_cas();

    // Create rule
    let req = RuleCreateRequest {
        scope: "project".to_string(),
        content: "Feedback test rule".to_string(),
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
    let id = if text.contains("rule-") {
        text.split("rule-")
            .nth(1)
            .and_then(|s| s.split(|c: char| !c.is_alphanumeric()).next())
            .map(|s| format!("rule-{s}"))
            .expect("should have rule ID")
    } else {
        text.split('[')
            .nth(1)
            .and_then(|s| s.split(']').next())
            .expect("should have rule ID")
            .to_string()
    };

    // Mark helpful
    let helpful_req = IdRequest { id: id.clone() };
    let result = service
        .cas_rule_helpful(Parameters(helpful_req))
        .await
        .expect("rule_helpful should succeed");

    let text = extract_text(result);
    assert!(text.contains("helpful") || text.contains("Promoted") || text.contains("Proven"));

    // Mark harmful
    let harmful_req = IdRequest { id: id.clone() };
    let result = service
        .cas_rule_harmful(Parameters(harmful_req))
        .await
        .expect("rule_harmful should succeed");

    let text = extract_text(result);
    assert!(text.contains("harmful"));
}

#[tokio::test]
async fn test_rule_delete() {
    let (_temp, service) = setup_cas();

    // Create rule
    let req = RuleCreateRequest {
        scope: "project".to_string(),
        content: "Delete test rule".to_string(),
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
    let id = if text.contains("rule-") {
        text.split("rule-")
            .nth(1)
            .and_then(|s| s.split(|c: char| !c.is_alphanumeric()).next())
            .map(|s| format!("rule-{s}"))
            .expect("should have rule ID")
    } else {
        text.split('[')
            .nth(1)
            .and_then(|s| s.split(']').next())
            .expect("should have rule ID")
            .to_string()
    };

    // Delete rule
    let delete_req = IdRequest { id: id.clone() };
    let result = service
        .cas_rule_delete(Parameters(delete_req))
        .await
        .expect("rule_delete should succeed");

    let text = extract_text(result);
    assert!(text.contains("Deleted"));
}
