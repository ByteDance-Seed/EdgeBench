#[test]
fn test_worktree_list() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    let output = cas
        .cas_cmd()
        .args(["worktree", "list"])
        .output()
        .expect("Failed to list worktrees");

    assert!(
        output.status.success(),
        "worktree list failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn test_worktree_status() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    let output = cas
        .cas_cmd()
        .args(["worktree", "status"])
        .output()
        .expect("Failed to get worktree status");

    assert!(
        output.status.success(),
        "worktree status failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn test_worktree_list_filters() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    // List with --all flag
    let output = cas
        .cas_cmd()
        .args(["worktree", "list", "--all"])
        .output()
        .expect("Failed to list worktrees with --all");

    assert!(output.status.success());

    // List with --orphans flag
    let output = cas
        .cas_cmd()
        .args(["worktree", "list", "--orphans"])
        .output()
        .expect("Failed to list orphan worktrees");

    assert!(output.status.success());
}

#[test]
fn test_pending_worktree_merge_flag() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    // Create an epic task
    let epic_id = cas.create_task_with_options("Epic for merge test", Some("epic"), None, false);
    cas.start_task(&epic_id);

    // Set pending_worktree_merge via direct DB update
    let db_path = cas.temp_dir.path().join(".cas").join("cas.db");
    let _ = Command::new("sqlite3")
        .arg(&db_path)
        .arg(format!(
            "UPDATE tasks SET pending_worktree_merge = 1 WHERE id = '{}';",
            epic_id
        ))
        .output();

    // Check task
    let task = cas.get_task_json(&epic_id);
    let pending_merge = task
        .get("pending_worktree_merge")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);

    println!("pending_worktree_merge: {}", pending_merge);
}

#[test]
fn test_worktree_list_json() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    let output = cas
        .cas_cmd()
        .args(["worktree", "list", "--json"])
        .output()
        .expect("Failed to list worktrees as JSON");

    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        // Try to parse as JSON
        if let Ok(json) = serde_json::from_str::<serde_json::Value>(&stdout) {
            println!("Worktree list JSON: {:?}", json);
        }
    }
}

#[test]
fn test_worktree_status_shows_branch() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    let output = cas
        .cas_cmd()
        .args(["worktree", "status"])
        .output()
        .expect("Failed to get worktree status");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should show current branch info (main or master)
    let has_branch_info =
        stdout.contains("main") || stdout.contains("master") || stdout.contains("branch");

    assert!(
        has_branch_info,
        "Worktree status should include branch info. Got: {}",
        stdout
    );

    println!("Worktree status: {}", stdout);
}

#[test]
fn test_worktree_cleanup_force() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    let output = cas
        .cas_cmd()
        .args(["worktree", "cleanup", "--force"])
        .output()
        .expect("Failed to run worktree cleanup with force");

    // Force cleanup should succeed
    assert!(
        output.status.success(),
        "worktree cleanup --force failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn test_worktree_merge() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    // Create an epic
    let epic_id = cas.create_task_with_options("Epic to merge", Some("epic"), None, false);

    // Try merge command (may require existing worktree)
    let output = cas.cas_cmd().args(["worktree", "merge", &epic_id]).output();

    match output {
        Ok(out) => {
            println!(
                "worktree merge stdout: {}",
                String::from_utf8_lossy(&out.stdout)
            );
            println!(
                "worktree merge stderr: {}",
                String::from_utf8_lossy(&out.stderr)
            );
        }
        Err(e) => {
            println!("worktree merge error (may be expected): {}", e);
        }
    }
}

#[test]
fn test_cli_epic_no_worktree_created() {
    let cas = new_cas_instance();
    init_git_repo(cas.temp_dir.path());

    // Create an epic via CLI
    let epic_id = cas.create_task_with_options("Add User Authentication", Some("epic"), None, true);

    // Get task JSON
    let task = cas.get_task_json(&epic_id);

    // worktree_id should be null (no worktree created)
    let worktree_id = task.get("worktree_id").and_then(|v| v.as_str());
    assert!(
        worktree_id.is_none() || worktree_id == Some(""),
        "worktree_id should be empty/null for CLI-created epics, got: {:?}",
        worktree_id
    );

    // Verify no worktree directory was created
    let worktree_path = cas.temp_dir.path().parent().unwrap().join(format!(
        "{}-worktrees",
        cas.temp_dir.path().file_name().unwrap().to_str().unwrap()
    ));
    let epic_worktree = worktree_path.join(&epic_id);
    assert!(
        !epic_worktree.exists(),
        "Worktree directory should not exist at: {}",
        epic_worktree.display()
    );

    println!("✓ CLI epic creation correctly does NOT create worktree");
}
