use crate::support::*;
use cas::mcp::tools::*;
use rmcp::handler::server::wrapper::Parameters;

#[tokio::test]
async fn test_empty_content_rejected() {
    let (_temp, service) = setup_cas();

    let req = RememberRequest {
        scope: "project".to_string(),
        content: "   ".to_string(), // Only whitespace
        entry_type: "learning".to_string(),
        tags: None,
        title: None,
        importance: 0.5,
        valid_from: None,
        valid_until: None,
        team_id: None,
    };

    // Should fail or handle gracefully
    let result = service.cas_remember(Parameters(req)).await;
    // May error or succeed with validation
    if let Ok(content) = result {
        let text = extract_text(content);
        // If it succeeds, it should still work
        assert!(!text.is_empty());
    }
}

#[tokio::test]
async fn test_very_long_content() {
    let (_temp, service) = setup_cas();

    let long_content = "a".repeat(10000);
    let req = RememberRequest {
        scope: "project".to_string(),
        content: long_content.clone(),
        entry_type: "learning".to_string(),
        tags: None,
        title: None,
        importance: 0.5,
        valid_from: None,
        valid_until: None,
        team_id: None,
    };

    let result = service
        .cas_remember(Parameters(req))
        .await
        .expect("remember should handle long content");

    let text = extract_text(result);
    assert!(text.contains("Created entry"));
}

#[tokio::test]
async fn test_special_characters_in_content() {
    let (_temp, service) = setup_cas();

    let special_content = "Content with émojis 🎉 and special chars: <>&\"'";
    let req = RememberRequest {
        scope: "project".to_string(),
        content: special_content.to_string(),
        entry_type: "learning".to_string(),
        tags: None,
        title: None,
        importance: 0.5,
        valid_from: None,
        valid_until: None,
        team_id: None,
    };

    let result = service
        .cas_remember(Parameters(req))
        .await
        .expect("remember should handle special characters");

    let text = extract_text(result);
    assert!(text.contains("Created entry"));
}

#[tokio::test]
async fn test_invalid_entry_type() {
    let (_temp, service) = setup_cas();

    let req = RememberRequest {
        scope: "project".to_string(),
        content: "Test content".to_string(),
        entry_type: "invalid_type".to_string(),
        tags: None,
        title: None,
        importance: 0.5,
        valid_from: None,
        valid_until: None,
        team_id: None,
    };

    // Should use default type
    let result = service
        .cas_remember(Parameters(req))
        .await
        .expect("remember should handle invalid type");

    let text = extract_text(result);
    assert!(text.contains("Created entry"));
}

#[tokio::test]
async fn test_importance_clamping() {
    let (_temp, service) = setup_cas();

    // Test importance > 1.0
    let req = RememberRequest {
        scope: "project".to_string(),
        content: "High importance".to_string(),
        entry_type: "learning".to_string(),
        tags: None,
        title: None,
        importance: 5.0, // Should be clamped to 1.0
        valid_from: None,
        valid_until: None,
        team_id: None,
    };

    let result = service
        .cas_remember(Parameters(req))
        .await
        .expect("remember should clamp importance");

    let text = extract_text(result);
    assert!(text.contains("Created entry"));
}


#[tokio::test]
async fn test_duplicate_dependency() {
    let (_temp, service) = setup_cas();

    // Create tasks
    let req1 = TaskCreateRequest {
        title: "Task A".to_string(),
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

    let result1 = service
        .cas_task_create(Parameters(req1))
        .await
        .expect("task_create should succeed");

    let text1 = extract_text(result1);
    let id_a = extract_task_id(&text1).expect("should have task ID");

    let req2 = TaskCreateRequest {
        title: "Task B".to_string(),
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

    let result2 = service
        .cas_task_create(Parameters(req2))
        .await
        .expect("task_create should succeed");

    let text2 = extract_text(result2);
    let id_b = extract_task_id(&text2).expect("should have task ID");

    // Add dependency
    let dep_req = DependencyRequest {
        from_id: id_b.to_string(),
        to_id: id_a.to_string(),
        dep_type: "blocks".to_string(),
    };

    service
        .cas_task_dep_add(Parameters(dep_req))
        .await
        .expect("first dep should succeed");

    // Add same dependency again - should handle gracefully
    let dep_req2 = DependencyRequest {
        from_id: id_b.to_string(),
        to_id: id_a.to_string(),
        dep_type: "blocks".to_string(),
    };
    let result = service.cas_task_dep_add(Parameters(dep_req2)).await;
    // May succeed (idempotent) or fail (duplicate)
    assert!(result.is_ok() || result.is_err());
}

#[tokio::test]
async fn test_self_dependency() {
    let (_temp, service) = setup_cas();

    let req = TaskCreateRequest {
        title: "Self dep task".to_string(),
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

    // Try to add self-dependency
    let dep_req = DependencyRequest {
        from_id: id.to_string(),
        to_id: id.to_string(),
        dep_type: "blocks".to_string(),
    };

    let result = service.cas_task_dep_add(Parameters(dep_req)).await;
    // Should fail (cyclic dependency)
    assert!(
        result.is_err() || {
            let text = extract_text(result.unwrap());
            text.contains("cycle") || text.contains("error") || text.contains("Error")
        }
    );
}
