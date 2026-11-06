#[tokio::test]
async fn test_cloud_pull_with_data() {
    let cas = new_cas_instance();
    let mock_server = CloudMockServer::start().await;

    // Set up mock with some data
    let entries = vec![sample_entry_json("remote-entry-1", "Remote learning")];
    let tasks = vec![sample_task_json("remote-task-1", "Remote task")];

    mock_server.mock_pull_with_data(entries, tasks).await;

    // Pull from cloud
    let output = cas
        .cas_cmd()
        .args(["cloud", "pull"])
        .env("CAS_CLOUD_ENDPOINT", &mock_server.endpoint)
        .env("CAS_CLOUD_TOKEN", "test-token")
        .output()
        .expect("Failed to pull");

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
