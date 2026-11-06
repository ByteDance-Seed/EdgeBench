#[test]
fn test_add_dependency() {
    let cas = new_cas_instance();

    let task_a = cas.create_task("Task A - depends on B");
    let task_b = cas.create_task("Task B - blocker");

    // Add dependency: A is blocked by B
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "dep",
            "add",
            &task_a,
            &task_b,
            "--dep-type",
            "blocks",
        ])
        .output()
        .expect("Failed to add dependency");

    assert!(
        output.status.success(),
        "dep add failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    // Verify the dependency exists via dep tree
    let output = cas
        .cas_cmd()
        .args(["task", "dep", "tree", &task_a])
        .output()
        .expect("Failed to show dependency tree");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Tree should show the blocking relationship
    assert!(
        stdout.contains(&task_b) || stdout.contains("Task B"),
        "Should show task B in dependency tree"
    );
}

#[test]
fn test_multiple_blockers() {
    let cas = new_cas_instance();

    let task_main = cas.create_task("Main task - needs multiple dependencies");
    let blocker1 = cas.create_task("Blocker 1");
    let blocker2 = cas.create_task("Blocker 2");
    let blocker3 = cas.create_task("Blocker 3");

    // Main task is blocked by all three
    for blocker in [&blocker1, &blocker2, &blocker3] {
        let output = cas
            .cas_cmd()
            .args([
                "task",
                "dep",
                "add",
                &task_main,
                blocker,
                "--dep-type",
                "blocks",
            ])
            .output()
            .expect("Failed to add dependency");
        assert!(output.status.success());
    }

    // Main task should NOT be ready
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        !stdout.contains(&task_main),
        "Task should be blocked by multiple blockers"
    );

    // Close blocker1 - still blocked by 2 and 3
    cas.close_task(&blocker1);
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(!stdout.contains(&task_main), "Task should still be blocked");

    // Close blocker2 - still blocked by 3
    cas.close_task(&blocker2);
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(!stdout.contains(&task_main), "Task should still be blocked");

    // Close blocker3 - now unblocked
    cas.close_task(&blocker3);
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        stdout.contains(&task_main),
        "Task should be ready after all blockers closed"
    );
}
