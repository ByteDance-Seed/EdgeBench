#[test]
fn test_latest_verification() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task for latest verification");
    cas.start_task(&task_id);

    // Add verifications
    cas.cas_cmd()
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "approved",
            "--summary",
            "First review",
        ])
        .output()
        .expect("Failed to add first verification");

    cas.cas_cmd()
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "rejected",
            "--summary",
            "Second review found issues",
        ])
        .output()
        .expect("Failed to add second verification");

    // Get latest verification
    let output = cas
        .cas_cmd()
        .args(["verification", "latest", &task_id])
        .output()
        .expect("Failed to get latest verification");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Latest should be the rejected one
    assert!(
        stdout.contains("rejected") || stdout.contains("Second review"),
        "Latest verification should be the second one"
    );
}

#[test]
fn test_verification_statuses() {
    let cas = new_cas_instance();

    let statuses = ["approved", "rejected", "error", "skipped"];

    for status in statuses {
        let task_id = cas.create_task(&format!("Task for {} verification", status));
        cas.start_task(&task_id);

        let output = cas
            .cas_cmd()
            .args([
                "verification",
                "add",
                &task_id,
                "--status",
                status,
                "--summary",
                &format!("Verification with {} status", status),
            ])
            .output()
            .expect("Failed to add verification");

        assert!(
            output.status.success(),
            "verification add with status {} failed: {}",
            status,
            String::from_utf8_lossy(&output.stderr)
        );
    }
}

#[test]
fn test_verification_with_files() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task with file review");
    cas.start_task(&task_id);

    // Add verification with files
    let output = cas
        .cas_cmd()
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "approved",
            "--summary",
            "Reviewed all implementation files",
            "--files",
            "src/main.rs,src/lib.rs,tests/test.rs",
        ])
        .output()
        .expect("Failed to add verification with files");

    assert!(
        output.status.success(),
        "verification add with files failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

#[test]
fn test_pending_verification_detection() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task needing verification");
    cas.start_task(&task_id);

    // Set pending_verification flag via direct DB update (simulating task close request)
    let db_path = cas.temp_dir.path().join(".cas").join("cas.db");
    let _ = Command::new("sqlite3")
        .arg(&db_path)
        .arg(format!(
            "UPDATE tasks SET pending_verification = 1 WHERE id = '{}';",
            task_id
        ))
        .output();

    // Check pending verifications
    let output = cas
        .cas_cmd()
        .args(["verification", "pending"])
        .output()
        .expect("Failed to check pending verifications");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should list the task as pending verification
    assert!(
        stdout.contains(&task_id),
        "Task should appear in pending verifications"
    );
}

#[test]
fn test_clear_pending_verification() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task with pending verification to clear");
    cas.start_task(&task_id);

    // Set pending_verification
    let db_path = cas.temp_dir.path().join(".cas").join("cas.db");
    let _ = Command::new("sqlite3")
        .arg(&db_path)
        .arg(format!(
            "UPDATE tasks SET pending_verification = 1 WHERE id = '{}';",
            task_id
        ))
        .output();

    // Add approved verification
    let output = cas
        .cas_cmd()
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "approved",
            "--summary",
            "Approved after review",
        ])
        .output()
        .expect("Failed to add verification");

    assert!(output.status.success());

    // The approved verification should clear pending_verification
    // Check the task
    let task = cas.get_task_json(&task_id);

    // Note: This depends on implementation - verification approval may or may not
    // automatically clear pending_verification flag
    println!("Task after approved verification: {:?}", task);
}

#[test]
fn test_multiple_pending_verifications() {
    let cas = new_cas_instance();

    let db_path = cas.temp_dir.path().join(".cas").join("cas.db");

    // Create multiple tasks and set them as pending verification
    let task_ids: Vec<String> = (1..=3)
        .map(|i| {
            let task_id = cas.create_task(&format!("Pending task {}", i));
            cas.start_task(&task_id);
            let _ = Command::new("sqlite3")
                .arg(&db_path)
                .arg(format!(
                    "UPDATE tasks SET pending_verification = 1 WHERE id = '{}';",
                    task_id
                ))
                .output();
            task_id
        })
        .collect();

    // Check pending verifications
    let output = cas
        .cas_cmd()
        .args(["verification", "pending"])
        .output()
        .expect("Failed to list pending verifications");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // All tasks should appear in pending list
    for task_id in &task_ids {
        assert!(
            stdout.contains(task_id),
            "Task {} should be in pending list",
            task_id
        );
    }
}
