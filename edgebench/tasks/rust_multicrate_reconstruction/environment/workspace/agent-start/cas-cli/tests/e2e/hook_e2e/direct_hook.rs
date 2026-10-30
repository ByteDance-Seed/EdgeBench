use crate::fixtures::HookTestEnv;

#[test]
#[ignore]
fn test_hook_pre_tool_use_jail_blocks_read() {
    let env = HookTestEnv::new();

    // Create a task and set pending_verification
    let task_id = env.create_task("Hook jail test task");
    env.set_pending_verification(&task_id, true);
    println!("Created jailed task: {}", task_id);

    // Call PreToolUse for Read - should be blocked
    let (success, output) = env.run_pre_tool_use_read("test.txt");
    println!("PreToolUse(Read) output: {}", output);

    // Parse the output and check for denial
    let is_denied = env.is_hook_denied(&output);
    println!("Is denied: {}", is_denied);

    assert!(
        is_denied || !success,
        "Read should be blocked when in verification jail. Output: {}",
        output
    );
}

/// Test that PreToolUse for Task(task-verifier) clears the verification jail
///
/// This tests the unjailing mechanism that allows task-verifier to run.
/// The key fix: Task must be in the PreToolUse matcher for unjailing to work.
#[test]
#[ignore]
fn test_hook_pre_tool_use_task_verifier_unjails() {
    let env = HookTestEnv::new();

    // Create a task and set pending_verification
    let task_id = env.create_task("Unjail test task");
    env.set_pending_verification(&task_id, true);
    println!("Created jailed task: {}", task_id);

    // Verify Read is blocked initially
    let (_, output1) = env.run_pre_tool_use_read("test.txt");
    let initially_blocked = env.is_hook_denied(&output1);
    println!("Initially blocked: {}", initially_blocked);

    // Clean up any existing marker file
    env.remove_marker_file();
    assert!(
        !env.marker_file_exists(),
        "Marker file should not exist yet"
    );

    // Call PreToolUse for Task(task-verifier) - should unjail
    let (success, output) = env.run_pre_tool_use_task_verifier();
    println!(
        "PreToolUse(Task, task-verifier) success: {}, output: {}",
        success, output
    );

    // Marker file should now exist
    assert!(
        env.marker_file_exists(),
        "Marker file should be created when Task(task-verifier) is called"
    );

    // pending_verification should be cleared in DB
    let tasks = env.get_tasks();
    let task = tasks.iter().find(|(id, _, _)| id == &task_id);
    assert!(task.is_some(), "Task should exist");

    // Verify directly via rusqlite that pending_verification is cleared
    let pv = env.get_pending_verification(&task_id);
    println!("pending_verification after unjail: {}", pv);
    assert!(
        !pv,
        "pending_verification should be cleared after Task(task-verifier)"
    );
}

/// Test full verification jail flow: block -> unjail -> allow
///
/// This is the comprehensive E2E test that covers the full flow:
/// 1. Set pending_verification=true
/// 2. PreToolUse(Read) is blocked
/// 3. PreToolUse(Task, task-verifier) clears jail
/// 4. PreToolUse(Read) now works
#[test]
#[ignore]
fn test_hook_verification_jail_full_flow() {
    let env = HookTestEnv::new();

    // Create a task and set pending_verification
    let task_id = env.create_task("Full flow jail test");
    env.set_pending_verification(&task_id, true);
    env.remove_marker_file();
    println!("=== Step 1: Created jailed task {} ===", task_id);

    // Step 2: Verify Read is blocked
    println!("\n=== Step 2: PreToolUse(Read) should be BLOCKED ===");
    let (success1, output1) = env.run_pre_tool_use_read("test.txt");
    println!("Success: {}, Output: {}", success1, output1);

    let is_blocked = env.is_hook_denied(&output1);
    assert!(
        is_blocked || !success1,
        "Read should be blocked when in jail. Output: {}",
        output1
    );
    println!("✓ Read correctly blocked");

    // Step 3: Unjail via Task(task-verifier)
    println!("\n=== Step 3: PreToolUse(Task, task-verifier) should UNJAIL ===");
    let (success2, output2) = env.run_pre_tool_use_task_verifier();
    println!("Success: {}, Output: {}", success2, output2);

    assert!(success2, "Task(task-verifier) should succeed");
    assert!(
        env.marker_file_exists(),
        "Marker file should exist after unjail"
    );
    println!("✓ Marker file created");

    // Verify DB was updated
    let pv = env.get_pending_verification(&task_id);
    assert!(!pv, "pending_verification should be cleared");
    println!("✓ pending_verification cleared in DB");

    // Step 4: Verify Read now works
    println!("\n=== Step 4: PreToolUse(Read) should NOW WORK ===");
    let (success3, output3) = env.run_pre_tool_use_read("test.txt");
    println!("Success: {}, Output: {}", success3, output3);

    let is_still_blocked = env.is_hook_denied(&output3);
    assert!(
        !is_still_blocked && success3,
        "Read should work after unjail. Output: {}",
        output3
    );
    println!("✓ Read allowed after unjail");

    println!("\n=== SUCCESS: Full verification jail flow verified ===");
}
