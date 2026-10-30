//! Task lifecycle e2e tests
//!
//! Tests the complete task workflow: create → start → notes → verify → close

use crate::fixtures::new_cas_instance;

/// Test complete task lifecycle from creation to closure
#[test]
fn test_task_full_lifecycle() {
    let cas = new_cas_instance();

    // 1. Create a task
    let task_id = cas.create_task("Implement new feature");

    // Verify task was created and is open
    let task = cas.get_task_json(&task_id);
    assert_eq!(task["status"], "open");
    assert_eq!(task["title"], "Implement new feature");

    // 2. Start the task
    cas.start_task(&task_id);

    let task = cas.get_task_json(&task_id);
    assert_eq!(task["status"], "in_progress");

    // 3. Add progress notes
    cas.add_task_note(&task_id, "Started implementation", "progress");
    cas.add_task_note(&task_id, "Found edge case to handle", "discovery");

    // Verify notes were added (notes is a string field)
    let task = cas.get_task_json(&task_id);
    let notes = task["notes"].as_str().expect("notes should be string");
    assert!(notes.contains("Started implementation"));
    assert!(notes.contains("Found edge case to handle"));

    // 4. Close the task
    cas.close_task(&task_id);

    let task = cas.get_task_json(&task_id);
    assert_eq!(task["status"], "closed");
}

/// Test creating tasks with different types
#[test]
fn test_task_types() {
    let cas = new_cas_instance();

    let test_cases = [
        ("task", "Regular task"),
        ("bug", "Fix critical bug"),
        ("feature", "Add new capability"),
        ("epic", "Major initiative"),
        ("chore", "Update dependencies"),
    ];

    for (task_type, title) in test_cases {
        let task_id = cas.create_task_with_options(title, Some(task_type), None, false);

        let task = cas.get_task_json(&task_id);
        assert_eq!(task["task_type"], task_type);
        assert_eq!(task["title"], title);
    }
}

/// Test task priorities

/// Test creating and starting a task in one command
#[test]
fn test_task_create_with_start() {
    let cas = new_cas_instance();
    let task_id = cas.create_task_with_options("Urgent task", None, Some(0), true);

    let task = cas.get_task_json(&task_id);
    assert_eq!(task["status"], "in_progress");
    assert_eq!(task["priority"], 0);
}

/// Test task list filtering by status

/// Test adding different note types to tasks
#[test]
fn test_task_note_types() {
    let cas = new_cas_instance();

    let test_cases = [
        ("progress", "Made good progress today"),
        ("blocker", "Waiting on API response"),
        ("decision", "Decided to use async approach"),
        ("discovery", "Found performance issue"),
        ("question", "Should we support older versions"),
    ];

    for (note_type, content) in test_cases {
        let task_id = cas.create_task(&format!("Task for {} note", note_type));
        cas.start_task(&task_id);

        cas.add_task_note(&task_id, content, note_type);

        let task = cas.get_task_json(&task_id);
        let notes = task["notes"].as_str().expect("notes should be string");

        // Verify the note content is present
        assert!(notes.contains(content), "Note should contain: {}", content);
        // Verify the note type indicator is present
        assert!(
            notes.to_uppercase().contains(&note_type.to_uppercase()),
            "Note should indicate type: {}",
            note_type
        );
    }
}

/// Test task ready command shows actionable tasks
#[test]
fn test_task_ready() {
    let cas = new_cas_instance();

    // Create open task (should be ready)
    let task1 = cas.create_task("Ready task 1");
    let _task2 = cas.create_task("Ready task 2");

    // Start one (no longer ready, it's in progress)
    cas.start_task(&task1);

    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to get ready tasks");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // In progress task should not appear in ready list
    assert!(!stdout.contains(&task1));
}

/// Test task show command output
#[test]
fn test_task_show_details() {
    let cas = new_cas_instance();
    let task_id = cas.create_task_with_options("Detailed task", Some("feature"), Some(1), true);

    cas.add_task_note(&task_id, "First note", "progress");

    let output = cas
        .cas_cmd()
        .args(["task", "show", &task_id])
        .output()
        .expect("Failed to show task");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    assert!(stdout.contains("Detailed task"));
    assert!(stdout.contains("feature"));
    assert!(stdout.contains("in_progress"));
}

/// Test task update command
#[test]
fn test_task_update() {
    let cas = new_cas_instance();
    let task_id = cas.create_task("Original title");

    // Update the task title
    let output = cas
        .cas_cmd()
        .args(["task", "update", &task_id, "--title", "Updated title"])
        .output()
        .expect("Failed to update task");

    assert!(output.status.success());

    let task = cas.get_task_json(&task_id);
    assert_eq!(task["title"], "Updated title");
}

/// Test task reopen after close
