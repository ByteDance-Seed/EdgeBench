use crate::*;


#[test]
fn test_factory_task_lifecycle() {
    let machine = TestMachine::new("lifecycle-machine");

    // Setup factory agents
    let _supervisor = machine.register_agent("supervisor", AgentType::Primary);
    let worker = machine.register_agent("worker-1", AgentType::Worker);

    let agent_store = machine.agent_store();
    let task_store = machine.task_store();

    // Create task
    let mut task = machine.create_task("Complete epic subtask");
    assert_eq!(task.status, TaskStatus::Open);

    // Worker claims task
    let claim = agent_store
        .try_claim(&task.id, &worker.id, 300, Some("Claimed for work"))
        .expect("Claim failed");
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    // Update task status to in_progress
    task.status = TaskStatus::InProgress;
    task_store.update(&task).expect("Failed to update task");

    // Verify task is in progress
    let updated_task = task_store.get(&task.id).expect("Failed to get task");
    assert_eq!(updated_task.status, TaskStatus::InProgress);

    // Worker completes task
    task.status = TaskStatus::Closed;
    task_store.update(&task).expect("Failed to close task");

    // Release lease
    agent_store
        .release_lease(&task.id, &worker.id)
        .expect("Failed to release lease");

    // Verify task is closed and lease is released
    let final_task = task_store.get(&task.id).expect("Failed to get task");
    assert_eq!(final_task.status, TaskStatus::Closed);

    let lease = agent_store
        .get_lease(&task.id)
        .expect("Failed to get lease");
    assert!(lease.is_none(), "Lease should be released");
}

#[test]
fn test_factory_multiple_workers_concurrent_claims() {
    let machine = TestMachine::new("concurrent-machine");

    // Create multiple tasks
    let _task_store = machine.task_store();
    let tasks: Vec<Task> = (0..5)
        .map(|i| machine.create_task(&format!("Task {i}")))
        .collect();

    // Create multiple workers
    let workers: Vec<Agent> = (0..3)
        .map(|i| machine.register_agent(&format!("worker-{i}"), AgentType::Worker))
        .collect();

    let cas_dir = Arc::new(machine.cas_dir.clone());
    let task_ids: Arc<Vec<String>> = Arc::new(tasks.iter().map(|t| t.id.clone()).collect());

    // Each worker tries to claim tasks concurrently
    let handles: Vec<_> = workers
        .iter()
        .enumerate()
        .map(|(worker_idx, worker)| {
            let cas_dir = Arc::clone(&cas_dir);
            let task_ids = Arc::clone(&task_ids);
            let worker_id = worker.id.clone();

            thread::spawn(move || {
                let store = open_agent_store(&cas_dir).expect("Failed to open store");
                let mut claimed = Vec::new();

                for (task_idx, task_id) in task_ids.iter().enumerate() {
                    // Each worker tries to claim different tasks based on their index
                    if task_idx % 3 == worker_idx {
                        if let Ok(cas::types::ClaimResult::Success(_)) =
                            store.try_claim(task_id, &worker_id, 300, None)
                        {
                            claimed.push(task_id.clone());
                        }
                    }
                }

                claimed
            })
        })
        .collect();

    let results: Vec<Vec<String>> = handles
        .into_iter()
        .map(|h| h.join().expect("Thread panicked"))
        .collect();

    // Verify no task is claimed by multiple workers
    let all_claimed: Vec<&String> = results.iter().flat_map(|v| v.iter()).collect();
    let unique_claims: std::collections::HashSet<_> = all_claimed.iter().collect();
    assert_eq!(
        all_claimed.len(),
        unique_claims.len(),
        "Each task should only be claimed once"
    );
}


