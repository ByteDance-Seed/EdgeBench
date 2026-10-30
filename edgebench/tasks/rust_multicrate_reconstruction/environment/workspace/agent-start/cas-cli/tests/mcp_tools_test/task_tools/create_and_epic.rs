use crate::support::*;
use cas::mcp::tools::*;
use rmcp::handler::server::wrapper::Parameters;
use rusqlite::Connection;



/// Test that epic creation creates a branch, not a worktree
///
/// This is a regression test for the bug where supervisors were getting
/// worktrees when creating epics. Epics should only get branches.
#[tokio::test]
async fn test_epic_creates_branch_not_worktree() {
    use std::process::Command;

    let (temp, service) = setup_cas();

    // Initialize git repo (required for branch creation)
    Command::new("git")
        .args(["init"])
        .current_dir(temp.path())
        .output()
        .expect("Failed to init git");

    Command::new("git")
        .args(["config", "user.email", "test@test.com"])
        .current_dir(temp.path())
        .output()
        .unwrap();

    Command::new("git")
        .args(["config", "user.name", "Test"])
        .current_dir(temp.path())
        .output()
        .unwrap();

    // Create initial commit (required for branch creation)
    std::fs::write(temp.path().join("README.md"), "# Test").unwrap();
    Command::new("git")
        .args(["add", "."])
        .current_dir(temp.path())
        .output()
        .unwrap();
    Command::new("git")
        .args(["commit", "-m", "Initial commit"])
        .current_dir(temp.path())
        .output()
        .unwrap();

    // Create epic task
    let req = TaskCreateRequest {
        title: "Add User Authentication".to_string(),
        description: Some("Epic for auth feature".to_string()),
        priority: 1,
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

    let create_text = extract_text(result);
    let epic_id = extract_task_id(&create_text).expect("should have epic ID");
    let expected_branch = format!("epic/add-user-authentication-{epic_id}");

    // Should contain branch info, not worktree info
    assert!(
        create_text.contains("Epic branch created") || create_text.contains("epic/"),
        "Epic should create branch on create: {create_text}"
    );
    assert!(
        !create_text.contains("Worktree created"),
        "Epic should NOT create worktree: {create_text}"
    );

    // Start the epic (which triggers branch creation)
    let start_req = IdRequest {
        id: epic_id.to_string(),
    };
    let start_result = service
        .cas_task_start(Parameters(start_req))
        .await
        .expect("task_start should succeed");

    let text = extract_text(start_result);
    println!("Epic start output: {text}");

    // Start should not create a worktree for epics
    assert!(
        !text.contains("Worktree created"),
        "Epic should NOT create worktree: {text}"
    );

    // Verify git branch was created
    let branch_list = Command::new("git")
        .args(["branch", "--list", "epic/*"])
        .current_dir(temp.path())
        .output()
        .expect("Failed to list branches");

    let branches = String::from_utf8_lossy(&branch_list.stdout);
    println!("Git branches: {branches}");
    assert!(
        branches.contains(&expected_branch),
        "Expected {expected_branch} branch, got: {branches}"
    );

    // Verify no worktree directory was created
    let worktree_dir = temp.path().parent().unwrap().join(format!(
        "{}-worktrees",
        temp.path().file_name().unwrap().to_str().unwrap()
    ));
    assert!(
        !worktree_dir.exists(),
        "Worktree directory should not exist"
    );
}

#[tokio::test]
async fn test_task_create_invalid_epic_does_not_persist_task() {
    let (_temp, service) = setup_cas();

    let req = TaskCreateRequest {
        title: "Should fail atomic create".to_string(),
        description: Some("invalid epic should not leave orphan task".to_string()),
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
        epic: Some("cas-does-not-exist".to_string()),
    };

    let result = service.cas_task_create(Parameters(req)).await;
    assert!(result.is_err(), "Create should fail for invalid epic");

    let list_req = TaskListRequest {
        scope: "all".to_string(),
        limit: Some(20),
        status: None,
        task_type: None,
        label: None,
        assignee: None,
        epic: None,
        sort: None,
        sort_order: None,
    };
    let list_result = service
        .cas_task_list(Parameters(list_req))
        .await
        .expect("task_list should succeed");
    let text = extract_text(list_result);
    assert!(
        text.contains("No tasks found matching filters"),
        "Task create should be atomic; unexpected task list output: {text}"
    );
}

