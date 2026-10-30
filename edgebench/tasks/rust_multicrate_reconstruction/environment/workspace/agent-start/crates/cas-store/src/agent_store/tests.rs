use crate::AgentStore;
use crate::agent_store::SqliteAgentStore;
use cas_types::{Agent, AgentStatus, ClaimResult};
use rusqlite::params;
use tempfile::TempDir;

fn create_test_store() -> (TempDir, SqliteAgentStore) { todo!() }

#[test]
fn test_agent_crud() {
    let (_temp, store) = create_test_store();

    // Register agent
    let agent = Agent::new("agent-test".to_string(), "Test Agent".to_string());
    store.register(&agent).unwrap();

    // Get agent
    let retrieved = store.get("agent-test").unwrap();
    assert_eq!(retrieved.name, "Test Agent");
    assert_eq!(retrieved.status, AgentStatus::Active);

    // Update agent
    let mut updated = retrieved;
    updated.name = "Updated Agent".to_string();
    store.update(&updated).unwrap();

    let retrieved = store.get("agent-test").unwrap();
    assert_eq!(retrieved.name, "Updated Agent");

    // List agents
    let agents = store.list(None).unwrap();
    assert_eq!(agents.len(), 1);

    // Unregister
    store.unregister("agent-test").unwrap();
    assert!(store.get("agent-test").is_err());
}

#[test]
fn test_heartbeat() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new("agent-hb".to_string(), "Heartbeat Test".to_string());
    store.register(&agent).unwrap();

    let before = store.get("agent-hb").unwrap().last_heartbeat;
    std::thread::sleep(std::time::Duration::from_millis(10));
    store.heartbeat("agent-hb").unwrap();
    let after = store.get("agent-hb").unwrap().last_heartbeat;

    assert!(after > before);
}

#[test]
fn test_lease_claim_and_release() {
    let (_temp, store) = create_test_store();

    // Register agent
    let agent = Agent::new("agent-1".to_string(), "Agent 1".to_string());
    store.register(&agent).unwrap();

    // Claim task
    let result = store
        .try_claim("task-1", "agent-1", 600, Some("Testing"))
        .unwrap();
    assert!(result.is_success());

    let lease = result.lease().unwrap();
    assert_eq!(lease.task_id, "task-1");
    assert_eq!(lease.agent_id, "agent-1");
    assert_eq!(lease.claim_reason, Some("Testing".to_string()));

    // Verify agent's active task count
    let agent = store.get("agent-1").unwrap();
    assert_eq!(agent.active_tasks, 1);

    // Try to claim same task with different agent - should fail
    let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
    store.register(&agent2).unwrap();

    let result = store.try_claim("task-1", "agent-2", 600, None).unwrap();
    assert!(!result.is_success());
    match result {
        ClaimResult::AlreadyClaimed { held_by, .. } => {
            assert_eq!(held_by, "agent-1");
        }
        _ => panic!("Expected AlreadyClaimed"),
    }

    // Release lease
    store.release_lease("task-1", "agent-1").unwrap();

    // Now agent-2 can claim
    let result = store.try_claim("task-1", "agent-2", 600, None).unwrap();
    assert!(result.is_success());
}


#[test]
fn test_expired_lease_reclaim() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new("agent-expire".to_string(), "Expire Test".to_string());
    store.register(&agent).unwrap();

    // Claim with very short duration
    store
        .try_claim("task-expire", "agent-expire", 1, None)
        .unwrap();

    // Wait for expiration
    std::thread::sleep(std::time::Duration::from_secs(2));

    // Reclaim expired
    let count = store.reclaim_expired_leases().unwrap();
    assert_eq!(count, 1);

    // Verify no active lease exists (get_lease only returns active leases)
    let lease = store.get_lease("task-expire").unwrap();
    assert!(
        lease.is_none(),
        "Expired lease should not be returned by get_lease"
    );

    // Verify expiration was logged in history
    let history = store.get_lease_history("task-expire", Some(1)).unwrap();
    assert!(!history.is_empty());
    assert_eq!(history[0].event_type, "expired");

    // Another agent can now claim
    let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
    store.register(&agent2).unwrap();

    let result = store
        .try_claim("task-expire", "agent-2", 600, None)
        .unwrap();
    assert!(result.is_success());
}