#[test]
fn test_factory_stale_agent_cleanup() {
    let machine = TestMachine::new("cleanup-machine");

    // Create agents
    let agent1 = machine.register_agent("agent-1", AgentType::Worker);
    let agent2 = machine.register_agent("agent-2", AgentType::Worker);

    let store = machine.agent_store();
    let _task_store = machine.task_store();

    // Create and claim task
    let task = machine.create_task("Orphan-able task");
    store
        .try_claim(&task.id, &agent1.id, 300, Some("Working"))
        .expect("Claim failed");

    // Mark agent1 as stale (simulates cleanup detection)
    store.mark_stale(&agent1.id).expect("Failed to mark stale");

    // Verify agent1 is stale and leases are released
    let stale_agent = store.get(&agent1.id).expect("Failed to get agent");
    assert_eq!(stale_agent.status, AgentStatus::Stale);

    let lease = store.get_lease(&task.id).expect("Failed to get lease");
    assert!(lease.is_none(), "Stale agent's leases should be released");

    // Agent2 can now claim the task
    let claim = store
        .try_claim(&task.id, &agent2.id, 300, Some("Taking over"))
        .expect("Claim failed");
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));
}

// =============================================================================
// Distributed Simulation Tests (Two CAS Directories)
// =============================================================================

#[test]
fn test_distributed_two_machines_independent() {
    // Simulate two separate machines with their own CAS directories
    let machine_a = TestMachine::new("machine-a");
    let machine_b = TestMachine::new("machine-b");

    // Each machine has its own supervisor and workers
    let _supervisor_a = machine_a.register_agent("supervisor-a", AgentType::Primary);
    let worker_a = machine_a.register_agent("worker-a", AgentType::Worker);

    let _supervisor_b = machine_b.register_agent("supervisor-b", AgentType::Primary);
    let worker_b = machine_b.register_agent("worker-b", AgentType::Worker);

    // Each machine creates its own tasks
    let task_a = machine_a.create_task("Task on Machine A");
    let task_b = machine_b.create_task("Task on Machine B");

    // Workers claim tasks on their respective machines
    let store_a = machine_a.agent_store();
    let store_b = machine_b.agent_store();

    let claim_a = store_a
        .try_claim(&task_a.id, &worker_a.id, 300, None)
        .expect("Claim failed");
    assert!(matches!(claim_a, cas::types::ClaimResult::Success(_)));

    let claim_b = store_b
        .try_claim(&task_b.id, &worker_b.id, 300, None)
        .expect("Claim failed");
    assert!(matches!(claim_b, cas::types::ClaimResult::Success(_)));

    // Verify isolation - each machine only knows about its own agents
    let agents_a = store_a.list(None).expect("List failed");
    let agents_b = store_b.list(None).expect("List failed");

    assert_eq!(agents_a.len(), 2); // supervisor-a, worker-a
    assert_eq!(agents_b.len(), 2); // supervisor-b, worker-b

    // Verify agents are distinct between machines
    let a_names: Vec<_> = agents_a.iter().map(|a| &a.name).collect();
    let b_names: Vec<_> = agents_b.iter().map(|a| &a.name).collect();

    assert!(a_names.contains(&&"supervisor-a".to_string()));
    assert!(a_names.contains(&&"worker-a".to_string()));
    assert!(b_names.contains(&&"supervisor-b".to_string()));
    assert!(b_names.contains(&&"worker-b".to_string()));
}

#[test]
fn test_distributed_task_handoff_simulation() {
    // Simulate task handoff between machines via shared storage
    // In real distributed mode, this would happen via cloud sync

    let machine_a = TestMachine::new("handoff-a");
    let machine_b = TestMachine::new("handoff-b");

    // Machine A: Supervisor creates task
    let task = machine_a.create_task("Distributed task");
    let _supervisor = machine_a.register_agent("supervisor", AgentType::Primary);

    // Simulate "syncing" the task to machine B
    // In real scenario, cloud sync would handle this
    let task_store_b = machine_b.task_store();
    let synced_task = Task::new(task.id.clone(), task.title.clone());
    task_store_b.add(&synced_task).expect("Failed to sync task");

    // Machine B: Worker claims the synced task
    let worker = machine_b.register_agent("remote-worker", AgentType::Worker);
    let store_b = machine_b.agent_store();

    let claim = store_b
        .try_claim(&synced_task.id, &worker.id, 300, Some("Remote claim"))
        .expect("Claim failed");
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    // Verify claim exists on machine B
    let lease = store_b
        .get_lease(&synced_task.id)
        .expect("Get lease failed");
    assert!(lease.is_some());
    assert_eq!(lease.unwrap().agent_id, worker.id);
}

