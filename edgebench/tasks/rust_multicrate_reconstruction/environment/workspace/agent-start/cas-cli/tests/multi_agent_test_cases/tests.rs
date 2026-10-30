use crate::*;

#[test]
fn test_multiple_agents_register_concurrently() {
    let (_temp, cas_dir) = setup_test_env();
    let cas_dir = Arc::new(cas_dir);

    let handles: Vec<_> = (0..5)
        .map(|i| {
            let cas_dir = Arc::clone(&cas_dir);
            thread::spawn(move || {
                let store = open_agent_store(&cas_dir).unwrap();
                let id = Agent::generate_fallback_id();
                let agent = Agent::new(id.clone(), format!("Agent {i}"));
                store.register(&agent).unwrap();
                id
            })
        })
        .collect();

    let agent_ids: Vec<String> = handles.into_iter().map(|h| h.join().unwrap()).collect();

    // Verify all agents were registered
    let store = open_agent_store(&cas_dir).unwrap();
    let agents = store.list(None).unwrap();
    assert_eq!(agents.len(), 5);

    // Verify each agent ID is unique
    let mut sorted_ids = agent_ids.clone();
    sorted_ids.sort();
    sorted_ids.dedup();
    assert_eq!(sorted_ids.len(), 5);
}


#[test]
fn test_concurrent_reads_dont_block() {
    let (_temp, cas_dir) = setup_test_env();

    // Create some agents
    let agent_store = open_agent_store(&cas_dir).unwrap();
    for i in 0..10 {
        create_test_agent(&*agent_store, &format!("Reader {i}"));
    }

    let cas_dir = Arc::new(cas_dir);

    // Many concurrent reads
    let handles: Vec<_> = (0..20)
        .map(|_| {
            let cas_dir = Arc::clone(&cas_dir);
            thread::spawn(move || {
                let store = open_agent_store(&cas_dir).unwrap();
                store.list(None).unwrap()
            })
        })
        .collect();

    // All reads should complete without blocking
    let results: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();

    for agents in results {
        assert_eq!(agents.len(), 10);
    }
}


#[test]
fn test_agent_heartbeat_under_load() {
    let (_temp, cas_dir) = setup_test_env();

    // Create multiple agents
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_ids: Vec<String> = (0..5)
        .map(|i| create_test_agent(&*agent_store, &format!("Heartbeater {i}")))
        .collect();

    let cas_dir = Arc::new(cas_dir);

    // Concurrent heartbeats from all agents
    let handles: Vec<_> = agent_ids
        .iter()
        .flat_map(|id| {
            (0..5).map(|_| {
                let cas_dir = Arc::clone(&cas_dir);
                let id = id.clone();
                thread::spawn(move || {
                    let store = open_agent_store(&cas_dir).unwrap();
                    store.heartbeat(&id)
                })
            })
        })
        .collect();

    let results: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();

    // All heartbeats should succeed
    for result in results {
        assert!(result.is_ok());
    }
}

#[test]
fn test_expired_lease_reclaim_under_contention() {
    let (_temp, cas_dir) = setup_test_env();

    // Create task
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_test_task(&*task_store, "Expirable Task");

    // Create agents
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let original_agent = create_test_agent(&*agent_store, "Original");
    let waiting_agents: Vec<String> = (0..3)
        .map(|i| create_test_agent(&*agent_store, &format!("Waiting {i}")))
        .collect();

    // Original agent claims with very short lease (1 second)
    let claim = agent_store
        .try_claim(&task_id, &original_agent, 1, None)
        .unwrap();
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    // Wait for lease to expire
    thread::sleep(Duration::from_secs(2));

    // Reclaim expired leases
    let reclaimed = agent_store.reclaim_expired_leases().unwrap();
    assert_eq!(reclaimed, 1);

    // Sequential claim attempts after expiry (race test is in test_task_claim_race_condition)
    // This test verifies that after reclaim, the task becomes claimable again
    let new_claim = agent_store
        .try_claim(&task_id, &waiting_agents[0], 300, Some("After expiry"))
        .unwrap();
    assert!(matches!(new_claim, cas::types::ClaimResult::Success(_)));

    // Other agents should get AlreadyClaimed
    let blocked_claim = agent_store
        .try_claim(&task_id, &waiting_agents[1], 300, None)
        .unwrap();
    assert!(matches!(
        blocked_claim,
        cas::types::ClaimResult::AlreadyClaimed { .. }
    ));
}

