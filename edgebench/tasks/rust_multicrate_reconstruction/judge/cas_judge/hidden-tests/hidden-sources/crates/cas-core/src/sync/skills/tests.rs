#[test]
fn test_sync_invokable_skill() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let mut skill = create_test_skill("my-task", true);
    skill.invokable = true;
    skill.argument_hint = "[title]".to_string();

    syncer.sync_skill(&skill).unwrap();

    let content = fs::read_to_string(target.join("cas-my-task/SKILL.md")).unwrap();
    assert!(content.contains("argument-hint: [title]"));
}

#[test]
fn test_sync_passive_skill_no_argument_hint() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let skill = create_test_skill("passive-skill", true);
    // invokable defaults to false

    syncer.sync_skill(&skill).unwrap();

    let content = fs::read_to_string(target.join("cas-passive-skill/SKILL.md")).unwrap();
    assert!(!content.contains("argument-hint"));
    // Non-invokable skills should have user-invocable: false
    assert!(content.contains("user-invocable: false"));
}

#[test]
fn test_sync_skill_with_agent_type() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let mut skill = create_test_skill("agent-skill", true);
    skill.agent_type = Some("code-reviewer".to_string());

    syncer.sync_skill(&skill).unwrap();

    let content = fs::read_to_string(target.join("cas-agent-skill/SKILL.md")).unwrap();
    assert!(content.contains("agent: code-reviewer"));
}

#[test]
fn test_create_cas_skill() {
    let temp = TempDir::new().unwrap();
    create_cas_skill(temp.path()).unwrap();

    let skill_file = temp.path().join(".claude/skills/cas/SKILL.md");
    assert!(skill_file.exists());

    let content = fs::read_to_string(skill_file).unwrap();
    assert!(content.contains("name: cas"));
    // MCP mode content
    assert!(
        content.contains("mcp__cas__memory"),
        "Should contain memory tool reference"
    );
    assert!(
        content.contains("mcp__cas__task"),
        "Should contain task tool reference"
    );
}