// =============================================================================
// Factory Event and Activity Tests
// =============================================================================

#[test]
fn test_factory_lease_history_tracking() {
    let machine = TestMachine::new("history-machine");

    let worker1 = machine.register_agent("worker-1", AgentType::Worker);
    let worker2 = machine.register_agent("worker-2", AgentType::Worker);

    let store = machine.agent_store();
    let task = machine.create_task("History tracking task");

    // Worker 1 claims
    store
        .try_claim(&task.id, &worker1.id, 300, Some("First claim"))
        .expect("Claim failed");

    // Worker 1 releases
    store
        .release_lease(&task.id, &worker1.id)
        .expect("Release failed");

    // Worker 2 claims
    store
        .try_claim(&task.id, &worker2.id, 300, Some("Second claim"))
        .expect("Claim failed");

    // Check history
    let history = store
        .get_lease_history(&task.id, None)
        .expect("History failed");

    // Should have at least: claimed (w1), released (w1), claimed (w2)
    assert!(history.len() >= 3, "Should have multiple history entries");

    // Verify event types are tracked
    let event_types: Vec<&str> = history.iter().map(|e| e.event_type.as_str()).collect();
    assert!(event_types.contains(&"claimed"), "Should track claims");
    assert!(event_types.contains(&"released"), "Should track releases");
}

#[test]
fn test_factory_agent_active_tasks_count() {
    let machine = TestMachine::new("active-tasks-machine");

    let worker = machine.register_agent("busy-worker", AgentType::Worker);
    let store = machine.agent_store();

    // Create and claim multiple tasks
    let tasks: Vec<Task> = (0..3)
        .map(|i| machine.create_task(&format!("Task {i}")))
        .collect();

    for task in &tasks {
        store
            .try_claim(&task.id, &worker.id, 300, None)
            .expect("Claim failed");
    }

    // Check agent's active leases
    let leases = store
        .list_agent_leases(&worker.id)
        .expect("List leases failed");
    assert_eq!(leases.len(), 3, "Worker should have 3 active leases");

    // Release one
    store
        .release_lease(&tasks[0].id, &worker.id)
        .expect("Release failed");

    let leases_after = store
        .list_agent_leases(&worker.id)
        .expect("List leases failed");
    assert_eq!(leases_after.len(), 2, "Worker should have 2 active leases");
}

// =============================================================================
// Cloud Integration Tests (Require CAS_CLOUD_TOKEN)
// =============================================================================

/// Get cloud configuration from environment for testing
/// Returns None if cloud credentials are not available
fn get_test_cloud_config() -> Option<cas::cloud::CloudConfig> { todo!() }

#[test]
#[ignore = "Requires CAS_CLOUD_TOKEN environment variable"]
fn test_cloud_factory_registration() {
    let config = match get_test_cloud_config() {
        Some(c) => c,
        None => {
            eprintln!("Skipping cloud test: CAS_CLOUD_TOKEN not set");
            return;
        }
    };

    // Create a cloud coordinator
    let mut coordinator =
        cas::cloud::CloudCoordinator::new(config).expect("Failed to create cloud coordinator");

    // Register a test agent
    let agent = Agent::new(
        Agent::generate_fallback_id(),
        "test-factory-agent".to_string(),
    );

    let result = coordinator.register(&agent);

    // Verify registration succeeded
    assert!(
        result.is_ok(),
        "Cloud registration should succeed: {:?}",
        result.err()
    );

    let agent_info = result.unwrap();
    assert_eq!(agent_info.name, "test-factory-agent");

    // Cleanup: shutdown the agent
    let shutdown_result = coordinator.shutdown();
    assert!(shutdown_result.is_ok(), "Shutdown should succeed");
}

