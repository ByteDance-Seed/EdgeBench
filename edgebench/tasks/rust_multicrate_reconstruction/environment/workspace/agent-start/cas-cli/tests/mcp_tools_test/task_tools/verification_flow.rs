use crate::support::*;
use cas::mcp::tools::*;
use cas::store::{open_agent_store, open_task_store, open_verification_store, open_worktree_store};
use cas::types::{Verification, VerificationType, Worktree};
use rmcp::handler::server::wrapper::Parameters;

#[tokio::test]
async fn test_task_close_blocked_without_verification() {
    let (temp, service) = setup_cas();
    let cas_dir = temp.path().join(".cas");

    // Initialize verification store
    let verification_store = open_verification_store(&cas_dir).unwrap();

    // Create task
    let req = TaskCreateRequest {
        title: "Task requiring verification".to_string(),
        description: None,
        priority: 2,
        task_type: "task".to_string(),
        labels: None,
        notes: None,
        blocked_by: None,
        design: None,
        acceptance_criteria: None,
        external_ref: None,
        assignee: None,
        demo_statement: None,
        epic: None,
    };

    let result = service
        .cas_task_create(Parameters(req))
        .await
        .expect("task_create should succeed");

    let text = extract_text(result);
    let id = extract_task_id(&text).expect("should have task ID");

    // Start task
    let start_req = IdRequest { id: id.to_string() };
    let _ = service
        .cas_task_start(Parameters(start_req))
        .await
        .expect("task_start should succeed");

    // Try to close task without verification - should be blocked
    let close_req = TaskCloseRequest {
        id: id.to_string(),
        reason: Some("Completed".to_string()),
    };
    let result = service
        .cas_task_close(Parameters(close_req))
        .await
        .expect("task_close should return a result");

    let text = extract_text(result);
    assert!(
        text.contains("VERIFICATION REQUIRED"),
        "Close should be blocked without verification: {text}"
    );

    // Verify no verification record exists
    let latest = verification_store.get_latest_for_task(id).unwrap();
    assert!(latest.is_none(), "No verification should exist yet");
}

#[tokio::test]
async fn test_task_close_sets_assignee_for_worktree_merge_jail() {
    let (temp, service) = setup_cas();
    let cas_dir = temp.path().join(".cas");

    std::fs::write(
        cas_dir.join("config.toml"),
        r#"[verification]
enabled = false

[worktrees]
enabled = true
require_merge_on_epic_close = true
"#,
    )
    .expect("should write config");

    let req = TaskCreateRequest {
        title: "Task with worktree".to_string(),
        description: None,
        priority: 2,
        task_type: "task".to_string(),
        labels: None,
        notes: None,
        blocked_by: None,
        design: None,
        acceptance_criteria: None,
        external_ref: None,
        assignee: None,
        demo_statement: None,
        epic: None,
    };

    let result = service
        .cas_task_create(Parameters(req))
        .await
        .expect("task_create should succeed");

    let text = extract_text(result);
    let id = extract_task_id(&text).expect("should have task ID");

    let worktree_store = open_worktree_store(&cas_dir).expect("open worktree store");
    worktree_store.init().expect("init worktree store");
    let worktree_id = Worktree::generate_id();
    let worktree = Worktree::new(
        worktree_id.clone(),
        "cas/test-worktree".to_string(),
        "main".to_string(),
        temp.path().join("worktree"),
    );
    worktree_store.add(&worktree).expect("should add worktree");

    let task_store = open_task_store(&cas_dir).expect("open task store");
    let mut task = task_store.get(id).expect("task should exist");
    task.worktree_id = Some(worktree_id);
    task_store.update(&task).expect("should update task");

    let close_req = TaskCloseRequest {
        id: task.id.clone(),
        reason: Some("Done".to_string()),
    };
    let result = service
        .cas_task_close(Parameters(close_req))
        .await
        .expect("task_close should return result");

    let text = extract_text(result);
    assert!(
        text.contains("WORKTREE MERGE REQUIRED"),
        "Close should be blocked for merge: {text}"
    );

    let task = task_store.get(&task.id).expect("task should exist");
    assert!(
        task.pending_worktree_merge,
        "pending_worktree_merge should be set"
    );

    let agent_store = open_agent_store(&cas_dir).expect("open agent store");
    let agent_id = agent_store
        .list(None)
        .expect("list agents")
        .first()
        .map(|a| a.id.clone())
        .expect("agent should exist");
    assert_eq!(
        task.assignee.as_deref(),
        Some(agent_id.as_str()),
        "assignee should be set to current agent"
    );
}

#[tokio::test]
async fn test_epic_close_requires_epic_verification_type() {
    let (temp, service) = setup_cas();
    let cas_dir = temp.path().join(".cas");

    let verification_store = open_verification_store(&cas_dir).unwrap();

    // Create epic
    let req = TaskCreateRequest {
        title: "Epic requiring epic verification".to_string(),
        description: None,
        priority: 2,
        task_type: "epic".to_string(),
        labels: None,
        notes: None,
        blocked_by: None,
        design: None,
        acceptance_criteria: None,
        external_ref: None,
        assignee: None,
        demo_statement: None,
        epic: None,
    };

    let result = service
        .cas_task_create(Parameters(req))
        .await
        .expect("task_create should succeed");

    let text = extract_text(result);
    let id = extract_task_id(&text).expect("should have task ID");

    // Start epic
    let start_req = IdRequest { id: id.to_string() };
    let _ = service
        .cas_task_start(Parameters(start_req))
        .await
        .expect("task_start should succeed");

    // Close without verification should be blocked
    let close_req = TaskCloseRequest {
        id: id.to_string(),
        reason: Some("Completed".to_string()),
    };
    let result = service
        .cas_task_close(Parameters(close_req))
        .await
        .expect("task_close should return a result");
    let text = extract_text(result);
    assert!(
        text.contains("VERIFICATION REQUIRED"),
        "Epic close should be blocked without verification: {text}"
    );

    // Add a task-level verification - should NOT unblock epic close
    let task_ver = Verification::approved(
        "ver-epic-task".to_string(),
        id.to_string(),
        "Task-level verification".to_string(),
    );
    verification_store.add(&task_ver).unwrap();

    let close_req = TaskCloseRequest {
        id: id.to_string(),
        reason: Some("Completed".to_string()),
    };
    let result = service
        .cas_task_close(Parameters(close_req))
        .await
        .expect("task_close should return a result");
    let text = extract_text(result);
    assert!(
        text.contains("VERIFICATION REQUIRED"),
        "Epic close should still be blocked with task-level verification: {text}"
    );

    // Add epic-level verification - should unblock
    let mut epic_ver = Verification::approved(
        "ver-epic-ok".to_string(),
        id.to_string(),
        "Epic verification passed".to_string(),
    );
    epic_ver.verification_type = VerificationType::Epic;
    verification_store.add(&epic_ver).unwrap();

    let close_req = TaskCloseRequest {
        id: id.to_string(),
        reason: Some("Completed".to_string()),
    };
    let result = service
        .cas_task_close(Parameters(close_req))
        .await
        .expect("task_close should succeed");
    let text = extract_text(result);
    assert!(
        text.contains("Closed") || text.contains("closed"),
        "Epic should close with epic verification: {text}"
    );
}


