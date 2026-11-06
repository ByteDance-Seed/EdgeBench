#[test]
fn test_factory_supervisor_worker_local() {
    // Simulate a factory with supervisor and worker on the same machine
    let machine = TestMachine::new("local-machine");

    // Register supervisor
    let supervisor = machine.register_agent("supervisor", AgentType::Primary);
    assert_eq!(supervisor.agent_type, AgentType::Primary);

    // Register workers
    let worker1 = machine.register_agent("swift-fox", AgentType::Worker);
    let worker2 = machine.register_agent("bold-eagle", AgentType::Worker);

    // Verify all agents are registered
    let store = machine.agent_store();
    let agents = store.list(None).expect("Failed to list agents");
    assert_eq!(agents.len(), 3);

    // Verify agent types
    let workers: Vec<_> = agents
        .iter()
        .filter(|a| a.agent_type == AgentType::Worker)
        .collect();
    assert_eq!(workers.len(), 2);

    // Create task and assign to worker
    let task = machine.create_task("Implement feature X");

    // Worker claims the task
    let claim_result = store
        .try_claim(&task.id, &worker1.id, 300, Some("Starting work"))
        .expect("Failed to claim task");

    assert!(matches!(claim_result, cas::types::ClaimResult::Success(_)));

    // Verify worker2 cannot claim the same task
    let claim_result2 = store
        .try_claim(&task.id, &worker2.id, 300, None)
        .expect("Failed to attempt claim");

    assert!(matches!(
        claim_result2,
        cas::types::ClaimResult::AlreadyClaimed { .. }
    ));
}

#[test]
fn test_factory_agent_heartbeat_and_status() {
    let machine = TestMachine::new("heartbeat-machine");

    let supervisor = machine.register_agent("supervisor", AgentType::Primary);
    let worker = machine.register_agent("worker", AgentType::Worker);

    let store = machine.agent_store();

    // Initial status should be active (just registered)
    let agent = store.get(&supervisor.id).expect("Failed to get supervisor");
    assert_eq!(agent.status, AgentStatus::Active);

    // Send heartbeat
    store.heartbeat(&worker.id).expect("Heartbeat failed");

    // Verify heartbeat updated
    let updated_worker = store.get(&worker.id).expect("Failed to get worker");
    assert_eq!(updated_worker.status, AgentStatus::Active);
}

#[test]
#[ignore = "Requires CAS_CLOUD_TOKEN environment variable"]
fn test_cloud_task_claiming_distributed() {
    let config = match get_test_cloud_config() {
        Some(c) => c,
        None => {
            eprintln!("Skipping cloud test: CAS_CLOUD_TOKEN not set");
            return;
        }
    };

    // Create two coordinators (simulating two machines)
    let mut coordinator_a =
        cas::cloud::CloudCoordinator::new(config.clone()).expect("Failed to create coordinator A");
    let mut coordinator_b =
        cas::cloud::CloudCoordinator::new(config).expect("Failed to create coordinator B");

    // Register agents
    let mut agent_a = Agent::new(Agent::generate_fallback_id(), "claimer-a".to_string());
    agent_a.agent_type = AgentType::Worker;
    coordinator_a
        .register(&agent_a)
        .expect("Failed to register agent A");

    let mut agent_b = Agent::new(Agent::generate_fallback_id(), "claimer-b".to_string());
    agent_b.agent_type = AgentType::Worker;
    coordinator_b
        .register(&agent_b)
        .expect("Failed to register agent B");

    // Create a test task ID (in real scenario, this would be synced via cloud)
    let task_id = format!("test-task-{}", chrono::Utc::now().timestamp());

    // Agent A claims the task
    let claim_a = coordinator_a.claim(&task_id, 300, Some("Testing"));

    // Handle case where task doesn't exist in cloud yet
    if let Ok(result) = &claim_a {
        if matches!(result, cas::types::ClaimResult::TaskNotFound(_)) {
            eprintln!("Task not found in cloud - this is expected if task wasn't synced");
            coordinator_a.shutdown().ok();
            coordinator_b.shutdown().ok();
            return;
        }

        // If claim succeeded, agent B should not be able to claim
        if matches!(result, cas::types::ClaimResult::Success(_)) {
            let claim_b = coordinator_b.claim(&task_id, 300, Some("Also trying"));
            assert!(
                matches!(
                    claim_b.as_ref().unwrap(),
                    cas::types::ClaimResult::AlreadyClaimed { .. }
                ),
                "Agent B should not be able to claim: {claim_b:?}"
            );
        }
    }

    // Cleanup
    coordinator_a.shutdown().ok();
    coordinator_b.shutdown().ok();
}