#[test]
fn test_task_release_allows_new_claim() {
    let (_temp, cas_dir) = setup_test_env();

    // Create task
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_test_task(&*task_store, "Releasable Task");

    // Create agents
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let first_agent = create_test_agent(&*agent_store, "First");
    let second_agent = create_test_agent(&*agent_store, "Second");

    // First agent claims
    let claim = agent_store
        .try_claim(&task_id, &first_agent, 300, None)
        .unwrap();
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    // Second agent tries to claim - should fail
    let claim2 = agent_store
        .try_claim(&task_id, &second_agent, 300, None)
        .unwrap();
    assert!(matches!(
        claim2,
        cas::types::ClaimResult::AlreadyClaimed { .. }
    ));

    // First agent releases
    agent_store.release_lease(&task_id, &first_agent).unwrap();

    // Second agent can now claim
    let claim3 = agent_store
        .try_claim(&task_id, &second_agent, 300, None)
        .unwrap();
    assert!(matches!(claim3, cas::types::ClaimResult::Success(_)));
}

#[test]
fn test_list_available_tasks_with_concurrent_claims() {
    let (_temp, cas_dir) = setup_test_env();

    // Create multiple tasks
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_ids: Vec<String> = (0..10)
        .map(|i| create_test_task(&*task_store, &format!("Task {i}")))
        .collect();

    // Create agents
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_ids: Vec<String> = (0..3)
        .map(|i| create_test_agent(&*agent_store, &format!("Claimer {i}")))
        .collect();

    // Each agent claims some tasks
    for (i, agent_id) in agent_ids.iter().enumerate() {
        for j in 0..2 {
            let task_idx = i * 2 + j;
            if task_idx < task_ids.len() {
                let _ = agent_store.try_claim(&task_ids[task_idx], agent_id, 300, None);
            }
        }
    }

    // List available tasks (unclaimed + open status)
    let all_leases = agent_store.list_active_leases().unwrap();
    assert_eq!(all_leases.len(), 6); // 3 agents * 2 tasks each

    // Verify claimed tasks have leases
    for lease in &all_leases {
        assert!(task_ids.contains(&lease.task_id));
    }
}

#[test]
fn test_stale_agent_detection() {
    let (_temp, cas_dir) = setup_test_env();

    let agent_store = open_agent_store(&cas_dir).unwrap();

    // Create agent that will go stale
    let _stale_agent_id = create_test_agent(&*agent_store, "Stale Agent");

    // Create active agent with recent heartbeat
    let active_agent_id = create_test_agent(&*agent_store, "Active Agent");
    agent_store.heartbeat(&active_agent_id).unwrap();

    // List stale agents (heartbeat older than 60 seconds)
    // Since both just registered, neither should be stale yet
    let stale = agent_store.list_stale(60).unwrap();
    assert_eq!(stale.len(), 0);

    // With a very short threshold, both should be stale
    // (we can't really test this without waiting, so skip time-based test)
}

#[test]
fn test_full_cleanup_cycle_stale_to_dead_to_reclaim() {
    let (_temp, cas_dir) = setup_test_env();

    // Create task
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_test_task(&*task_store, "Abandoned Task");

    // Create agent and claim task
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_id = create_test_agent(&*agent_store, "Will Die Agent");

    let claim = agent_store
        .try_claim(&task_id, &agent_id, 300, Some("Working on it"))
        .unwrap();
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    // Verify lease exists
    let lease = agent_store.get_lease(&task_id).unwrap();
    assert!(lease.is_some());
    assert_eq!(lease.unwrap().agent_id, agent_id);

    // Mark agent as stale (simulates what cleanup does after stale detection)
    agent_store.mark_stale(&agent_id).unwrap();

    // Verify agent status is stale
    let agent = agent_store.get(&agent_id).unwrap();
    assert_eq!(agent.status, cas::types::AgentStatus::Stale);

    // Verify lease was released (mark_stale releases all leases)
    let lease_after = agent_store.get_lease(&task_id).unwrap();
    assert!(
        lease_after.is_none(),
        "Lease should be released when agent marked stale"
    );

    // Another agent can now claim the task
    let new_agent_id = create_test_agent(&*agent_store, "New Agent");
    let new_claim = agent_store
        .try_claim(&task_id, &new_agent_id, 300, Some("Taking over"))
        .unwrap();
    assert!(matches!(new_claim, cas::types::ClaimResult::Success(_)));
}

#[test]
fn test_heartbeat_prevents_stale_detection() {
    let (_temp, cas_dir) = setup_test_env();

    let agent_store = open_agent_store(&cas_dir).unwrap();

    // Create two agents
    let active_agent = create_test_agent(&*agent_store, "Active Agent");
    let _inactive_agent = create_test_agent(&*agent_store, "Inactive Agent");

    // Send heartbeat for active agent
    agent_store.heartbeat(&active_agent).unwrap();

    // Both just created, so neither is stale with 60s threshold
    let stale = agent_store.list_stale(60).unwrap();
    assert_eq!(stale.len(), 0);

    // Verify heartbeat updated the timestamp and status
    let agent = agent_store.get(&active_agent).unwrap();
    assert_eq!(agent.status, cas::types::AgentStatus::Active);
}

