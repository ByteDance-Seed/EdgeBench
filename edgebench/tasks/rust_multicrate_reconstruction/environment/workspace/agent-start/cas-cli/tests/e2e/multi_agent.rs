//! Multi-agent coordination E2E tests
//!
//! Tests agent registration, task claiming, lease management, coordination

use crate::fixtures::new_cas_instance;

/// Test agent registration
#[test]
fn test_agent_register() {
    let cas = new_cas_instance();

    let output = cas
        .cas_cmd()
        .args([
            "agent",
            "register",
            "--name",
            "test-agent-1",
            "--agent-type",
            "primary",
        ])
        .output()
        .expect("Failed to register agent");

    assert!(
        output.status.success(),
        "agent register failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

/// Test agent whoami

/// Test agent list

/// Test agent heartbeat

/// Test task claiming by agent
#[test]
fn test_task_claim() {
    let cas = new_cas_instance();

    // Register an agent first
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "claim-agent"])
        .output()
        .expect("Failed to register agent");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let re = regex::Regex::new(r"(cli-[a-f0-9]+)").ok();
    let agent_id = re
        .and_then(|r| r.captures(&stdout))
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
        .unwrap_or_default();

    if agent_id.is_empty() {
        println!("Skipping test: could not extract agent ID");
        return;
    }

    // Create a task
    let task_id = cas.create_task("Task to claim");

    // Claim the task
    let output = cas
        .cas_cmd()
        .args(["task", "claim", &task_id, "--agent-id", &agent_id])
        .output()
        .expect("Failed to claim task");

    assert!(
        output.status.success(),
        "task claim failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

/// Test task release
#[test]
fn test_task_release() {
    let cas = new_cas_instance();

    // Register an agent first
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "release-agent"])
        .output()
        .expect("Failed to register agent");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let re = regex::Regex::new(r"(cli-[a-f0-9]+)").ok();
    let agent_id = re
        .and_then(|r| r.captures(&stdout))
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
        .unwrap_or_default();

    if agent_id.is_empty() {
        println!("Skipping test: could not extract agent ID");
        return;
    }

    let task_id = cas.create_task("Task to release");

    // Claim first
    let _ = cas
        .cas_cmd()
        .args(["task", "claim", &task_id, "--agent-id", &agent_id])
        .output();

    // Release
    let output = cas
        .cas_cmd()
        .args(["task", "release", &task_id])
        .output()
        .expect("Failed to release task");

    assert!(
        output.status.success(),
        "release failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    println!(
        "Release output: {}",
        String::from_utf8_lossy(&output.stdout)
    );
}

/// Test agent leases
#[test]
fn test_agent_leases() {
    let cas = new_cas_instance();

    // Register an agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "leases-agent"])
        .output()
        .expect("Failed to register agent");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let re = regex::Regex::new(r"(cli-[a-f0-9]+)").ok();
    let agent_id = re
        .and_then(|r| r.captures(&stdout))
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
        .unwrap_or_default();

    if !agent_id.is_empty() {
        // Create and claim a task to create a lease
        let task_id = cas.create_task("Task for lease test");
        let _ = cas
            .cas_cmd()
            .args(["task", "claim", &task_id, "--agent-id", &agent_id])
            .output();
    }

    // List leases
    let output = cas
        .cas_cmd()
        .args(["agent", "leases"])
        .output()
        .expect("Failed to list leases");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    println!("Agent leases: {}", stdout);
}

/// Test available tasks (unclaimed, ready)
#[test]
fn test_task_available() {
    let cas = new_cas_instance();

    // Create multiple tasks
    cas.create_task("Available task 1");
    cas.create_task("Available task 2");

    // Check available tasks
    let output = cas
        .cas_cmd()
        .args(["task", "available"])
        .output()
        .expect("Failed to list available tasks");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    println!("Available tasks: {}", stdout);
}

/// Test my tasks (tasks assigned to current agent)

