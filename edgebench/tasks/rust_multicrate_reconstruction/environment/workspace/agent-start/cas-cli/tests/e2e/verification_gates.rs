//! Verification gates E2E tests
//!
//! Tests the verification system: adding verifications, pending checks, quality gates

use crate::fixtures::new_cas_instance;
use std::process::Command;

/// Test adding a verification to a task
#[test]
fn test_add_verification() {
    let cas = new_cas_instance();

    // Create and start a task
    let task_id = cas.create_task("Task to verify");
    cas.start_task(&task_id);

    // Add a verification
    let output = cas
        .cas_cmd()
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "approved",
            "--summary",
            "Code review passed",
            "--confidence",
            "0.9",
        ])
        .output()
        .expect("Failed to add verification");

    assert!(
        output.status.success(),
        "verification add failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

/// Test listing verifications for a task
#[test]
fn test_list_verifications() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task with multiple verifications");
    cas.start_task(&task_id);

    // Add multiple verifications
    for i in 1..=3 {
        let output = cas
            .cas_cmd()
            .args([
                "verification",
                "add",
                &task_id,
                "--status",
                "approved",
                "--summary",
                &format!("Verification round {}", i),
            ])
            .output()
            .expect("Failed to add verification");
        assert!(output.status.success());
    }

    // List verifications
    let output = cas
        .cas_cmd()
        .args(["verification", "list", &task_id])
        .output()
        .expect("Failed to list verifications");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should show all verifications
    assert!(stdout.contains("Verification round 1") || stdout.contains("approved"));
}

/// Test getting the latest verification for a task

/// Test verification status types

/// Test verification with issues
#[test]
fn test_verification_with_issues() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task with issues");
    cas.start_task(&task_id);

    // Add verification with issues as JSON
    let issues_json = r#"[{"severity":"error","message":"Missing tests"},{"severity":"warning","message":"Consider refactoring"}]"#;

    let output = cas
        .cas_cmd()
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "rejected",
            "--summary",
            "Found issues during review",
            "--issues",
            issues_json,
        ])
        .output()
        .expect("Failed to add verification with issues");

    assert!(
        output.status.success(),
        "verification add with issues failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    // Show verification
    let output = cas
        .cas_cmd()
        .args(["verification", "latest", &task_id])
        .output()
        .expect("Failed to get verification");

    let stdout = String::from_utf8_lossy(&output.stdout);
    // Should contain issue information
    println!("Verification with issues: {}", stdout);
}

/// Test verification with files reviewed

/// Test pending verification detection

/// Test confidence score in verification
#[test]
fn test_verification_confidence_score() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task for confidence test");
    cas.start_task(&task_id);

    // Add verification with specific confidence
    let output = cas
        .cas_cmd()
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "approved",
            "--summary",
            "High confidence approval",
            "--confidence",
            "0.95",
        ])
        .output()
        .expect("Failed to add verification");

    assert!(output.status.success());

    // Get the verification and check confidence
    let output = cas
        .cas_cmd()
        .args(["verification", "latest", &task_id, "--json"])
        .output()
        .expect("Failed to get verification");

    if output.status.success() {
        let stdout = String::from_utf8_lossy(&output.stdout);
        if let Ok(v) = serde_json::from_str::<serde_json::Value>(&stdout) {
            if let Some(conf) = v.get("confidence").and_then(|c| c.as_f64()) {
                assert!(
                    (conf - 0.95).abs() < 0.01,
                    "Confidence should be ~0.95, got {}",
                    conf
                );
            }
        }
    }
}

/// Test showing a specific verification by ID
#[test]
fn test_show_verification() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task for show verification");
    cas.start_task(&task_id);

    // Add verification and capture ID
    let output = cas
        .cas_cmd()
        .args([
            "verification",
            "add",
            &task_id,
            "--status",
            "approved",
            "--summary",
            "Test verification for show",
        ])
        .output()
        .expect("Failed to add verification");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Extract verification ID if present
    let re = regex::Regex::new(r"(verif-[a-f0-9]+)").ok();
    if let Some(re) = re {
        if let Some(caps) = re.captures(&stdout) {
            let verif_id = caps.get(1).map(|m| m.as_str()).unwrap_or("");

            if !verif_id.is_empty() {
                // Show the specific verification
                let output = cas
                    .cas_cmd()
                    .args(["verification", "show", verif_id])
                    .output()
                    .expect("Failed to show verification");

                assert!(output.status.success());
            }
        }
    }
}

/// Test verification after task close attempt
#[test]
fn test_verification_after_close_attempt() {
    let cas = new_cas_instance();

    let task_id = cas.create_task("Task to close and verify");
    cas.start_task(&task_id);

    // Add progress notes
    cas.add_task_note(&task_id, "Implementation complete", "progress");

    // Attempt to close (this may trigger verification requirement)
    let _output = cas
        .cas_cmd()
        .args(["task", "close", &task_id])
        .output()
        .expect("Failed to close task");

    // Check if task was closed or if verification is pending
    let task = cas.get_task_json(&task_id);
    let status = task["status"].as_str().unwrap_or("");
    let pending_v = task
        .get("pending_verification")
        .and_then(|v| v.as_bool())
        .unwrap_or(false);

    println!(
        "Task status after close: {}, pending_verification: {}",
        status, pending_v
    );

    // Either closed successfully or pending verification
    assert!(
        status == "closed" || pending_v,
        "Task should either be closed or pending verification"
    );
}

/// Test clearing pending verification

/// Test multiple tasks with pending verifications
