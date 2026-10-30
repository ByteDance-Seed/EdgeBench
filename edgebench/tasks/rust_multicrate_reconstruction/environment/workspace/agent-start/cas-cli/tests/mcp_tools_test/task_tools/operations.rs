use crate::support::*;
use cas::mcp::tools::*;
use rmcp::handler::server::wrapper::Parameters;
use rusqlite::Connection;

#[tokio::test]
async fn test_task_show() {
    let (_temp, service) = setup_cas();

    // Create task
    let req = TaskCreateRequest {
        title: "Show task".to_string(),
        description: Some("Detailed description".to_string()),
        priority: 1,
        task_type: "bug".to_string(),
        labels: Some("urgent".to_string()),
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

    // Show task
    let show_req = TaskShowRequest {
        id: id.to_string(),
        with_deps: true,
    };
    let result = service
        .cas_task_show(Parameters(show_req))
        .await
        .expect("task_show should succeed");

    let text = extract_text(result);
    assert!(text.contains("Show task"));
    assert!(text.contains("Detailed description") || text.contains("bug"));
}

#[tokio::test]
async fn test_task_update() {
    let (_temp, service) = setup_cas();

    // Create task
    let req = TaskCreateRequest {
        title: "Update task".to_string(),
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

    // Update task
    let update_req = TaskUpdateRequest {
        id: id.to_string(),
        title: Some("Updated title".to_string()),
        notes: Some("Added note".to_string()),
        priority: Some(1),
        labels: None,
        description: None,
        design: None,
        acceptance_criteria: None,
        demo_statement: None,
        external_ref: None,
        assignee: None,
        status: None,
        epic: None,
        epic_verification_owner: None,
    };

    let result = service
        .cas_task_update(Parameters(update_req))
        .await
        .expect("task_update should succeed");

    let text = extract_text(result);
    assert!(text.contains("Updated") || text.contains("updated"));
}


#[tokio::test]
async fn test_task_notes() {
    let (_temp, service) = setup_cas();

    // Create task
    let req = TaskCreateRequest {
        title: "Notes task".to_string(),
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

    // Add notes
    let notes_req = TaskNotesRequest {
        id: id.to_string(),
        note: "Making progress on implementation".to_string(),
        note_type: "progress".to_string(),
    };

    let result = service
        .cas_task_notes(Parameters(notes_req))
        .await
        .expect("task_notes should succeed");

    let text = extract_text(result);
    assert!(text.contains("Added note") || text.contains("note"));
}


#[tokio::test]
async fn test_task_ready() {
    let (_temp, service) = setup_cas();

    // Create ready tasks
    for i in 0..3 {
        let req = TaskCreateRequest {
            title: format!("Ready task {i}"),
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
        service
            .cas_task_create(Parameters(req))
            .await
            .expect("task_create should succeed");
    }

    // List ready tasks
    let ready_req = TaskReadyBlockedRequest {
        scope: "all".to_string(),
        limit: Some(10),
        sort: None,
        sort_order: None,
        epic: None,
    };
    let result = service
        .cas_task_ready(Parameters(ready_req))
        .await
        .expect("task_ready should succeed");

    let text = extract_text(result);
    assert!(text.contains("Ready task") || text.contains("ready") || text.contains("Tasks"));
}

#[tokio::test]
async fn test_task_delete() {
    let (_temp, service) = setup_cas();

    // Create task
    let req = TaskCreateRequest {
        title: "Delete task".to_string(),
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

    // Delete task
    let delete_req = IdRequest { id: id.to_string() };
    let result = service
        .cas_task_delete(Parameters(delete_req))
        .await
        .expect("task_delete should succeed");

    let text = extract_text(result);
    assert!(text.contains("Deleted"));
}



#[tokio::test]
async fn test_close_auto_unblocks_blocked_dependents() {
    let (_temp, service) = setup_cas();

    let blocker = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Auto unblock blocker".to_string(),
            description: None,
            priority: 1,
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
        }))
        .await
        .expect("blocker create should succeed");
    let blocker_id = extract_task_id(&extract_text(blocker))
        .expect("blocker id")
        .to_string();

    let blocked = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Auto unblock dependent".to_string(),
            description: None,
            priority: 2,
            task_type: "task".to_string(),
            labels: None,
            notes: None,
            blocked_by: Some(blocker_id.clone()),
            design: None,
            acceptance_criteria: None,
            external_ref: None,
            assignee: None,
            demo_statement: None,
            epic: None,
        }))
        .await
        .expect("blocked task create should succeed");
    let blocked_id = extract_task_id(&extract_text(blocked))
        .expect("blocked id")
        .to_string();

    let _ = service
        .cas_task_update(Parameters(TaskUpdateRequest {
            id: blocked_id.clone(),
            title: None,
            notes: None,
            priority: None,
            labels: None,
            description: None,
            design: None,
            acceptance_criteria: None,
            demo_statement: None,
            external_ref: None,
            assignee: None,
            status: Some("blocked".to_string()),
            epic: None,
            epic_verification_owner: None,
        }))
        .await
        .expect("blocked task update should succeed");

    let _ = service
        .cas_verification_add(Parameters(VerificationAddRequest {
            task_id: blocker_id.clone(),
            status: "approved".to_string(),
            summary: "approved for close".to_string(),
            confidence: Some(0.9),
            issues: None,
            files_reviewed: None,
            duration_ms: None,
            verification_type: None,
        }))
        .await
        .expect("verification add should succeed");

    let close = service
        .cas_task_close(Parameters(TaskCloseRequest {
            id: blocker_id,
            reason: Some("done".to_string()),
        }))
        .await
        .expect("task close should succeed");
    let close_text = extract_text(close);
    assert!(
        close_text.contains("Auto-unblocked"),
        "Close output should mention auto-unblocked tasks: {close_text}"
    );

    let show = service
        .cas_task_show(Parameters(TaskShowRequest {
            id: blocked_id,
            with_deps: false,
        }))
        .await
        .expect("task_show should succeed");
    let text = extract_text(show);
    assert!(
        text.contains("Status: Open"),
        "Blocked dependent should auto-transition to Open: {text}"
    );
}

