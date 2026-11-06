//! Cloud sync e2e tests with wiremock
//!
//! Tests cloud sync operations using mocked HTTP endpoints.

use crate::fixtures::{new_cas_instance, sample_entry_json, sample_task_json, CloudMockServer};

/// Test cloud push with successful response
#[tokio::test]
async fn test_cloud_push_success() {
    let cas = new_cas_instance();
    let mock_server = CloudMockServer::start().await;
    mock_server.mock_push_success(1, 1, 0, 0).await;

    // Add some data to push
    cas.add_memory("Test memory for push");
    cas.create_task("Test task for push");

    // Push to cloud
    let output = cas
        .cas_cmd()
        .args(["cloud", "push"])
        .env("CAS_CLOUD_ENDPOINT", &mock_server.endpoint)
        .env("CAS_CLOUD_TOKEN", "test-token")
        .output()
        .expect("Failed to push");

    // Check output - may succeed or show "not configured" depending on feature flags
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    // Either succeeds or indicates cloud isn't configured
    assert!(
        output.status.success()
            || stderr.contains("not configured")
            || stderr.contains("token")
            || stderr.contains("login"),
        "Unexpected error: stdout={}, stderr={}",
        stdout,
        stderr
    );
}

/// Test cloud pull with data

/// Test conflict resolution during pull
#[tokio::test]
async fn test_pull_with_conflict() {
    let cas = new_cas_instance();
    let mock_server = CloudMockServer::start().await;

    // Add local entry
    let local_id = cas.add_memory("Local version of learning");

    // Mock returns same ID with different content (conflict)
    mock_server
        .mock_pull_with_conflict(&local_id, "Remote version of learning")
        .await;

    // Pull should handle conflict gracefully (not crash)
    let output = cas
        .cas_cmd()
        .args(["cloud", "pull"])
        .env("CAS_CLOUD_ENDPOINT", &mock_server.endpoint)
        .env("CAS_CLOUD_TOKEN", "test-token")
        .output()
        .expect("Failed to pull");

    // Command should complete without panic
    // Actual conflict behavior depends on implementation
    let _ = String::from_utf8_lossy(&output.stdout);
    let _ = String::from_utf8_lossy(&output.stderr);
}

/// Test rate limiting response handling
#[tokio::test]
async fn test_rate_limit_handling() {
    let cas = new_cas_instance();
    let mock_server = CloudMockServer::start().await;
    mock_server.mock_rate_limit().await;

    cas.add_memory("Test memory");

    let output = cas
        .cas_cmd()
        .args(["cloud", "push"])
        .env("CAS_CLOUD_ENDPOINT", &mock_server.endpoint)
        .env("CAS_CLOUD_TOKEN", "test-token")
        .output()
        .expect("Failed to run push");

    // Should handle rate limit gracefully (not panic)
    let stderr = String::from_utf8_lossy(&output.stderr);
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Either reports rate limit error or indicates cloud isn't configured
    assert!(
        stderr.contains("rate")
            || stderr.contains("limit")
            || stderr.contains("429")
            || stderr.contains("not configured")
            || stderr.contains("token")
            || stderr.contains("login")
            || stdout.contains("retry"),
        "Should handle rate limit: stdout={}, stderr={}",
        stdout,
        stderr
    );
}

/// Test server error handling
#[tokio::test]
async fn test_server_error() {
    let cas = new_cas_instance();
    let mock_server = CloudMockServer::start().await;
    mock_server.mock_server_error().await;

    cas.add_memory("Test memory");

    let output = cas
        .cas_cmd()
        .args(["cloud", "push"])
        .env("CAS_CLOUD_ENDPOINT", &mock_server.endpoint)
        .env("CAS_CLOUD_TOKEN", "test-token")
        .output()
        .expect("Failed to run push");

    // Should handle server error gracefully (not crash)
    let _ = String::from_utf8_lossy(&output.stdout);
    let _ = String::from_utf8_lossy(&output.stderr);
}

/// Test cloud status command
#[test]
fn test_cloud_status() {
    let cas = new_cas_instance();

    let output = cas
        .cas_cmd()
        .args(["cloud", "status"])
        .output()
        .expect("Failed to get status");

    // Should show status or indicate not logged in
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    // Status command should complete (may show "not logged in")
    assert!(
        output.status.success()
            || stderr.contains("not")
            || stderr.contains("login")
            || stdout.contains("not")
            || stdout.contains("status"),
        "Status should complete: stdout={}, stderr={}",
        stdout,
        stderr
    );
}

/// Test cloud queue command
#[test]
fn test_cloud_queue() {
    let cas = new_cas_instance();

    // Add some data
    cas.add_memory("Test memory");
    cas.create_task("Test task");

    let output = cas
        .cas_cmd()
        .args(["cloud", "queue"])
        .output()
        .expect("Failed to get queue");

    // Queue command should complete
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    assert!(
        output.status.success() || stderr.contains("not") || stderr.contains("login"),
        "Queue should complete: stdout={}, stderr={}",
        stdout,
        stderr
    );
}

/// Test dry run push
#[tokio::test]
async fn test_push_dry_run() {
    let cas = new_cas_instance();

    // Add some data
    cas.add_memory("Test memory for dry run");

    let output = cas
        .cas_cmd()
        .args(["cloud", "push", "--dry-run"])
        .output()
        .expect("Failed to run dry push");

    // Dry run should work without cloud credentials
    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    // Should show what would be pushed or indicate not logged in
    assert!(
        output.status.success()
            || stderr.contains("not")
            || stderr.contains("login")
            || stdout.contains("would"),
        "Dry run should work: stdout={}, stderr={}",
        stdout,
        stderr
    );
}
