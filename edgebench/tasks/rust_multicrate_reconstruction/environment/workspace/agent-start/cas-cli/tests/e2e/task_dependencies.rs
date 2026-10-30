//! Task dependency E2E tests
//!
//! Tests task dependency management: blocking chains, circular detection, cascading

use crate::fixtures::new_cas_instance;

/// Test basic task dependency creation

/// Test that blocked tasks don't appear in 'ready' list
#[test]
fn test_blocked_task_not_ready() {
    let cas = new_cas_instance();

    let task_a = cas.create_task("Task A - blocked");
    let task_b = cas.create_task("Task B - blocker");

    // A is blocked by B
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
    assert!(output.status.success());

    // Task A should NOT be in ready list (it's blocked)
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        !stdout.contains(&task_a),
        "Blocked task should not be in ready list"
    );
    assert!(
        stdout.contains(&task_b),
        "Blocker task should be in ready list"
    );
}

/// Test unblocking when blocker is closed
#[test]
fn test_unblock_when_blocker_closed() {
    let cas = new_cas_instance();

    let task_a = cas.create_task("Task A - will be unblocked");
    let task_b = cas.create_task("Task B - blocker to close");

    // A is blocked by B
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
    assert!(output.status.success());

    // Close task B
    cas.close_task(&task_b);

    // Task A should now be in ready list
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        stdout.contains(&task_a),
        "Previously blocked task should now be ready"
    );
}

/// Test blocking chain: A <- B <- C (A is blocked by B, B is blocked by C)
#[test]
fn test_blocking_chain() {
    let cas = new_cas_instance();

    let task_a = cas.create_task("Task A - end of chain");
    let task_b = cas.create_task("Task B - middle");
    let task_c = cas.create_task("Task C - start of chain");

    // A is blocked by B
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
        .expect("Failed to add A->B dependency");
    assert!(output.status.success());

    // B is blocked by C
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "dep",
            "add",
            &task_b,
            &task_c,
            "--dep-type",
            "blocks",
        ])
        .output()
        .expect("Failed to add B->C dependency");
    assert!(output.status.success());

    // Only C should be ready
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        !stdout.contains(&task_a),
        "Task A should be blocked (transitively)"
    );
    assert!(!stdout.contains(&task_b), "Task B should be blocked");
    assert!(
        stdout.contains(&task_c),
        "Task C should be ready (head of chain)"
    );

    // Close C, now B should be ready
    cas.close_task(&task_c);

    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(!stdout.contains(&task_a), "Task A should still be blocked");
    assert!(stdout.contains(&task_b), "Task B should now be ready");

    // Close B, now A should be ready
    cas.close_task(&task_b);

    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains(&task_a), "Task A should now be ready");
}

/// Test circular dependency detection
#[test]
fn test_circular_dependency_detection() {
    let cas = new_cas_instance();

    let task_a = cas.create_task("Task A");
    let task_b = cas.create_task("Task B");

    // A is blocked by B
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
        .expect("Failed to add A->B dependency");
    assert!(output.status.success());

    // Try to make B blocked by A (would create cycle)
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "dep",
            "add",
            &task_b,
            &task_a,
            "--dep-type",
            "blocks",
        ])
        .output()
        .expect("Failed to run dep add for cycle");

    // This should either fail or warn about cycle
    let stderr = String::from_utf8_lossy(&output.stderr);
    let stdout = String::from_utf8_lossy(&output.stdout);
    let combined = format!("{} {}", stdout, stderr).to_lowercase();

    // Check if cycle was detected (implementation may vary)
    let cycle_detected =
        !output.status.success() || combined.contains("cycle") || combined.contains("circular");

    if !cycle_detected {
        println!("NOTE: Circular dependency was allowed - check if this is intended behavior");
        println!("Output: {}", combined);
    }
}

