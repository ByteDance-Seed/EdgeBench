#[test]
fn test_agent_whoami() {
    let cas = new_cas_instance();

    // Register first
    let _ = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "whoami-test"])
        .output();

    let output = cas
        .cas_cmd()
        .args(["agent", "whoami"])
        .output()
        .expect("Failed to run agent whoami");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    println!("Agent whoami: {}", stdout);
}

#[test]
fn test_agent_list() {
    let cas = new_cas_instance();

    // Register an agent
    let _ = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "list-test-agent"])
        .output();

    let output = cas
        .cas_cmd()
        .args(["agent", "list"])
        .output()
        .expect("Failed to list agents");

    assert!(output.status.success());
}

#[test]
fn test_agent_heartbeat() {
    let cas = new_cas_instance();

    // Register first
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "heartbeat-agent"])
        .output()
        .expect("Failed to register agent");

    // Extract agent ID if present
    let stdout = String::from_utf8_lossy(&output.stdout);
    let re = regex::Regex::new(r"(cli-[a-f0-9]+)").ok();

    if let Some(re) = re {
        if let Some(caps) = re.captures(&stdout) {
            let agent_id = caps.get(1).map(|m| m.as_str()).unwrap_or("");

            if !agent_id.is_empty() {
                // Send heartbeat
                let output = cas
                    .cas_cmd()
                    .args(["agent", "heartbeat", agent_id])
                    .output()
                    .expect("Failed to send heartbeat");

                assert!(
                    output.status.success(),
                    "heartbeat failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                );
            }
        }
    }
}

#[test]
fn test_task_mine() {
    let cas = new_cas_instance();

    // Register an agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "mine-agent"])
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

    // Create and claim a task
    let task_id = cas.create_task("My task");
    let _ = cas
        .cas_cmd()
        .args(["task", "claim", &task_id, "--agent-id", &agent_id])
        .output();

    // List my tasks
    let output = cas
        .cas_cmd()
        .args(["task", "mine", "--agent-id", &agent_id])
        .output()
        .expect("Failed to list my tasks");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains(&task_id) || stdout.contains("My task"));
}

#[test]
fn test_agent_unregister() {
    let cas = new_cas_instance();

    // Register an agent
    let output = cas
        .cas_cmd()
        .args(["agent", "register", "--name", "unregister-test-agent"])
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
                    .args(["agent", "unregister", agent_id])
                    .output()
                    .expect("Failed to unregister agent");

                assert!(
                    output.status.success(),
                    "agent unregister failed: {}",
                    String::from_utf8_lossy(&output.stderr)
                );
            }
        }
    }
}
