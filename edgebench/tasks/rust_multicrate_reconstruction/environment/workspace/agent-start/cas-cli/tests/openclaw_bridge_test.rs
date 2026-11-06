//! Integration tests for the CLI bridge used by external orchestrators (e.g., OpenClaw).

use assert_cmd::Command;
use tempfile::TempDir;

use cas::store::open_prompt_queue_store;
use cas::ui::factory::{SessionManager, create_metadata};

fn cas_cmd(project_dir: &std::path::Path, home: &std::path::Path) -> Command { todo!() }

#[test]
fn openclaw_cli_bridge_smoke() {
    let home = TempDir::new().unwrap();
    let project = TempDir::new().unwrap();

    // Ensure in-process helpers (SessionManager/create_metadata) use the temp HOME too.
    unsafe { std::env::set_var("HOME", home.path()) };

    // Initialize CAS in the project (creates .cas/)
    cas_cmd(project.path(), home.path())
        .args(["init", "--yes"])
        .assert()
        .success();

    // Create a fake running session metadata entry under this HOME
    let session_name = "factory-test-openclaw";
    let workers = vec!["worker-a".to_string(), "worker-b".to_string()];
    let metadata = create_metadata(
        session_name,
        std::process::id(), // is_running=true
        "supervisor-x",
        &workers,
        None,
        Some(project.path().to_string_lossy().as_ref()),
        None,
    );
    let manager = SessionManager::new();
    manager.save_metadata(&metadata).unwrap();

    // Make it attachable by creating the socket file path referenced in metadata.
    let sock_path = std::path::Path::new(&metadata.socket_path);
    if let Some(parent) = sock_path.parent() {
        std::fs::create_dir_all(parent).unwrap();
    }
    std::fs::write(sock_path, b"").unwrap();

    // `cas list --json` should include schema_version and our session.
    let out = cas_cmd(project.path(), home.path())
        .args(["--json", "list", "--name", session_name])
        .output()
        .unwrap();
    assert!(out.status.success());
    let v: serde_json::Value = serde_json::from_slice(&out.stdout).unwrap();
    assert_eq!(v["schema_version"], 1);
    assert_eq!(v["sessions"][0]["name"], session_name);

    // `cas factory targets --json` should resolve targets.
    let out = cas_cmd(project.path(), home.path())
        .args(["factory", "targets", "--json", "--session", session_name])
        .output()
        .unwrap();
    assert!(out.status.success());
    let v: serde_json::Value = serde_json::from_slice(&out.stdout).unwrap();
    assert_eq!(v["schema_version"], 1);
    assert_eq!(v["supervisor"], "supervisor-x");
    assert_eq!(v["workers"].as_array().unwrap().len(), 2);

    // Enqueue a message via the bridge.
    let out = cas_cmd(project.path(), home.path())
        .args([
            "factory",
            "message",
            "--json",
            "--session",
            session_name,
            "--target",
            "all_workers",
            "--message",
            "hello",
            "--from",
            "openclaw-test",
        ])
        .output()
        .unwrap();
    assert!(out.status.success());
    let v: serde_json::Value = serde_json::from_slice(&out.stdout).unwrap();
    assert_eq!(v["schema_version"], 1);
    let message_id = v["message_id"].as_i64().unwrap();
    assert!(message_id > 0);

    // Ensure it's actually queued in the prompt queue store.
    let cas_root = project.path().join(".cas");
    let queue = open_prompt_queue_store(&cas_root).unwrap();
    assert!(queue.pending_count().unwrap() >= 1);

    // Aggregated status should surface the pending queue count.
    let out = cas_cmd(project.path(), home.path())
        .args(["factory", "status", "--json", "--session", session_name])
        .output()
        .unwrap();
    assert!(out.status.success());
    let v: serde_json::Value = serde_json::from_slice(&out.stdout).unwrap();
    assert_eq!(v["schema_version"], 1);
    assert!(v["prompt_queue_pending"].as_u64().unwrap() >= 1);
}