#[tokio::test]
async fn test_task_update_invalid_epic_keeps_original_parent_dependency() {
    let (_temp, service) = setup_cas();

    let epic_1 = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Epic 1".to_string(),
            description: None,
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
        }))
        .await
        .expect("epic 1 create should succeed");
    let epic_1_id = extract_task_id(&extract_text(epic_1))
        .expect("epic 1 id")
        .to_string();

    let subtask = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Child task".to_string(),
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
            epic: Some(epic_1_id.clone()),
        }))
        .await
        .expect("subtask create should succeed");
    let subtask_id = extract_task_id(&extract_text(subtask))
        .expect("subtask id")
        .to_string();

    let update_result = service
        .cas_task_update(Parameters(TaskUpdateRequest {
            id: subtask_id.clone(),
            title: None,
            notes: None,
            priority: None,
            labels: None,
            description: None,
            design: None,
            acceptance_criteria: None,
            demo_statement: None,
            external_ref: None,
            assignee: None,
            status: None,
            epic: Some("cas-does-not-exist".to_string()),
            epic_verification_owner: None,
        }))
        .await;
    assert!(
        update_result.is_err(),
        "Invalid epic reassignment should fail"
    );

    let list_result = service
        .cas_task_list(Parameters(TaskListRequest {
            scope: "all".to_string(),
            limit: Some(20),
            status: None,
            task_type: None,
            label: None,
            assignee: None,
            epic: Some(epic_1_id),
            sort: None,
            sort_order: None,
        }))
        .await
        .expect("task list by epic should succeed");
    let text = extract_text(list_result);
    assert!(
        text.contains(&subtask_id),
        "Original ParentChild dependency should be preserved on failed reassignment: {text}"
    );
}