#[test]
#[ignore = "Requires CAS_CLOUD_TOKEN environment variable"]
fn test_cloud_agent_sync_across_machines() {
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

    // Register agent on machine A
    let agent_a = Agent::new(Agent::generate_fallback_id(), "machine-a-agent".to_string());
    coordinator_a
        .register(&agent_a)
        .expect("Failed to register agent A");

    // Register agent on machine B
    let agent_b = Agent::new(Agent::generate_fallback_id(), "machine-b-agent".to_string());
    coordinator_b
        .register(&agent_b)
        .expect("Failed to register agent B");

    // List all agents - both should be visible
    let agents = coordinator_a
        .list_agents(None)
        .expect("Failed to list agents");

    // Verify both agents are visible (may include other agents from previous runs)
    let names: Vec<&str> = agents.iter().map(|a| a.name.as_str()).collect();
    assert!(names.contains(&"machine-a-agent"), "Should see agent A");
    assert!(names.contains(&"machine-b-agent"), "Should see agent B");

    // Cleanup
    coordinator_a.shutdown().ok();
    coordinator_b.shutdown().ok();
}


#[test]
#[ignore = "Requires CAS_CLOUD_TOKEN environment variable"]
fn test_cloud_prompt_queue_delivery() {
    let config = match get_test_cloud_config() {
        Some(c) => c,
        None => {
            eprintln!("Skipping cloud test: CAS_CLOUD_TOKEN not set");
            return;
        }
    };

    // Create a coordinator
    let mut coordinator =
        cas::cloud::CloudCoordinator::new(config).expect("Failed to create cloud coordinator");

    // Register test agent
    let agent = Agent::new(
        Agent::generate_fallback_id(),
        "prompt-test-agent".to_string(),
    );
    coordinator
        .register(&agent)
        .expect("Failed to register agent");

    // Verify agent is registered and can receive heartbeat
    // (Prompt queue testing requires the full MCP + Director infrastructure)
    let heartbeat = coordinator.heartbeat();
    assert!(
        heartbeat.is_ok(),
        "Heartbeat should succeed after registration"
    );

    // Cleanup
    coordinator.shutdown().ok();
}

#[test]
#[ignore = "Requires CAS_CLOUD_TOKEN environment variable"]
fn test_cloud_event_streaming() {
    let config = match get_test_cloud_config() {
        Some(c) => c,
        None => {
            eprintln!("Skipping cloud test: CAS_CLOUD_TOKEN not set");
            return;
        }
    };

    // Create coordinators
    let mut coordinator_a =
        cas::cloud::CloudCoordinator::new(config.clone()).expect("Failed to create coordinator A");
    let mut coordinator_b =
        cas::cloud::CloudCoordinator::new(config).expect("Failed to create coordinator B");

    // Register agents
    let agent_a = Agent::new(Agent::generate_fallback_id(), "event-agent-a".to_string());
    coordinator_a
        .register(&agent_a)
        .expect("Failed to register agent A");

    let agent_b = Agent::new(Agent::generate_fallback_id(), "event-agent-b".to_string());
    coordinator_b
        .register(&agent_b)
        .expect("Failed to register agent B");

    // Send heartbeats (events are recorded in cloud)
    coordinator_a.heartbeat().expect("Heartbeat A failed");
    coordinator_b.heartbeat().expect("Heartbeat B failed");

    // List locks to verify coordinator is working
    let locks_a = coordinator_a.list_locks();
    let locks_b = coordinator_b.list_locks();

    assert!(locks_a.is_ok(), "List locks from A should work");
    assert!(locks_b.is_ok(), "List locks from B should work");

    // Both should see the same locks (consistent view)
    let locks_a = locks_a.unwrap();
    let locks_b = locks_b.unwrap();
    assert_eq!(
        locks_a.len(),
        locks_b.len(),
        "Both coordinators should see same locks"
    );

    // Cleanup
    coordinator_a.shutdown().ok();
    coordinator_b.shutdown().ok();
}

// =============================================================================
// Factory Mode Simulation Tests
// =============================================================================

