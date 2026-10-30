use crate::sync::skills::*;
use cas_types::{Scope, SkillType};
use tempfile::TempDir;

fn create_test_skill(name: &str, enabled: bool) -> Skill { todo!() }

#[test]
fn test_is_enabled() {
    let syncer = SkillSyncer::new(PathBuf::from("/tmp/test"));

    let enabled = create_test_skill("enabled", true);
    let disabled = create_test_skill("disabled", false);

    assert!(syncer.is_enabled(&enabled));
    assert!(!syncer.is_enabled(&disabled));
}

#[test]
fn test_sync_skill() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let skill = create_test_skill("test-skill", true);

    // Sync the skill
    assert!(syncer.sync_skill(&skill).unwrap());

    // Check directory and file were created
    let skill_dir = target.join("cas-test-skill");
    assert!(skill_dir.exists());
    assert!(skill_dir.join("SKILL.md").exists());

    let content = fs::read_to_string(skill_dir.join("SKILL.md")).unwrap();
    assert!(content.contains("name: cas-test-skill"));
    assert!(content.contains("Test skill: test-skill"));
}

#[test]
fn test_sync_all() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let skill1 = create_test_skill("skill1", true);
    let skill2 = create_test_skill("skill2", false); // Not enabled

    let skills = vec![skill1, skill2];
    let report = syncer.sync_all(&skills).unwrap();

    assert_eq!(report.synced, 1);
    assert!(target.join("cas-skill1").exists());
    assert!(!target.join("cas-skill2").exists());
}

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
fn test_sanitize_name() {
    assert_eq!(sanitize_name("My Skill"), "my-skill");
    assert_eq!(sanitize_name("skill_test"), "skill-test");
    assert_eq!(sanitize_name("Skill-123"), "skill-123");
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
fn test_sync_skill_with_context_fork() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let mut skill = create_test_skill("forked-skill", true);
    skill.context_mode = Some("fork".to_string());

    syncer.sync_skill(&skill).unwrap();

    let content = fs::read_to_string(target.join("cas-forked-skill/SKILL.md")).unwrap();
    assert!(content.contains("context: fork"));
}


#[test]
fn test_sync_skill_with_allowed_tools() {
    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let mut skill = create_test_skill("restricted-skill", true);
    skill.allowed_tools = vec!["Read".to_string(), "Grep".to_string(), "Glob".to_string()];

    syncer.sync_skill(&skill).unwrap();

    let content = fs::read_to_string(target.join("cas-restricted-skill/SKILL.md")).unwrap();
    assert!(content.contains("allowed-tools:"));
    assert!(content.contains("  - Read"));
    assert!(content.contains("  - Grep"));
    assert!(content.contains("  - Glob"));
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


#[test]
fn test_sync_skill_with_hooks() {
    use cas_types::{SkillHookConfig, SkillHookEntry, SkillHooks};

    let temp = TempDir::new().unwrap();
    let target = temp.path().join(".claude/skills");
    let syncer = SkillSyncer::new(target.clone());

    let mut skill = create_test_skill("hooked-skill", true);
    skill.hooks = Some(SkillHooks {
        pre_tool_use: None,
        post_tool_use: Some(vec![SkillHookConfig {
            matcher: Some("Write|Edit".to_string()),
            hooks: vec![SkillHookEntry {
                hook_type: "command".to_string(),
                command: "cas hook PostToolUse".to_string(),
                timeout: Some(5000),
            }],
        }]),
        stop: Some(vec![SkillHookConfig {
            matcher: None,
            hooks: vec![SkillHookEntry::new("cas hook Stop")],
        }]),
    });

    syncer.sync_skill(&skill).unwrap();

    let content = fs::read_to_string(target.join("cas-hooked-skill/SKILL.md")).unwrap();
    assert!(content.contains("hooks:"), "Missing hooks section");
    assert!(
        content.contains("PostToolUse:"),
        "Missing PostToolUse section"
    );
    assert!(
        content.contains("matcher: Write|Edit") || content.contains("matcher: \"Write|Edit\""),
        "Missing matcher - content:\n{content}"
    );
    assert!(
        content.contains("command: cas hook PostToolUse"),
        "Missing command"
    );
    assert!(content.contains("timeout: 5000"), "Missing timeout");
    assert!(content.contains("Stop:"), "Missing Stop section");
    assert!(
        content.contains("command: cas hook Stop"),
        "Missing Stop command"
    );
}