#[tokio::test]
async fn test_task_update_surfaces_epic_dependency_delete_failure() {
    let (temp, service) = setup_cas();

    let epic = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Epic".to_string(),
            description: None,
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
        }))
        .await
        .expect("epic create should succeed");
    let epic_id = extract_task_id(&extract_text(epic))
        .expect("epic id")
        .to_string();

    let subtask = service
        .cas_task_create(Parameters(TaskCreateRequest {
            title: "Subtask".to_string(),
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
            epic: Some(epic_id),
        }))
        .await
        .expect("subtask create should succeed");
    let subtask_id = extract_task_id(&extract_text(subtask))
        .expect("subtask id")
        .to_string();

    let db_path = temp.path().join(".cas").join("cas.db");
    let conn = Connection::open(&db_path).expect("open sqlite db");
    conn.execute(
        "CREATE TRIGGER fail_dependency_delete
         BEFORE DELETE ON dependencies
         BEGIN
             SELECT RAISE(FAIL, 'forced dependency delete failure');
         END;",
        [],
    )
    .expect("create delete failure trigger");

    let update_result = service
        .cas_task_update(Parameters(TaskUpdateRequest {
            id: subtask_id,
            title: None,
            notes: None,
            priority: None,
            labels: None,
            description: None,
            design: None,
            acceptance_criteria: None,
            demo_statement: None,
            external_ref: None,
            assignee: None,
            status: None,
            epic: Some(String::new()),
            epic_verification_owner: None,
        }))
        .await;
    assert!(
        update_result.is_err(),
        "Dependency delete failure should be returned to caller"
    );
}

#[tokio::test]
async fn test_subtask_start_auto_starts_epic() {
    let (_temp, service) = setup_cas();

    // Create an epic
    let epic_req = TaskCreateRequest {
        title: "Test Epic".to_string(),
        description: Some("An epic with subtasks".to_string()),
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
        .cas_task_create(Parameters(epic_req))
        .await
        .expect("epic create should succeed");

    let text = extract_text(result);
    let epic_id = extract_task_id(&text).expect("should have epic ID");

    // Verify epic is NOT in progress
    let show_req = TaskShowRequest {
        id: epic_id.to_string(),
        with_deps: false,
    };
    let result = service
        .cas_task_show(Parameters(show_req))
        .await
        .expect("task show should succeed");
    let text = extract_text(result);
    assert!(
        text.contains("open") || text.contains("Open"),
        "Epic should be open initially: {text}"
    );

    // Create a subtask linked to the epic
    let subtask_req = TaskCreateRequest {
        title: "Subtask 1".to_string(),
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
        epic: Some(epic_id.to_string()),
    };

    let result = service
        .cas_task_create(Parameters(subtask_req))
        .await
        .expect("subtask create should succeed");

    let text = extract_text(result);
    let subtask_id = extract_task_id(&text).expect("should have subtask ID");

    // Start the subtask - this should auto-start the epic
    let start_req = IdRequest {
        id: subtask_id.to_string(),
    };
    let result = service
        .cas_task_start(Parameters(start_req))
        .await
        .expect("subtask start should succeed");

    let text = extract_text(result);
    assert!(
        text.contains("EPIC OWNERSHIP"),
        "Should show epic ownership message: {text}"
    );
    assert!(text.contains(epic_id), "Should reference epic ID: {text}");
    assert!(
        text.contains("auto-started"),
        "Should indicate epic was auto-started: {text}"
    );
    // Workflow guidance should be included when starting a task
    assert!(
        text.contains("Workflow Guidance"),
        "Task start should include workflow guidance: {text}"
    );
    assert!(
        text.contains("mcp__cas__search"),
        "Workflow guidance should mention CAS search: {text}"
    );

    // Verify the epic is now in progress
    let show_req2 = TaskShowRequest {
        id: epic_id.to_string(),
        with_deps: false,
    };
    let result = service
        .cas_task_show(Parameters(show_req2))
        .await
        .expect("task show should succeed");
    let text = extract_text(result);
    assert!(
        text.contains("in_progress") || text.contains("InProgress") || text.contains("In Progress"),
        "Epic should be in progress after subtask start: {text}"
    );
}
