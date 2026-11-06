#[test]
#[ignore = "task/verification CLI commands removed - tests need MCP fixtures"]
fn test_verification_add_cli() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let task_id = create_task(&temp, "Task for verification");

    // Add approved verification
    cas_cmd(&temp)
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "approved",
            "-m",
            "All checks passed",
        ])
        .assert()
        .success()
        .stdout(predicate::str::contains("Verification"))
        .stdout(predicate::str::contains("All checks passed"));
}

#[test]
#[ignore = "task/verification CLI commands removed - tests need MCP fixtures"]
fn test_verification_add_json() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let task_id = create_task(&temp, "JSON verification task");
    let ver_id = add_verification(&temp, &task_id, "approved", "All good");

    assert!(!ver_id.is_empty(), "Verification ID should be returned");
    assert!(
        ver_id.starts_with("ver-"),
        "Verification ID should start with ver-"
    );
}

#[test]
#[ignore = "task/verification CLI commands removed - tests need MCP fixtures"]
fn test_verification_list_cli() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let task_id = create_task(&temp, "List verification task");

    // Add multiple verifications
    add_verification(&temp, &task_id, "rejected", "First attempt failed");
    std::thread::sleep(std::time::Duration::from_millis(10));
    add_verification(&temp, &task_id, "approved", "Second attempt passed");

    // List verifications
    cas_cmd(&temp)
        .args(["verification", "list", &task_id])
        .assert()
        .success()
        .stdout(predicate::str::contains("VERIFICATIONS"))
        .stdout(predicate::str::contains("2 total"));
}

#[test]
#[ignore = "task/verification CLI commands removed - tests need MCP fixtures"]
fn test_verification_latest_cli() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let task_id = create_task(&temp, "Latest verification task");

    // Add verifications
    add_verification(&temp, &task_id, "rejected", "First failed");
    std::thread::sleep(std::time::Duration::from_millis(10));
    add_verification(&temp, &task_id, "approved", "Second passed");

    // Latest should be the approved one
    cas_cmd(&temp)
        .args(["verification", "latest", &task_id])
        .assert()
        .success()
        .stdout(predicate::str::contains("approved"))
        .stdout(predicate::str::contains("Second passed"));
}

#[test]
#[ignore = "task/verification CLI commands removed - tests need MCP fixtures"]
fn test_verification_latest_empty() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let task_id = create_task(&temp, "No verifications task");

    cas_cmd(&temp)
        .args(["verification", "latest", &task_id])
        .assert()
        .success()
        .stdout(predicate::str::contains("No verifications found"));
}

#[test]
#[ignore = "task/verification CLI commands removed - tests need MCP fixtures"]
fn test_verification_with_metadata() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let task_id = create_task(&temp, "Metadata task");

    let output = cas_cmd(&temp)
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "approved",
            "-m",
            "Thorough review",
            "--confidence",
            "0.95",
            "--duration-ms",
            "1500",
            "--files",
            "src/main.rs,src/lib.rs,tests/test.rs",
            "--json",
        ])
        .output()
        .unwrap();

    let stdout = String::from_utf8_lossy(&output.stdout);
    let json: serde_json::Value = serde_json::from_str(&stdout).unwrap();
    let ver_id = json["id"].as_str().unwrap();

    // Show should display metadata
    cas_cmd(&temp)
        .args(["verification", "show", ver_id])
        .assert()
        .success()
        .stdout(predicate::str::contains("95%")) // confidence
        .stdout(predicate::str::contains("1500ms")) // duration
        .stdout(predicate::str::contains("Files Reviewed"))
        .stdout(predicate::str::contains("src/main.rs"));
}

#[test]
#[ignore = "task/verification CLI commands removed - tests need MCP fixtures"]
fn test_verification_statuses() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Test all status types
    for status in &["approved", "rejected", "error", "skipped"] {
        let task_id = create_task(&temp, &format!("{status} status task"));
        add_verification(&temp, &task_id, status, &format!("Status: {status}"));

        cas_cmd(&temp)
            .args(["verification", "latest", &task_id])
            .assert()
            .success()
            .stdout(predicate::str::contains(*status));
    }
}

#[test]
fn test_verification_config_toggle() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    // Enable verification
    enable_verification(&temp);

    cas_cmd(&temp)
        .args(["config", "get", "verification.enabled"])
        .assert()
        .success()
        .stdout(predicate::str::contains("true"));

    // Disable verification
    cas_cmd(&temp)
        .args(["config", "set", "verification.enabled", "false"])
        .assert()
        .success();

    cas_cmd(&temp)
        .args(["config", "get", "verification.enabled"])
        .assert()
        .success()
        .stdout(predicate::str::contains("false"));
}

#[test]
fn test_verification_show_invalid_id() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    cas_cmd(&temp)
        .args(["verification", "show", "ver-nonexistent"])
        .assert()
        .failure();
}

#[test]
#[ignore = "task/verification CLI commands removed - tests need MCP fixtures"]
fn test_verification_add_invalid_status() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let task_id = create_task(&temp, "Invalid status task");

    cas_cmd(&temp)
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "invalid_status",
            "-m",
            "Should fail",
        ])
        .assert()
        .failure()
        .stderr(predicate::str::contains("Invalid status"));
}