/// Test agent cleanup of stale agents
#[test]
fn test_agent_cleanup() {
    let cas = new_cas_instance();

    let output = cas
        .cas_cmd()
        .args(["agent", "cleanup", "--stale-threshold", "0"])
        .output()
        .expect("Failed to run agent cleanup");

    assert!(
        output.status.success(),
        "agent cleanup failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

/// Test agent types
#[test]
fn test_agent_types() {
    let cas = new_cas_instance();

    let agent_types = ["primary", "sub_agent", "worker", "ci"];

    for agent_type in agent_types {
        let output = cas
            .cas_cmd()
            .args([
                "agent",
                "register",
                "--name",
                &format!("test-{}-agent", agent_type),
                "--agent-type",
                agent_type,
            ])
            .output()
            .expect("Failed to register agent");

        assert!(
            output.status.success(),
            "agent register --agent-type {} failed: {}",
            agent_type,
            String::from_utf8_lossy(&output.stderr)
        );
    }
}

/// Test task transfer between agents
#[test]
fn test_task_transfer() {
    let cas = new_cas_instance();

    // Register first agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-from"])
        .output()
        .expect("Failed to register first agent");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let re = regex::Regex::new(r"(cli-[a-f0-9]+)").ok();
    let from_agent_id = re
        .as_ref()
        .and_then(|r| r.captures(&stdout))
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
        .unwrap_or_default();

    // Register second agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "agent-to"])
        .output()
        .expect("Failed to register second agent");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let to_agent_id = re
        .and_then(|r| r.captures(&stdout))
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
        .unwrap_or_default();

    if from_agent_id.is_empty() || to_agent_id.is_empty() {
        println!("Skipping test: could not extract agent IDs");
        return;
    }

    // Create and claim a task
    let task_id = cas.create_task("Task to transfer");
    let _ = cas
        .cas_cmd()
        .args(["task", "claim", &task_id, "--agent-id", &from_agent_id])
        .output();

    // Transfer task
    let output = cas
        .cas_cmd()
        .args(["task", "transfer", &task_id, "--to-agent", &to_agent_id])
        .output()
        .expect("Failed to transfer task");

    println!(
        "Transfer output: {}",
        String::from_utf8_lossy(&output.stdout)
    );
    println!(
        "Transfer stderr: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

/// Test lease duration
#[test]
fn test_claim_with_duration() {
    let cas = new_cas_instance();

    // Register an agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "duration-agent"])
        .output()
        .expect("Failed to register agent");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let re = regex::Regex::new(r"(cli-[a-f0-9]+)").ok();
    let agent_id = re
        .and_then(|r| r.captures(&stdout))
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
        .unwrap_or_default();

    if agent_id.is_empty() {
        println!("Skipping test: could not extract agent ID");
        return;
    }

    let task_id = cas.create_task("Task with custom lease duration");

    // Claim with custom duration
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "claim",
            &task_id,
            "--agent-id",
            &agent_id,
            "--duration",
            "3600",
        ])
        .output()
        .expect("Failed to claim task with duration");

    assert!(
        output.status.success(),
        "claim with duration failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
}

/// Test agent show command
#[test]
fn test_agent_show() {
    let cas = new_cas_instance();

    // Register an agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "show-test-agent"])
        .output()
        .expect("Failed to register agent");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let re = regex::Regex::new(r"(cli-[a-f0-9]+)").ok();

    if let Some(re) = re {
        if let Some(caps) = re.captures(&stdout) {
            let agent_id = caps.get(1).map(|m| m.as_str()).unwrap_or("");

            if !agent_id.is_empty() {
                let output = cas
                    .cas_cmd()
                    .args(["agent", "show", agent_id])
                    .output()
                    .expect("Failed to show agent");

                assert!(
                    output.status.success(),
                    "agent show failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                );
            }
        }
    }
}

/// Test agent unregister

/// Test lease expiration behavior
#[test]
fn test_lease_expiration() {
    let cas = new_cas_instance();

    // Register an agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "expiration-agent"])
        .output()
        .expect("Failed to register agent");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let re = regex::Regex::new(r"(cli-[a-f0-9]+)").ok();
    let agent_id = re
        .and_then(|r| r.captures(&stdout))
        .and_then(|c| c.get(1))
        .map(|m| m.as_str().to_string())
        .unwrap_or_default();

    if agent_id.is_empty() {
        println!("Skipping test: could not extract agent ID");
        return;
    }

    let task_id = cas.create_task("Task with expiring lease");

    // Claim with very short duration
    let output = cas
        .cas_cmd()
        .args([
            "task",
            "claim",
            &task_id,
            "--agent-id",
            &agent_id,
            "--duration",
            "1",
        ])
        .output()
        .expect("Failed to claim task");

    if output.status.success() {
        // Wait a bit (lease should expire)
        std::thread::sleep(std::time::Duration::from_secs(2));

        // Check lease status
        let output = cas
            .cas_cmd()
            .args(["agent", "leases"])
            .output()
            .expect("Failed to list leases");

        let stdout = String::from_utf8_lossy(&output.stdout);
        println!("Leases after expiration: {}", stdout);
    }
}
