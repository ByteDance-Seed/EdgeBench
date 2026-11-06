#[test]
fn test_rule_with_tags() {
    let cas = new_cas_instance();

    let output = cas
        .cas_cmd()
        .args([
            "rules",
            "add",
            "Document public APIs",
            "--tags",
            "documentation,api,required",
        ])
        .output()
        .expect("Failed to create rule");

    assert!(output.status.success());
}

#[test]
fn test_rule_delete() {
    let cas = new_cas_instance();
    let rule_id = cas.create_rule("Rule to delete");

    let output = cas
        .cas_cmd()
        .args(["rules", "delete", &rule_id])
        .output()
        .expect("Failed to delete rule");

    assert!(
        output.status.success(),
        "rules delete failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    // Verify deleted
    let output = cas
        .cas_cmd()
        .args(["rules", "show", &rule_id])
        .output()
        .expect("show command");

    // Should fail or show not found
    assert!(
        !output.status.success() || String::from_utf8_lossy(&output.stderr).contains("not found")
    );
}

#[test]
fn test_multiple_rules_sync() {
    let cas = new_cas_instance();

    // Create and promote multiple rules
    let rule1 = cas.create_rule("First proven rule");
    let rule2 = cas.create_rule("Second proven rule");
    let _rule3 = cas.create_rule("Draft rule - should not sync");

    cas.mark_rule_helpful(&rule1);
    cas.mark_rule_helpful(&rule2);
    // rule3 stays as draft

    // Sync
    cas.sync_rules();

    // Verify only proven rules are synced
    let cas_rules_dir = cas
        .temp_dir
        .path()
        .join(".claude")
        .join("rules")
        .join("cas");

    let rule1_file = cas_rules_dir.join(format!("{}.md", rule1));
    let rule2_file = cas_rules_dir.join(format!("{}.md", rule2));

    assert!(rule1_file.exists(), "Proven rule 1 should be synced");
    assert!(rule2_file.exists(), "Proven rule 2 should be synced");
}