#[test]
fn test_list_agent_leases() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new("agent-list".to_string(), "List Test".to_string());
    store.register(&agent).unwrap();

    store.try_claim("task-1", "agent-list", 600, None).unwrap();
    store.try_claim("task-2", "agent-list", 600, None).unwrap();
    store.try_claim("task-3", "agent-list", 600, None).unwrap();

    let leases = store.list_agent_leases("agent-list").unwrap();
    assert_eq!(leases.len(), 3);

    // Verify agent's active task count
    let agent = store.get("agent-list").unwrap();
    assert_eq!(agent.active_tasks, 3);
}

#[test]
fn test_mark_stale_releases_leases() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new("agent-stale".to_string(), "Stale Test".to_string());
    store.register(&agent).unwrap();

    store
        .try_claim("task-stale", "agent-stale", 600, None)
        .unwrap();

    // Mark agent as stale
    store.mark_stale("agent-stale").unwrap();

    // Verify agent is stale
    let agent = store.get("agent-stale").unwrap();
    assert_eq!(agent.status, AgentStatus::Stale);

    // Verify no active lease exists (get_lease only returns active leases)
    let lease = store.get_lease("task-stale").unwrap();
    assert!(
        lease.is_none(),
        "Revoked lease should not be returned by get_lease"
    );

    // Verify revocation was logged in history
    let history = store.get_lease_history("task-stale", Some(1)).unwrap();
    assert!(!history.is_empty());
    assert_eq!(history[0].event_type, "revoked");

    // Another agent can now claim
    let agent2 = Agent::new("agent-alive".to_string(), "Alive".to_string());
    store.register(&agent2).unwrap();

    let result = store
        .try_claim("task-stale", "agent-alive", 600, None)
        .unwrap();
    assert!(result.is_success());
}

#[test]
fn test_agent_get_handles_legacy_text_active_tasks() {
    let (temp, store) = create_test_store();

    let agent = Agent::new("agent-legacy".to_string(), "Legacy Agent".to_string());
    store.register(&agent).unwrap();

    // Simulate legacy/dirty schema data where active_tasks was stored as TEXT.
    let conn = rusqlite::Connection::open(temp.path().join("cas.db")).unwrap();
    conn.execute(
        "UPDATE agents SET active_tasks = ? WHERE id = ?",
        params!["3", "agent-legacy"],
    )
    .unwrap();

    let loaded = store.get("agent-legacy").unwrap();
    assert_eq!(loaded.active_tasks, 3);
}

#[test]
fn test_lease_history_audit_log() {
    let (_temp, store) = create_test_store();

    // Register agent
    let agent = Agent::new("agent-history".to_string(), "History Test".to_string());
    store.register(&agent).unwrap();

    // Claim task with reason
    store
        .try_claim("task-history", "agent-history", 600, Some("Starting work"))
        .unwrap();

    // Verify claim is logged
    let history = store.get_lease_history("task-history", None).unwrap();
    assert_eq!(history.len(), 1);
    assert_eq!(history[0].event_type, "claimed");
    assert_eq!(history[0].agent_id, "agent-history");
    assert_eq!(history[0].epoch, 1);
    assert!(history[0].details.is_some());

    // Renew the lease
    store
        .renew_lease("task-history", "agent-history", 120)
        .unwrap();

    // Verify renewal is logged
    let history = store.get_lease_history("task-history", None).unwrap();
    assert_eq!(history.len(), 2);
    assert_eq!(history[0].event_type, "renewed"); // Most recent first
    assert_eq!(history[1].event_type, "claimed");

    // Release the lease
    store
        .release_lease("task-history", "agent-history")
        .unwrap();

    // Verify release is logged
    let history = store.get_lease_history("task-history", None).unwrap();
    assert_eq!(history.len(), 3);
    assert_eq!(history[0].event_type, "released");

    // Test limit parameter
    let history = store.get_lease_history("task-history", Some(2)).unwrap();
    assert_eq!(history.len(), 2);
}