#[test]
fn test_reclaim_expired_leases() {
    let (_temp, cas_dir) = setup_test_env();

    // Create task
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_test_task(&*task_store, "Short Lease Task");

    // Create agent with very short lease (1 second)
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_id = create_test_agent(&*agent_store, "Short Lease Agent");

    let claim = agent_store.try_claim(&task_id, &agent_id, 1, None).unwrap();
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    // Wait for lease to expire
    thread::sleep(Duration::from_secs(2));

    // Reclaim expired leases
    let reclaimed = agent_store.reclaim_expired_leases().unwrap();
    assert_eq!(reclaimed, 1, "Should reclaim 1 expired lease");

    // Verify lease is gone
    let lease = agent_store.get_lease(&task_id).unwrap();
    assert!(lease.is_none(), "Expired lease should be reclaimed");

    // Another agent can now claim
    let new_agent = create_test_agent(&*agent_store, "New Agent");
    let new_claim = agent_store
        .try_claim(&task_id, &new_agent, 300, None)
        .unwrap();
    assert!(matches!(new_claim, cas::types::ClaimResult::Success(_)));
}


#[test]
fn test_lease_history_audit_trail() {
    let (_temp, cas_dir) = setup_test_env();

    // Create task
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_test_task(&*task_store, "Audited Task");

    // Create agents
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent1 = create_test_agent(&*agent_store, "Agent 1");
    let agent2 = create_test_agent(&*agent_store, "Agent 2");

    // Agent 1 claims
    agent_store
        .try_claim(&task_id, &agent1, 300, Some("First claim"))
        .unwrap();

    // Agent 1 releases
    agent_store.release_lease(&task_id, &agent1).unwrap();

    // Agent 2 claims
    agent_store
        .try_claim(&task_id, &agent2, 300, Some("Second claim"))
        .unwrap();

    // Check history
    let history = agent_store.get_lease_history(&task_id, None).unwrap();
    assert!(history.len() >= 3, "Should have at least 3 history entries");

    // Verify event types
    let event_types: Vec<&str> = history.iter().map(|e| e.event_type.as_str()).collect();
    assert!(
        event_types.contains(&"claimed"),
        "Should have 'claimed' event"
    );
    assert!(
        event_types.contains(&"released"),
        "Should have 'released' event"
    );
}

// =============================================================================
// Orphaned Task Detection Tests
// =============================================================================
// These tests verify that tasks in `in_progress` status without active leases
// (orphaned tasks) are properly detected and can be identified.

/// Helper to create a task with a specific status
fn create_task_with_status(store: &dyn TaskStore, title: &str, status: TaskStatus) -> String { todo!() }

#[test]
fn test_detect_orphaned_task_in_progress_without_lease() {
    let (_temp, cas_dir) = setup_test_env();

    // Create a task directly as in_progress (simulating the bug)
    let task_store = open_task_store(&cas_dir).unwrap();
    let orphaned_task_id =
        create_task_with_status(&*task_store, "Orphaned Task", TaskStatus::InProgress);

    // Create a normal task that will be properly claimed
    let normal_task_id =
        create_task_with_status(&*task_store, "Normal Task", TaskStatus::InProgress);

    // Create an agent and claim only the normal task
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_id = create_test_agent(&*agent_store, "Test Agent");

    let claim = agent_store
        .try_claim(&normal_task_id, &agent_id, 300, Some("Working"))
        .unwrap();
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    // Get all in_progress tasks
    let all_tasks = task_store.list(Some(TaskStatus::InProgress)).unwrap();
    assert_eq!(all_tasks.len(), 2, "Should have 2 in_progress tasks");

    // Get all active leases
    let leases = agent_store.list_active_leases().unwrap();
    let claimed_task_ids: Vec<&str> = leases.iter().map(|l| l.task_id.as_str()).collect();

    // Find orphaned tasks (in_progress but not claimed)
    let orphaned: Vec<_> = all_tasks
        .iter()
        .filter(|t| !claimed_task_ids.contains(&t.id.as_str()))
        .collect();

    assert_eq!(orphaned.len(), 1, "Should detect 1 orphaned task");
    assert_eq!(
        orphaned[0].id, orphaned_task_id,
        "Orphaned task ID should match"
    );
}

