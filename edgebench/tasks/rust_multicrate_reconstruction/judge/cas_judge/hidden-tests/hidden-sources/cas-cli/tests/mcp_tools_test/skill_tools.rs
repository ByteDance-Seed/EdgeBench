#[tokio::test]
async fn test_skill_use() {
    let (_temp, service) = setup_cas();

    // Create skill
    let req = SkillCreateRequest {
        scope: "global".to_string(),
        name: "Use Skill".to_string(),
        description: "Skill for use tracking".to_string(),
        invocation: "use-skill".to_string(),
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

    // Record skill use
    let use_req = IdRequest { id: id.to_string() };
    let result = service
        .cas_skill_use(Parameters(use_req))
        .await
        .expect("skill_use should succeed");

    let text = extract_text(result);
    assert!(text.contains("usage") || text.contains("Used") || text.contains("1"));
}