#[test]
fn test_lease_history_expired() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new(
        "agent-expire-hist".to_string(),
        "Expire History".to_string(),
    );
    store.register(&agent).unwrap();

    // Claim with very short duration
    store
        .try_claim("task-expire-hist", "agent-expire-hist", 1, None)
        .unwrap();

    // Wait for expiration
    std::thread::sleep(std::time::Duration::from_secs(2));

    // Reclaim expired
    store.reclaim_expired_leases().unwrap();

    // Verify expired event is logged
    let history = store.get_lease_history("task-expire-hist", None).unwrap();
    assert_eq!(history.len(), 2);
    assert_eq!(history[0].event_type, "expired");
    assert_eq!(history[1].event_type, "claimed");
}


#[test]
fn test_get_agent_worked_tasks() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new("agent-worked".to_string(), "Worked Tasks Test".to_string());
    store.register(&agent).unwrap();

    // Claim multiple tasks
    store
        .try_claim("task-1", "agent-worked", 600, None)
        .unwrap();
    store
        .try_claim("task-2", "agent-worked", 600, None)
        .unwrap();
    store
        .try_claim("task-3", "agent-worked", 600, None)
        .unwrap();

    // Release some (simulating task completion)
    store.release_lease("task-1", "agent-worked").unwrap();
    store.release_lease("task-2", "agent-worked").unwrap();

    // get_agent_worked_tasks with None should return ALL tasks that were ever claimed
    // even if they were released
    let worked_tasks = store.get_agent_worked_tasks("agent-worked", None).unwrap();
    assert_eq!(worked_tasks.len(), 3);
    assert!(worked_tasks.contains(&"task-1".to_string()));
    assert!(worked_tasks.contains(&"task-2".to_string()));
    assert!(worked_tasks.contains(&"task-3".to_string()));

    // list_agent_leases should only return active leases (task-3)
    let active_leases = store.list_agent_leases("agent-worked").unwrap();
    assert_eq!(active_leases.len(), 1);
    assert_eq!(active_leases[0].task_id, "task-3");
}

#[test]
fn test_get_agent_worked_tasks_with_since_filter() {
    use chrono::Utc;

    let (_temp, store) = create_test_store();

    let agent = Agent::new("agent-filter".to_string(), "Filter Test".to_string());
    store.register(&agent).unwrap();

    // Claim a task
    store
        .try_claim("old-task", "agent-filter", 600, None)
        .unwrap();

    // Sleep briefly and record timestamp
    std::thread::sleep(std::time::Duration::from_millis(50));
    let cutoff = Utc::now();
    std::thread::sleep(std::time::Duration::from_millis(50));

    // Claim another task after the cutoff
    store
        .try_claim("new-task", "agent-filter", 600, None)
        .unwrap();

    // Without filter: both tasks
    let all_tasks = store.get_agent_worked_tasks("agent-filter", None).unwrap();
    assert_eq!(all_tasks.len(), 2);

    // With filter: only new task
    let filtered_tasks = store
        .get_agent_worked_tasks("agent-filter", Some(cutoff))
        .unwrap();
    assert_eq!(filtered_tasks.len(), 1);
    assert!(filtered_tasks.contains(&"new-task".to_string()));
}

#[test]
fn test_working_epics() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new("agent-epic".to_string(), "Epic Test".to_string());
    store.register(&agent).unwrap();

    // Add working epics
    store.add_working_epic("agent-epic", "epic-1").unwrap();
    store.add_working_epic("agent-epic", "epic-2").unwrap();
    store.add_working_epic("agent-epic", "epic-1").unwrap(); // Duplicate should be ignored

    // Get working epics
    let epics = store.get_working_epics("agent-epic").unwrap();
    assert_eq!(epics.len(), 2);
    assert!(epics.contains(&"epic-1".to_string()));
    assert!(epics.contains(&"epic-2".to_string()));

    // Remove one epic
    store.remove_working_epic("agent-epic", "epic-1").unwrap();
    let epics = store.get_working_epics("agent-epic").unwrap();
    assert_eq!(epics.len(), 1);
    assert!(epics.contains(&"epic-2".to_string()));

    // Clear all epics
    store.add_working_epic("agent-epic", "epic-3").unwrap();
    store.clear_working_epics("agent-epic").unwrap();
    let epics = store.get_working_epics("agent-epic").unwrap();
    assert_eq!(epics.len(), 0);
}

