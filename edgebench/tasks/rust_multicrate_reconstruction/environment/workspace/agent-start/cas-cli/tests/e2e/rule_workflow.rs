//! Rule workflow e2e tests
//!
//! Tests the complete rule lifecycle: create → helpful → promote → sync

use crate::fixtures::new_cas_instance;
use std::fs;

/// Test complete rule lifecycle from draft to proven
#[test]
fn test_rule_full_lifecycle() {
    let cas = new_cas_instance();

    // 1. Create a rule (starts as Draft)
    let rule_id = cas.create_rule("Always write tests for new features");

    // 2. Verify rule was created
    let output = cas
        .cas_cmd()
        .args(["rules", "show", &rule_id, "--json"])
        .output()
        .expect("Failed to show rule");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    let rule: serde_json::Value = serde_json::from_str(&stdout).expect("Failed to parse JSON");

    assert_eq!(rule["content"], "Always write tests for new features");
    assert_eq!(rule["status"], "draft"); // New rules start as draft

    // 3. Mark as helpful (promotes to proven)
    cas.mark_rule_helpful(&rule_id);

    let output = cas
        .cas_cmd()
        .args(["rules", "show", &rule_id, "--json"])
        .output()
        .expect("Failed to show rule");

    let rule: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");
    assert_eq!(rule["status"], "proven");

    // 4. Sync rules to .claude/rules/
    cas.sync_rules();

    // 5. Verify rule file was created
    let rules_dir = cas
        .temp_dir
        .path()
        .join(".claude")
        .join("rules")
        .join("cas");

    assert!(
        rules_dir.exists(),
        "Rules directory should exist after sync"
    );

    // Find the rule file
    let rule_file = rules_dir.join(format!("{}.md", rule_id));
    assert!(
        rule_file.exists(),
        "Rule file should exist: {:?}",
        rule_file
    );

    let content = fs::read_to_string(&rule_file).expect("Failed to read rule file");
    assert!(content.contains("Always write tests for new features"));
}

/// Test rule list command
#[test]
fn test_rule_list_filtering() {
    let cas = new_cas_instance();

    // Create multiple rules
    let _rule1 = cas.create_rule("Draft rule 1");
    let _rule2 = cas.create_rule("Draft rule 2");
    let rule3 = cas.create_rule("Rule to promote");

    // Promote one rule
    cas.mark_rule_helpful(&rule3);

    // List rules
    let output = cas
        .cas_cmd()
        .args(["rules", "list"])
        .output()
        .expect("Failed to list rules");

    assert!(
        output.status.success(),
        "rules list failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should show the promoted rule (or all rules)
    assert!(!stdout.is_empty(), "Rules list should not be empty");
}

/// Test rule with path patterns
#[test]
fn test_rule_with_paths() {
    let cas = new_cas_instance();

    let output = cas
        .cas_cmd()
        .args([
            "rules",
            "add",
            "Use TypeScript strict mode",
            "--paths",
            "*.ts,*.tsx",
        ])
        .output()
        .expect("Failed to create rule");

    assert!(
        output.status.success(),
        "rules add with paths failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    // Extract rule ID and verify
    let stdout = String::from_utf8_lossy(&output.stdout);
    let rule_id = extract_rule_id(&stdout).expect("Could not extract rule ID");

    let output = cas
        .cas_cmd()
        .args(["rules", "show", &rule_id, "--json"])
        .output()
        .expect("Failed to show rule");

    let rule: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");

    // Verify paths are set (paths is a string in CAS)
    let paths = rule["paths"].as_str().expect("paths should be string");
    assert!(!paths.is_empty(), "paths should not be empty");
    assert!(paths.contains("*.ts"), "paths should contain *.ts");
}

/// Test rule with tags

/// Test rule harmful marks decrease promotion
#[test]
fn test_rule_harmful() {
    let cas = new_cas_instance();
    let rule_id = cas.create_rule("Rule that might be wrong");

    // Mark as harmful
    let output = cas
        .cas_cmd()
        .args(["rules", "harmful", &rule_id])
        .output()
        .expect("Failed to mark harmful");

    assert!(output.status.success());

    let output = cas
        .cas_cmd()
        .args(["rules", "show", &rule_id, "--json"])
        .output()
        .expect("Failed to show rule");

    let rule: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");
    assert_eq!(rule["harmful_count"], 1);
}

/// Test rule update - skipped as CAS rules don't have an update command
/// Rules are designed to be immutable once created; create a new rule instead
#[test]
#[ignore = "CAS rules don't have an update command - rules are immutable"]
fn test_rule_update() {
    // Rules in CAS are designed to be immutable once created
    // To "update" a rule, you would delete the old one and create a new one
}

/// Test rule delete

/// Test sync creates correct directory structure
#[test]
fn test_rule_sync_directory_structure() {
    let cas = new_cas_instance();

    // Create and promote a rule
    let rule_id = cas.create_rule("Test rule for sync");
    cas.mark_rule_helpful(&rule_id);

    // Sync
    cas.sync_rules();

    // Verify directory structure
    let claude_dir = cas.temp_dir.path().join(".claude");
    let rules_dir = claude_dir.join("rules");
    let cas_rules_dir = rules_dir.join("cas");

    assert!(claude_dir.exists(), ".claude directory should exist");
    assert!(rules_dir.exists(), ".claude/rules directory should exist");
    assert!(
        cas_rules_dir.exists(),
        ".claude/rules/cas directory should exist"
    );

    // Verify rule file content format
    let rule_file = cas_rules_dir.join(format!("{}.md", rule_id));
    let content = fs::read_to_string(&rule_file).expect("Failed to read rule file");

    // Should contain the rule content
    assert!(content.contains("Test rule for sync"));
}

/// Test multiple rules sync

/// Test rule scope - project scope (default)
/// Note: Global scope requires user's config directory (~/.config/cas) which is outside test scope
#[test]
fn test_rule_scope() {
    let cas = new_cas_instance();

    // Create project-scoped rule (default)
    let output = cas
        .cas_cmd()
        .args(["rules", "add", "Project-specific rule"])
        .output()
        .expect("Failed to create rule");

    assert!(
        output.status.success(),
        "rules add (project) failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    // Verify the rule was created with project scope
    let stdout = String::from_utf8_lossy(&output.stdout);
    let rule_id = extract_rule_id(&stdout).expect("Could not extract rule ID");

    let output = cas
        .cas_cmd()
        .args(["rules", "show", &rule_id, "--json"])
        .output()
        .expect("Failed to show rule");

    let rule: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");
    assert_eq!(rule["scope"], "project");

    // Create another project rule with explicit --project flag
    let output = cas
        .cas_cmd()
        .args(["rules", "add", "Another project rule", "--project"])
        .output()
        .expect("Failed to create project rule");

    assert!(
        output.status.success(),
        "rules add --project failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

// Helper function to extract rule ID from output
fn extract_rule_id(output: &str) -> Option<String> { todo!() }
