#[test]
fn test_task_claim_race_condition() {
    let (_temp, cas_dir) = setup_test_env();

    // Create a single task
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_test_task(&*task_store, "Contested Task");

    // Create multiple agents
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_ids: Vec<String> = (0..5)
        .map(|i| create_test_agent(&*agent_store, &format!("Racer {i}")))
        .collect();

    let cas_dir = Arc::new(cas_dir);
    let task_id = Arc::new(task_id);

    // All agents try to claim the same task simultaneously
    let handles: Vec<_> = agent_ids
        .into_iter()
        .map(|agent_id| {
            let cas_dir = Arc::clone(&cas_dir);
            let task_id = Arc::clone(&task_id);
            thread::spawn(move || {
                let store = open_agent_store(&cas_dir).unwrap();
                store.try_claim(&task_id, &agent_id, 300, Some("Racing"))
            })
        })
        .collect();

    let results: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();

    // Exactly one agent should succeed
    let successes: Vec<_> = results
        .iter()
        .filter(|r| matches!(r, Ok(cas::types::ClaimResult::Success(_))))
        .collect();

    assert_eq!(
        successes.len(),
        1,
        "Exactly one agent should claim the task"
    );

    // Verify the lease exists
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let lease = agent_store.get_lease(&task_id).unwrap();
    assert!(lease.is_some());
}

#[test]
fn test_lease_renewal_under_contention() {
    let (_temp, cas_dir) = setup_test_env();

    // Create task and agent
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_test_task(&*task_store, "Renewable Task");

    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_id = create_test_agent(&*agent_store, "Renewer");

    // Claim the task
    let claim = agent_store
        .try_claim(&task_id, &agent_id, 300, None)
        .unwrap();
    assert!(matches!(claim, cas::types::ClaimResult::Success(_)));

    let cas_dir = Arc::new(cas_dir);
    let task_id = Arc::new(task_id);
    let agent_id = Arc::new(agent_id);

    // Concurrent renewals from the owner
    let handles: Vec<_> = (0..10)
        .map(|_| {
            let cas_dir = Arc::clone(&cas_dir);
            let task_id = Arc::clone(&task_id);
            let agent_id = Arc::clone(&agent_id);
            thread::spawn(move || {
                let store = open_agent_store(&cas_dir).unwrap();
                store.renew_lease(&task_id, &agent_id, 300)
            })
        })
        .collect();

    let results: Vec<_> = handles.into_iter().map(|h| h.join().unwrap()).collect();

    // All renewals should succeed (they're from the owner)
    for result in results {
        assert!(result.is_ok());
    }
}

#[test]
fn test_unregister_releases_all_leases() {
    let (_temp, cas_dir) = setup_test_env();

    // Create multiple tasks
    let task_store = open_task_store(&cas_dir).unwrap();
    let task1 = create_test_task(&*task_store, "Task 1");
    let task2 = create_test_task(&*task_store, "Task 2");
    let task3 = create_test_task(&*task_store, "Task 3");

    // Create agent and claim all tasks
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_id = create_test_agent(&*agent_store, "Multi-Task Agent");

    agent_store.try_claim(&task1, &agent_id, 300, None).unwrap();
    agent_store.try_claim(&task2, &agent_id, 300, None).unwrap();
    agent_store.try_claim(&task3, &agent_id, 300, None).unwrap();

    // Verify all leases exist
    let leases = agent_store.list_agent_leases(&agent_id).unwrap();
    assert_eq!(leases.len(), 3);

    // Unregister agent
    agent_store.unregister(&agent_id).unwrap();

    // Verify agent is gone
    assert!(agent_store.get(&agent_id).is_err());

    // Verify all leases are released
    assert!(agent_store.get_lease(&task1).unwrap().is_none());
    assert!(agent_store.get_lease(&task2).unwrap().is_none());
    assert!(agent_store.get_lease(&task3).unwrap().is_none());
}

#[test]
fn test_released_lease_makes_task_orphaned() {
    let (_temp, cas_dir) = setup_test_env();

    // Create task
    let task_store = open_task_store(&cas_dir).unwrap();
    let task_id = create_task_with_status(&*task_store, "Will Be Orphaned", TaskStatus::InProgress);

    // Create agent and claim task
    let agent_store = open_agent_store(&cas_dir).unwrap();
    let agent_id = create_test_agent(&*agent_store, "Leaving Agent");

    agent_store
        .try_claim(&task_id, &agent_id, 300, None)
        .unwrap();

    // Verify task is not orphaned
    let leases = agent_store.list_active_leases().unwrap();
    assert_eq!(leases.len(), 1);

    // Release the lease but DON'T change task status (simulating a bug/crash)
    agent_store.release_lease(&task_id, &agent_id).unwrap();

    // Task is still in_progress but lease is gone - this is an orphaned task
    let task = task_store.get(&task_id).unwrap();
    assert_eq!(task.status, TaskStatus::InProgress);

    let lease = agent_store.get_lease(&task_id).unwrap();
    assert!(lease.is_none(), "Lease should be released");

    // Detect orphan
    let in_progress_tasks = task_store.list(Some(TaskStatus::InProgress)).unwrap();
    let active_leases = agent_store.list_active_leases().unwrap();
    let claimed_ids: Vec<&str> = active_leases.iter().map(|l| l.task_id.as_str()).collect();

    let orphaned: Vec<_> = in_progress_tasks
        .iter()
        .filter(|t| !claimed_ids.contains(&t.id.as_str()))
        .collect();

    assert_eq!(
        orphaned.len(),
        1,
        "Task should be orphaned after lease release"
    );
}

#[test]
fn test_open_tasks_are_not_orphaned() {
    let (_temp, cas_dir) = setup_test_env();

    // Create open tasks (not in_progress)
    let task_store = open_task_store(&cas_dir).unwrap();
    create_task_with_status(&*task_store, "Open Task 1", TaskStatus::Open);
    create_task_with_status(&*task_store, "Open Task 2", TaskStatus::Open);

    // Create one in_progress task without lease (orphaned)
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
    assert_eq!(orphaned.len(), 1, "Only in_progress tasks can be orphaned");
    assert_eq!(orphaned[0].title, "Orphaned Task");
}