#[test]
fn test_orphaned_working_epics() {
    let (_temp, store) = create_test_store();

    // Create two agents - one active, one will be marked dead
    let agent_active = Agent::new("agent-active".to_string(), "Active Agent".to_string());
    let agent_dead = Agent::new("agent-dead".to_string(), "Dead Agent".to_string());
    store.register(&agent_active).unwrap();
    store.register(&agent_dead).unwrap();

    // Both agents work on epics
    store
        .add_working_epic("agent-active", "epic-active")
        .unwrap();
    store.add_working_epic("agent-dead", "epic-orphan").unwrap();

    // list_all_working_epics returns both
    let all_epics = store.list_all_working_epics().unwrap();
    assert_eq!(all_epics.len(), 2);

    // While both agents are active, no orphaned epics
    let orphaned = store.list_orphaned_working_epics().unwrap();
    assert_eq!(orphaned.len(), 0);

    // Mark one agent as stale
    store.mark_stale("agent-dead").unwrap();

    // Now the stale agent's epic should be orphaned
    let orphaned = store.list_orphaned_working_epics().unwrap();
    assert_eq!(orphaned.len(), 1);
    assert!(orphaned.contains(&"epic-orphan".to_string()));

    // Active agent's epic should NOT be in orphaned list
    assert!(!orphaned.contains(&"epic-active".to_string()));
}

#[test]
fn test_worker_can_takeover_supervisor_task() {
    let (_temp, store) = create_test_store();

    // Create supervisor agent
    let supervisor = Agent::new("supervisor-1".to_string(), "Supervisor".to_string());
    store.register(&supervisor).unwrap();

    // Create worker agent with supervisor as parent
    let mut worker = Agent::new("worker-1".to_string(), "Worker".to_string());
    worker.parent_id = Some("supervisor-1".to_string());
    store.register(&worker).unwrap();

    // Supervisor claims a task
    let result = store
        .try_claim("task-1", "supervisor-1", 600, Some("planning"))
        .unwrap();
    assert!(matches!(result, ClaimResult::Success(_)));

    // Verify supervisor has the lease
    let lease = store.get_lease("task-1").unwrap().unwrap();
    assert_eq!(lease.agent_id, "supervisor-1");

    // Worker should be able to take over the task from their supervisor
    let result = store
        .try_claim("task-1", "worker-1", 600, Some("executing"))
        .unwrap();
    assert!(matches!(result, ClaimResult::Success(_)));

    // Verify worker now has the lease
    let lease = store.get_lease("task-1").unwrap().unwrap();
    assert_eq!(lease.agent_id, "worker-1");
    assert_eq!(lease.epoch, 2); // Epoch incremented

    // Check lease history shows transfer
    let history = store.get_lease_history("task-1", None).unwrap();
    let transfer_event = history.iter().find(|e| e.event_type == "transferred");
    assert!(transfer_event.is_some(), "Should have a transfer event");
    let transfer = transfer_event.unwrap();
    assert_eq!(transfer.agent_id, "supervisor-1");
}

#[test]
fn test_non_child_cannot_takeover_task() {
    let (_temp, store) = create_test_store();

    // Create two independent agents (no parent relationship)
    let agent1 = Agent::new("agent-1".to_string(), "Agent 1".to_string());
    let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
    store.register(&agent1).unwrap();
    store.register(&agent2).unwrap();

    // Agent 1 claims a task
    let result = store.try_claim("task-1", "agent-1", 600, None).unwrap();
    assert!(matches!(result, ClaimResult::Success(_)));

    // Agent 2 should NOT be able to take over (no parent relationship)
    let result = store.try_claim("task-1", "agent-2", 600, None).unwrap();
    assert!(matches!(result, ClaimResult::AlreadyClaimed { .. }));

    // Verify agent 1 still has the lease
    let lease = store.get_lease("task-1").unwrap().unwrap();
    assert_eq!(lease.agent_id, "agent-1");
}