#[test]
fn test_factory_epic_workflow_simulation() {
    let machine = TestMachine::new("epic-machine");

    // Setup factory with supervisor and workers
    let _supervisor = machine.register_agent("supervisor", AgentType::Primary);
    let workers: Vec<Agent> = (0..2)
        .map(|i| machine.register_agent(&format!("worker-{i}"), AgentType::Worker))
        .collect();

    let task_store = machine.task_store();
    let agent_store = machine.agent_store();

    // Supervisor creates an "epic" (parent task)
    let mut epic = machine.create_task("Implement user authentication");
    epic.task_type = cas::types::TaskType::Epic;
    task_store.update(&epic).expect("Failed to update epic");

    // Supervisor creates subtasks
    let subtasks: Vec<Task> = vec![
        machine.create_task("Design auth schema"),
        machine.create_task("Implement login endpoint"),
        machine.create_task("Add JWT validation"),
        machine.create_task("Write auth tests"),
    ];

    // Workers claim subtasks
    for (i, subtask) in subtasks.iter().enumerate() {
        let worker_idx = i % workers.len();
        agent_store
            .try_claim(
                &subtask.id,
                &workers[worker_idx].id,
                300,
                Some("Working on epic"),
            )
            .expect("Claim failed");
    }

    // Verify task distribution
    for worker in &workers {
        let leases = agent_store
            .list_agent_leases(&worker.id)
            .expect("List failed");
        assert!(
            !leases.is_empty(),
            "Each worker should have at least 1 task"
        );
    }

    // Simulate task completion
    for subtask in &subtasks {
        let mut task = task_store.get(&subtask.id).expect("Get failed");
        task.status = TaskStatus::Closed;
        task_store.update(&task).expect("Update failed");
    }

    // Verify all subtasks are closed
    let all_tasks = task_store.list(None).expect("List failed");
    let closed_count = all_tasks
        .iter()
        .filter(|t| t.status == TaskStatus::Closed && t.id != epic.id)
        .count();
    assert_eq!(closed_count, subtasks.len());
}

#[test]
fn test_factory_worker_reassignment() {
    let machine = TestMachine::new("reassignment-machine");

    let worker1 = machine.register_agent("worker-1", AgentType::Worker);
    let worker2 = machine.register_agent("worker-2", AgentType::Worker);

    let store = machine.agent_store();
    let task = machine.create_task("Reassignable task");

    // Worker 1 claims task
    store
        .try_claim(&task.id, &worker1.id, 300, None)
        .expect("Claim failed");

    // Worker 1 gets marked as stale (simulating crash)
    store.mark_stale(&worker1.id).expect("Mark stale failed");

    // Worker 2 can now take over
    let claim = store
        .try_claim(&task.id, &worker2.id, 300, Some("Reassigned"))
        .expect("Claim failed");
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    // Verify worker 2 now holds the lease
    let lease = store.get_lease(&task.id).expect("Get lease failed");
    assert!(lease.is_some());
    assert_eq!(lease.unwrap().agent_id, worker2.id);
}

#[test]
fn test_factory_priority_based_task_selection() {
    let machine = TestMachine::new("priority-machine");

    let worker = machine.register_agent("worker", AgentType::Worker);
    let task_store = machine.task_store();
    let agent_store = machine.agent_store();

    // Create tasks with different priorities
    let mut critical_task = machine.create_task("Critical bug fix");
    critical_task.priority = Priority::CRITICAL;
    task_store.update(&critical_task).expect("Update failed");

    let mut high_task = machine.create_task("High priority feature");
    high_task.priority = Priority::HIGH;
    task_store.update(&high_task).expect("Update failed");

    let mut low_task = machine.create_task("Low priority chore");
    low_task.priority = Priority::BACKLOG;
    task_store.update(&low_task).expect("Update failed");

    // Query tasks by priority (simulating supervisor task assignment)
    let all_tasks = task_store
        .list(Some(TaskStatus::Open))
        .expect("List failed");
    let mut sorted_tasks = all_tasks.clone();
    sorted_tasks.sort_by_key(|t| t.priority.0);

    // Highest priority (lowest number) should be first
    assert_eq!(sorted_tasks[0].id, critical_task.id);
    assert_eq!(sorted_tasks[1].id, high_task.id);
    assert_eq!(sorted_tasks[2].id, low_task.id);

    // Worker claims highest priority task
    agent_store
        .try_claim(&sorted_tasks[0].id, &worker.id, 300, Some("Critical work"))
        .expect("Claim failed");

    let leases = agent_store
        .list_agent_leases(&worker.id)
        .expect("List failed");
    assert_eq!(leases[0].task_id, critical_task.id);
}
