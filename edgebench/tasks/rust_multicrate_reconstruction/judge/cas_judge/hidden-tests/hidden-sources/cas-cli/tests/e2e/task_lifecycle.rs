#[test]
fn test_task_priorities() {
    let cas = new_cas_instance();

    let test_cases = [
        (0u8, "Critical"),
        (1, "High"),
        (2, "Medium"),
        (3, "Low"),
        (4, "Backlog"),
    ];

    for (priority, title) in test_cases {
        let task_id = cas.create_task_with_options(
            &format!("{} priority task", title),
            None,
            Some(priority),
            false,
        );

        let task = cas.get_task_json(&task_id);
        assert_eq!(task["priority"], priority);
    }
}

#[test]
fn test_task_list_filtering() {
    let cas = new_cas_instance();

    // Create tasks in different states
    let task1 = cas.create_task("Open task");
    let task2 = cas.create_task("In progress task");
    let task3 = cas.create_task("Closed task");

    cas.start_task(&task2);
    cas.close_task(&task3);

    // List open tasks
    let output = cas
        .cas_cmd()
        .args(["task", "list", "--status", "open"])
        .output()
        .expect("Failed to list tasks");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains(&task1));
    assert!(!stdout.contains(&task2));
    assert!(!stdout.contains(&task3));

    // List in_progress tasks
    let output = cas
        .cas_cmd()
        .args(["task", "list", "--status", "in_progress"])
        .output()
        .expect("Failed to list tasks");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(!stdout.contains(&task1));
    assert!(stdout.contains(&task2));
    assert!(!stdout.contains(&task3));
}

#[test]
fn test_task_reopen() {
    let cas = new_cas_instance();
    let task_id = cas.create_task("Task to reopen");
    cas.close_task(&task_id);

    // Verify closed
    let task = cas.get_task_json(&task_id);
    assert_eq!(task["status"], "closed");

    // Reopen
    let output = cas
        .cas_cmd()
        .args(["task", "reopen", &task_id])
        .output()
        .expect("Failed to reopen task");

    assert!(output.status.success());

    let task = cas.get_task_json(&task_id);
    assert_eq!(task["status"], "open");
}