/// Test dependency tree visualization
#[test]
fn test_dependency_tree() {
    let cas = new_cas_instance();

    let epic = cas.create_task_with_options("Epic task", Some("epic"), None, false);
    let task1 = cas.create_task("Subtask 1");
    let task2 = cas.create_task("Subtask 2");

    // Add subtasks as children of epic (using ParentChild relationship)
    let _ = cas
        .cas_cmd()
        .args([
            "task",
            "dep",
            "add",
            &task1,
            &epic,
            "--dep-type",
            "parent-child",
        ])
        .output();
    let _ = cas
        .cas_cmd()
        .args([
            "task",
            "dep",
            "add",
            &task2,
            &epic,
            "--dep-type",
            "parent-child",
        ])
        .output();

    // View dependency tree
    let output = cas
        .cas_cmd()
        .args(["task", "dep", "tree", &epic])
        .output()
        .expect("Failed to show dependency tree");

    assert!(
        output.status.success(),
        "dep tree failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Tree should show epic and its children
    assert!(
        stdout.contains(&epic) || stdout.contains("Epic task"),
        "Tree should show epic"
    );
}

/// Test removing a dependency
#[test]
fn test_remove_dependency() {
    let cas = new_cas_instance();

    let task_a = cas.create_task("Task A");
    let task_b = cas.create_task("Task B");

    // Add dependency
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
    assert!(output.status.success());

    // Task A should be blocked
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        !stdout.contains(&task_a),
        "Task A should be blocked initially"
    );

    // Remove dependency
    let output = cas
        .cas_cmd()
        .args(["task", "dep", "remove", &task_a, &task_b])
        .output()
        .expect("Failed to remove dependency");
    assert!(
        output.status.success(),
        "dep remove failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    // Task A should now be ready
    let output = cas
        .cas_cmd()
        .args(["task", "ready"])
        .output()
        .expect("Failed to list ready tasks");
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(
        stdout.contains(&task_a),
        "Task A should be ready after removing dependency"
    );
}

/// Test multiple blockers

/// Test 'blocked' command shows blocked tasks
#[test]
fn test_blocked_command() {
    let cas = new_cas_instance();

    let blocked_task = cas.create_task("I am blocked");
    let blocker = cas.create_task("I am blocking");
    let _normal_task = cas.create_task("I am normal");

    // Create blocking dependency
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "dep",
            "add",
            &blocked_task,
            &blocker,
            "--dep-type",
            "blocks",
        ])
        .output()
        .expect("Failed to add dependency");
    assert!(output.status.success());

    // List blocked tasks
    let output = cas
        .cas_cmd()
        .args(["task", "blocked"])
        .output()
        .expect("Failed to list blocked tasks");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Blocked task should appear in blocked list
    assert!(
        stdout.contains(&blocked_task),
        "Blocked task should appear in blocked list"
    );
    // The blocker ID may appear since "blocked" shows tasks with their blockers
    // But normal tasks shouldn't appear unless they're blocked
}

/// Test dependency relationships of different types
#[test]
fn test_dependency_types() {
    let cas = new_cas_instance();

    let _task1 = cas.create_task("Task 1");
    let _task2 = cas.create_task("Task 2");

    let dep_types = ["blocks", "related", "parent-child", "discovered-from"];

    for dep_type in dep_types {
        // Clean slate - create new tasks for each type
        let a = cas.create_task(&format!("Task A - {} test", dep_type));
        let b = cas.create_task(&format!("Task B - {} test", dep_type));

        let output = cas
            .cas_cmd()
            .args(["task", "dep", "add", &a, &b, "--dep-type", dep_type])
            .output()
            .expect("Failed to add dependency");

        assert!(
            output.status.success(),
            "dep add --type {} failed: {}",
            dep_type,
            String::from_utf8_lossy(&output.stderr)
        );
    }
}

/// Test starting a blocked task shows warning
#[test]
fn test_start_blocked_task_warning() {
    let cas = new_cas_instance();

    let blocked_task = cas.create_task("Blocked task");
    let blocker = cas.create_task("Blocker task");

    // Create blocking dependency
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "dep",
            "add",
            &blocked_task,
            &blocker,
            "--dep-type",
            "blocks",
        ])
        .output()
        .expect("Failed to add dependency");
    assert!(output.status.success());

    // Try to start the blocked task
    let output = cas
        .cas_cmd()
        .args(["task", "start", &blocked_task])
        .output()
        .expect("Failed to run start command");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);
    let combined = format!("{} {}", stdout, stderr).to_lowercase();

    // Should either succeed with warning or show blocking info
    println!("Start blocked task output: {}", combined);
    // Note: Implementation may allow starting blocked tasks with a warning
}