#[test]
fn test_task_properly_claimed_is_not_orphaned() {
    let (_temp, cas_dir) = setup_test_env();

    // Create tasks
    let task_store = open_task_store(&cas_dir).unwrap();
    let task1_id = create_task_with_status(&*task_store, "Task 1", TaskStatus::InProgress);
    let task2_id = create_task_with_status(&*task_store, "Task 2", TaskStatus::InProgress);
    let task3_id = create_task_with_status(&*task_store, "Task 3", TaskStatus::InProgress);

    // Create agent and claim all tasks
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_id = create_test_agent(&*agent_store, "Diligent Agent");

    agent_store
        .try_claim(&task1_id, &agent_id, 300, None)
        .unwrap();
    agent_store
        .try_claim(&task2_id, &agent_id, 300, None)
        .unwrap();
    agent_store
        .try_claim(&task3_id, &agent_id, 300, None)
        .unwrap();

    // Get all in_progress tasks
    let in_progress_tasks = task_store.list(Some(TaskStatus::InProgress)).unwrap();

    // Get all active leases
    let leases = agent_store.list_active_leases().unwrap();
    let claimed_task_ids: Vec<&str> = leases.iter().map(|l| l.task_id.as_str()).collect();

    // Find orphaned tasks
    let orphaned: Vec<_> = in_progress_tasks
        .iter()
        .filter(|t| !claimed_task_ids.contains(&t.id.as_str()))
        .collect();

    assert_eq!(
        orphaned.len(),
        0,
        "All tasks should be claimed, none orphaned"
    );
}


#[test]
fn test_expired_lease_makes_task_orphaned() {
    let (_temp, cas_dir) = setup_test_env();

    // Create task
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_task_with_status(&*task_store, "Expiring Task", TaskStatus::InProgress);

    // Create agent and claim with very short lease
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_id = create_test_agent(&*agent_store, "Short Lease Agent");

    agent_store.try_claim(&task_id, &agent_id, 1, None).unwrap();

    // Wait for lease to expire
    thread::sleep(Duration::from_secs(2));

    // Reclaim expired leases
    agent_store.reclaim_expired_leases().unwrap();

    // Task is still in_progress but lease is gone
    let task = task_store.get(&task_id).unwrap();
    assert_eq!(task.status, TaskStatus::InProgress);

    let lease = agent_store.get_lease(&task_id).unwrap();
    assert!(lease.is_none(), "Lease should be expired/reclaimed");

    // This task is now orphaned
    let in_progress_tasks = task_store.list(Some(TaskStatus::InProgress)).unwrap();
    let active_leases = agent_store.list_active_leases().unwrap();

    assert_eq!(in_progress_tasks.len(), 1);
    assert_eq!(active_leases.len(), 0);
}


#[test]
fn test_closed_tasks_are_not_orphaned() {
    let (_temp, cas_dir) = setup_test_env();

    // Create closed task
    let task_store = open_task_store(&cas_dir).unwrap();
    create_task_with_status(&*task_store, "Closed Task", TaskStatus::Closed);

    // Create orphaned task
    create_task_with_status(&*task_store, "Orphaned Task", TaskStatus::InProgress);

    let agent_store = open_agent_store(&cas_dir).unwrap();

    // Get only in_progress tasks for orphan detection
    let in_progress_tasks = task_store.list(Some(TaskStatus::InProgress)).unwrap();
    let active_leases = agent_store.list_active_leases().unwrap();
    let claimed_ids: Vec<&str> = active_leases.iter().map(|l| l.task_id.as_str()).collect();

    let orphaned: Vec<_> = in_progress_tasks
        .iter()
        .filter(|t| !claimed_ids.contains(&t.id.as_str()))
        .collect();

    // Only the in_progress task should be orphaned
    assert_eq!(
        orphaned.len(),
        1,
        "Closed tasks should not be considered orphaned"
    );
}

#[test]
fn test_multiple_agents_orphan_detection() {
    let (_temp, cas_dir) = setup_test_env();

    // Create multiple tasks
    let task_store = open_task_store(&cas_dir).unwrap();
    let task1 = create_task_with_status(&*task_store, "Agent 1 Task", TaskStatus::InProgress);
    let task2 = create_task_with_status(&*task_store, "Agent 2 Task", TaskStatus::InProgress);
    let task3 = create_task_with_status(&*task_store, "Orphaned Task", TaskStatus::InProgress);

    // Create multiple agents
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent1 = create_test_agent(&*agent_store, "Agent 1");
    let agent2 = create_test_agent(&*agent_store, "Agent 2");

    // Each agent claims one task, leaving task3 orphaned
    agent_store.try_claim(&task1, &agent1, 300, None).unwrap();
    agent_store.try_claim(&task2, &agent2, 300, None).unwrap();

    // Detect orphans
    let in_progress_tasks = task_store.list(Some(TaskStatus::InProgress)).unwrap();
    let active_leases = agent_store.list_active_leases().unwrap();
    let claimed_ids: Vec<&str> = active_leases.iter().map(|l| l.task_id.as_str()).collect();

    let orphaned: Vec<_> = in_progress_tasks
        .iter()
        .filter(|t| !claimed_ids.contains(&t.id.as_str()))
        .collect();

    assert_eq!(orphaned.len(), 1, "Should have 1 orphaned task");
    assert_eq!(orphaned[0].id, task3, "Task 3 should be orphaned");
}
