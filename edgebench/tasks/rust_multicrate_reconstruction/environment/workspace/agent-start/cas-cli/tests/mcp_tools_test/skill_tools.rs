use crate::support::*;
use cas::mcp::tools::*;
use rmcp::handler::server::wrapper::Parameters;

#[tokio::test]
async fn test_skill_create() {
    let (_temp, service) = setup_cas();

    let req = SkillCreateRequest {
        scope: "global".to_string(),
        name: "Test Skill".to_string(),
        description: "A skill for testing".to_string(),
        invocation: "test-skill".to_string(),
        skill_type: "command".to_string(),
        tags: Some("test,skill".to_string()),
        summary: None,
        example: None,
        preconditions: None,
        postconditions: None,
        validation_script: None,
        invokable: false,
        argument_hint: None,
        context_mode: None,
        agent_type: None,
        allowed_tools: None,
        draft: false,
        disable_model_invocation: false,
    };

    let result = service
        .cas_skill_create(Parameters(req))
        .await
        .expect("skill_create should succeed");

    let text = extract_text(result);
    assert!(text.contains("Created skill") || text.contains("Test Skill"));
}

#[tokio::test]
async fn test_skill_show() {
    let (_temp, service) = setup_cas();

    // Create skill
    let req = SkillCreateRequest {
        scope: "global".to_string(),
        name: "Show Skill".to_string(),
        description: "A skill for show test".to_string(),
        invocation: "show-skill".to_string(),
        skill_type: "command".to_string(),
        tags: None,
        summary: None,
        example: None,
        preconditions: None,
        postconditions: None,
        validation_script: None,
        invokable: false,
        argument_hint: None,
        context_mode: None,
        agent_type: None,
        allowed_tools: None,
        draft: false,
        disable_model_invocation: false,
    };

    let result = service
        .cas_skill_create(Parameters(req))
        .await
        .expect("skill_create should succeed");

    let text = extract_text(result);
    let id = extract_skill_id(&text).expect("should have skill ID");

    // Show skill
    let show_req = IdRequest { id: id.clone() };
    let result = service
        .cas_skill_show(Parameters(show_req))
        .await
        .expect("skill_show should succeed");

    let text = extract_text(result);
    assert!(text.contains("Show Skill") || text.contains("show-skill"));
}

#[tokio::test]
async fn test_skill_list() {
    let (_temp, service) = setup_cas();

    // Create skills
    for i in 0..3 {
        let req = SkillCreateRequest {
            scope: "global".to_string(),
            name: format!("List Skill {i}"),
            description: format!("Skill {i} for list test"),
            invocation: format!("list-skill-{i}"),
            skill_type: "command".to_string(),
            tags: None,
            summary: None,
            example: None,
            preconditions: None,
            postconditions: None,
            validation_script: None,
            invokable: false,
            argument_hint: None,
            context_mode: None,
            agent_type: None,
            allowed_tools: None,
            draft: false,
            disable_model_invocation: false,
        };
        service
            .cas_skill_create(Parameters(req))
            .await
            .expect("skill_create should succeed");
    }

    // List all skills
    let list_req = LimitRequest {
        scope: "all".to_string(),
        limit: Some(10),
        sort: None,
        sort_order: None,
        team_id: None,
    };
    let result = service
        .cas_skill_list_all(Parameters(list_req))
        .await
        .expect("skill_list_all should succeed");

    let text = extract_text(result);
    assert!(text.contains("List Skill") || text.contains("Skills"));
}

#[tokio::test]
async fn test_skill_update() {
    let (_temp, service) = setup_cas();

    // Create skill
    let req = SkillCreateRequest {
        scope: "global".to_string(),
        name: "Update Skill".to_string(),
        description: "Original description".to_string(),
        invocation: "update-skill".to_string(),
        skill_type: "command".to_string(),
        tags: None,
        summary: None,
        example: None,
        preconditions: None,
        postconditions: None,
        validation_script: None,
        invokable: false,
        argument_hint: None,
        context_mode: None,
        agent_type: None,
        allowed_tools: None,
        draft: false,
        disable_model_invocation: false,
    };

    let result = service
        .cas_skill_create(Parameters(req))
        .await
        .expect("skill_create should succeed");

    let text = extract_text(result);
    let id = extract_skill_id(&text).expect("should have skill ID");

    // Update skill
    let update_req = SkillUpdateRequest {
        id: id.to_string(),
        name: Some("Updated Skill Name".to_string()),
        description: Some("Updated description".to_string()),
        invocation: None,
        tags: None,
        summary: None,
        disable_model_invocation: None,
    };

    let result = service
        .cas_skill_update(Parameters(update_req))
        .await
        .expect("skill_update should succeed");

    let text = extract_text(result);
    assert!(text.contains("Updated") || text.contains("updated"));
}

#[tokio::test]
async fn test_skill_enable_disable() {
    let (_temp, service) = setup_cas();

    // Create skill
    let req = SkillCreateRequest {
        scope: "global".to_string(),
        name: "Enable Skill".to_string(),
        description: "Skill for enable/disable test".to_string(),
        invocation: "enable-skill".to_string(),
        skill_type: "command".to_string(),
        tags: None,
        summary: None,
        example: None,
        preconditions: None,
        postconditions: None,
        validation_script: None,
        invokable: false,
        argument_hint: None,
        context_mode: None,
        agent_type: None,
        allowed_tools: None,
        draft: false,
        disable_model_invocation: false,
    };

    let result = service
        .cas_skill_create(Parameters(req))
        .await
        .expect("skill_create should succeed");

    let text = extract_text(result);
    let id = extract_skill_id(&text).expect("should have skill ID");

    // Disable skill
    let disable_req = IdRequest { id: id.to_string() };
    let result = service
        .cas_skill_disable(Parameters(disable_req))
        .await
        .expect("skill_disable should succeed");

    let text = extract_text(result);
    assert!(text.contains("Disabled") || text.contains("disabled"));

    // Enable skill
    let enable_req = IdRequest { id: id.to_string() };
    let result = service
        .cas_skill_enable(Parameters(enable_req))
        .await
        .expect("skill_enable should succeed");

    let text = extract_text(result);
    assert!(text.contains("Enabled") || text.contains("enabled"));
}

#[tokio::test]
async fn test_skill_delete() {
    let (_temp, service) = setup_cas();

    // Create skill
    let req = SkillCreateRequest {
        scope: "global".to_string(),
        name: "Delete Skill".to_string(),
        description: "Skill for delete test".to_string(),
        invocation: "delete-skill".to_string(),
        skill_type: "command".to_string(),
        tags: None,
        summary: None,
        example: None,
        preconditions: None,
        postconditions: None,
        validation_script: None,
        invokable: false,
        argument_hint: None,
        context_mode: None,
        agent_type: None,
        allowed_tools: None,
        draft: false,
        disable_model_invocation: false,
    };

    let result = service
        .cas_skill_create(Parameters(req))
        .await
        .expect("skill_create should succeed");

    let text = extract_text(result);
    let id = extract_skill_id(&text).expect("should have skill ID");

    // Delete skill
    let delete_req = IdRequest { id: id.to_string() };
    let result = service
        .cas_skill_delete(Parameters(delete_req))
        .await
        .expect("skill_delete should succeed");

    let text = extract_text(result);
    assert!(text.contains("Deleted"));
}

