#[test]
fn test_remove_stale() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    // Create a stale skill directory
    let stale_dir = target.join("cas-stale");
    fs::create_dir_all(&stale_dir).unwrap();
    fs::write(stale_dir.join("SKILL.md"), "stale").unwrap();

    // Sync with no skills
    let report = syncer.sync_all(&[]).unwrap();

    assert_eq!(report.removed, 1);
    assert!(!stale_dir.exists());
}

#[test]
fn test_sync_invokable_skill_no_user_invocable_false() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let mut skill = create_test_skill("invokable-skill", true);
    skill.invokable = true;
    skill.argument_hint = "[query]".to_string();

    syncer.sync_skill(&skill).unwrap();

    let content = fs::read_to_string(target.join("cas-invokable-skill/SKILL.md")).unwrap();
    // Invokable skills should NOT have user-invocable: false
    assert!(!content.contains("user-invocable: false"));
    assert!(content.contains("argument-hint: [query]"));
}

#[test]
fn test_sync_skill_with_all_frontmatter_fields() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let mut skill = create_test_skill("full-skill", true);
    skill.invokable = true;
    skill.argument_hint = "[file]".to_string();
    skill.context_mode = Some("fork".to_string());
    skill.agent_type = Some("Explore".to_string());
    skill.allowed_tools = vec!["Read".to_string(), "Bash".to_string()];

    syncer.sync_skill(&skill).unwrap();

    let content = fs::read_to_string(target.join("cas-full-skill/SKILL.md")).unwrap();
    // Should have all frontmatter fields
    assert!(content.contains("name: cas-full-skill"));
    assert!(content.contains("argument-hint: [file]"));
    assert!(content.contains("context: fork"));
    assert!(content.contains("agent: Explore"));
    assert!(content.contains("allowed-tools:"));
    assert!(content.contains("  - Read"));
    assert!(content.contains("  - Bash"));
    // Should NOT have user-invocable: false since it IS invokable
    assert!(!content.contains("user-invocable: false"));
}
