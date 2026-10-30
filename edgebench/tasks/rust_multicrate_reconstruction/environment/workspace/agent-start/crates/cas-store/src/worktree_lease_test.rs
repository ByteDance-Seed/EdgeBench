//! TDD tests for worktree lease functionality
//!
//! These tests define the expected behavior BEFORE implementation.
//! Run with: cargo test -p cas-store worktree_lease

#[cfg(test)]
mod tests {
    use crate::agent_store::{AgentStore, SqliteAgentStore};
    use crate::worktree_store::{SqliteWorktreeStore, WorktreeStore};
    use cas_types::{Agent, LeaseStatus, Worktree, WorktreeClaimResult, WorktreeLease};
    use chrono::{Duration, Utc};
    use tempfile::TempDir;

    fn create_test_stores() -> (TempDir, SqliteAgentStore, SqliteWorktreeStore) {
        let temp = TempDir::new().unwrap();

        // Create shared database with all required tables
        let conn = rusqlite::Connection::open(temp.path().join("cas.db")).unwrap();
        conn.busy_timeout(crate::SQLITE_BUSY_TIMEOUT).unwrap();
        conn.execute_batch(
            r#"
            PRAGMA journal_mode=WAL;
            PRAGMA synchronous=NORMAL;
            PRAGMA foreign_keys=ON;

            -- Agents table
            CREATE TABLE IF NOT EXISTS agents (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                agent_type TEXT NOT NULL DEFAULT 'primary',
                role TEXT NOT NULL DEFAULT 'standard',
                status TEXT NOT NULL DEFAULT 'active',
                pid INTEGER,
                ppid INTEGER,
                cc_session_id TEXT,
                parent_id TEXT,
                machine_id TEXT,
                registered_at TEXT NOT NULL,
                last_heartbeat TEXT NOT NULL,
                active_tasks INTEGER NOT NULL DEFAULT 0,
                metadata TEXT NOT NULL DEFAULT '{}'
            );

            -- Task leases table
            CREATE TABLE IF NOT EXISTS task_leases (
                task_id TEXT PRIMARY KEY,
                agent_id TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'active',
                acquired_at TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                renewed_at TEXT NOT NULL,
                renewal_count INTEGER NOT NULL DEFAULT 0,
                epoch INTEGER NOT NULL DEFAULT 1,
                claim_reason TEXT
            );

            -- Worktrees table
            CREATE TABLE IF NOT EXISTS worktrees (
                id TEXT PRIMARY KEY,
                epic_id TEXT,
                branch TEXT NOT NULL,
                parent_branch TEXT NOT NULL,
                path TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'active',
                created_at TEXT NOT NULL,
                merged_at TEXT,
                removed_at TEXT,
                created_by_agent TEXT,
                merge_commit TEXT,
                change_id TEXT,
                workspace_name TEXT,
                has_conflicts INTEGER NOT NULL DEFAULT 0
            );

            -- Worktree leases table (NEW)
            CREATE TABLE IF NOT EXISTS worktree_leases (
                worktree_id TEXT PRIMARY KEY,
                agent_id TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'active',
                acquired_at TEXT NOT NULL,
                expires_at TEXT NOT NULL,
                renewed_at TEXT NOT NULL,
                renewal_count INTEGER NOT NULL DEFAULT 0,
                FOREIGN KEY (worktree_id) REFERENCES worktrees(id) ON DELETE CASCADE,
                FOREIGN KEY (agent_id) REFERENCES agents(id) ON DELETE CASCADE
            );

            CREATE INDEX IF NOT EXISTS idx_worktree_leases_agent ON worktree_leases(agent_id);
            CREATE INDEX IF NOT EXISTS idx_worktree_leases_status ON worktree_leases(status);
            CREATE INDEX IF NOT EXISTS idx_worktree_leases_expires ON worktree_leases(expires_at);

            -- Working epics table (needed by agent store)
            CREATE TABLE IF NOT EXISTS working_epics (
                agent_id TEXT NOT NULL,
                epic_id TEXT NOT NULL,
                started_at TEXT NOT NULL,
                PRIMARY KEY (agent_id, epic_id)
            );

            -- Task lease history (needed by agent store)
            CREATE TABLE IF NOT EXISTS task_lease_history (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                task_id TEXT NOT NULL,
                agent_id TEXT NOT NULL,
                event_type TEXT NOT NULL,
                epoch INTEGER NOT NULL DEFAULT 1,
                timestamp TEXT NOT NULL,
                details TEXT,
                previous_agent_id TEXT
            );

            -- Daemon instances (needed by agent store)
            CREATE TABLE IF NOT EXISTS daemon_instances (
                id TEXT PRIMARY KEY,
                pid INTEGER NOT NULL,
                daemon_type TEXT NOT NULL DEFAULT 'mcp_embedded',
                started_at TEXT NOT NULL,
                last_heartbeat TEXT NOT NULL,
                status TEXT NOT NULL DEFAULT 'running'
            );
            "#,
        )
        .unwrap();
        drop(conn);

        let agent_store = SqliteAgentStore::open(temp.path()).unwrap();
        let worktree_store = SqliteWorktreeStore::open(temp.path()).unwrap();

        (temp, agent_store, worktree_store)
    }

    fn create_test_workspace(store: &SqliteWorktreeStore, epic_id: &str) -> Worktree {
        let workspace = Worktree::for_epic(
            Worktree::generate_id(),
            epic_id.to_string(),
            format!("epic/{epic_id}"),
            "main".to_string(),
            std::path::PathBuf::from(format!("/tmp/workspaces/{epic_id}")),
            None,
        );
        store.add(&workspace).unwrap();
        workspace
    }

    // ============================================
    // TEST: WorktreeLease type basics
    // ============================================

    #[test]
    fn test_worktree_lease_new() {
        let lease = WorktreeLease::new(
            "wt-123".to_string(),
            "agent-1".to_string(),
            600, // 10 minutes
        );

        assert_eq!(lease.worktree_id, "wt-123");
        assert_eq!(lease.agent_id, "agent-1");
        assert_eq!(lease.status, LeaseStatus::Active);
        assert!(lease.is_valid());
        assert!(!lease.is_expired());
        assert_eq!(lease.renewal_count, 0);
    }

    #[test]
    fn test_worktree_lease_expiry() {
        let mut lease = WorktreeLease::new("wt-1".to_string(), "agent-1".to_string(), 1);
        assert!(lease.is_valid());

        // Simulate time passing
        lease.expires_at = Utc::now() - Duration::seconds(1);
        assert!(lease.is_expired());
        assert!(!lease.is_valid());
    }

    #[test]
    fn test_worktree_lease_renewal() {
        let mut lease = WorktreeLease::new("wt-1".to_string(), "agent-1".to_string(), 60);
        let old_expires = lease.expires_at;

        std::thread::sleep(std::time::Duration::from_millis(10));
        lease.renew(120);

        assert!(lease.expires_at > old_expires);
        assert_eq!(lease.renewal_count, 1);
        assert!(lease.is_valid());
    }

    #[test]
    fn test_worktree_lease_release() {
        let mut lease = WorktreeLease::new("wt-1".to_string(), "agent-1".to_string(), 600);
        assert!(lease.is_valid());

        lease.release();
        assert_eq!(lease.status, LeaseStatus::Released);
        assert!(!lease.is_valid());
    }

    // ============================================
    // TEST: Worktree lease storage - claim
    // ============================================

    #[test]
    fn test_try_claim_worktree_success() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        // Register agent
        let agent = Agent::new("agent-1".to_string(), "Test Agent".to_string());
        agent_store.register(&agent).unwrap();

        // Create worktree
        let worktree = create_test_workspace(&worktree_store, "epic-123");

        // Claim worktree
        let result = agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 600)
            .unwrap();

        assert!(result.is_success());
        let lease = result.lease().unwrap();
        assert_eq!(lease.worktree_id, worktree.id);
        assert_eq!(lease.agent_id, "agent-1");
        assert!(lease.is_valid());
    }

    #[test]
    fn test_try_claim_worktree_already_claimed() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        // Register two agents
        let agent1 = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
        agent_store.register(&agent1).unwrap();
        agent_store.register(&agent2).unwrap();

        // Create worktree
        let worktree = create_test_workspace(&worktree_store, "epic-456");

        // Agent 1 claims worktree
        let result1 = agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 600)
            .unwrap();
        assert!(result1.is_success());

        // Agent 2 tries to claim - should fail
        let result2 = agent_store
            .try_claim_worktree(&worktree.id, "agent-2", 600)
            .unwrap();
        assert!(!result2.is_success());

        match result2 {
            WorktreeClaimResult::AlreadyClaimed { held_by, .. } => {
                assert_eq!(held_by, "agent-1");
            }
            _ => panic!("Expected AlreadyClaimed"),
        }
    }


    // ============================================
    // TEST: Worktree lease storage - release
    // ============================================

    #[test]
    fn test_release_worktree_lease() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        agent_store.register(&agent).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-release");

        // Claim
        agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 600)
            .unwrap();

        // Release
        agent_store
            .release_worktree_lease(&worktree.id, "agent-1")
            .unwrap();

        // Verify no active lease
        let lease = agent_store.get_worktree_lease(&worktree.id).unwrap();
        assert!(lease.is_none());

        // Another agent can now claim
        let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
        agent_store.register(&agent2).unwrap();

        let result = agent_store
            .try_claim_worktree(&worktree.id, "agent-2", 600)
            .unwrap();
        assert!(result.is_success());
    }

    #[test]
    fn test_release_worktree_lease_wrong_owner() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent1 = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
        agent_store.register(&agent1).unwrap();
        agent_store.register(&agent2).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-wrong-owner");

        // Agent 1 claims
        agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 600)
            .unwrap();

        // Agent 2 tries to release - should fail
        let result = agent_store.release_worktree_lease(&worktree.id, "agent-2");
        assert!(result.is_err());
    }

    // ============================================
    // TEST: Worktree lease storage - renewal
    // ============================================

    #[test]
    fn test_renew_worktree_lease() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        agent_store.register(&agent).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-renew");

        agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 60)
            .unwrap();

        let before = agent_store
            .get_worktree_lease(&worktree.id)
            .unwrap()
            .unwrap();

        std::thread::sleep(std::time::Duration::from_millis(10));

        agent_store
            .renew_worktree_lease(&worktree.id, "agent-1", 120)
            .unwrap();

        let after = agent_store
            .get_worktree_lease(&worktree.id)
            .unwrap()
            .unwrap();

        assert!(after.expires_at > before.expires_at);
        assert_eq!(after.renewal_count, 1);
    }

    // ============================================
    // TEST: Worktree lease storage - expiry
    // ============================================

    #[test]
    fn test_expired_worktree_lease_allows_new_claim() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent1 = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
        agent_store.register(&agent1).unwrap();
        agent_store.register(&agent2).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-expire");

        // Agent 1 claims with very short duration
        agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 1)
            .unwrap();

        // Wait for expiration
        std::thread::sleep(std::time::Duration::from_secs(2));

        // Agent 2 can now claim (expired lease)
        let result = agent_store
            .try_claim_worktree(&worktree.id, "agent-2", 600)
            .unwrap();
        assert!(result.is_success());
        assert_eq!(result.lease().unwrap().agent_id, "agent-2");
    }

    #[test]
    fn test_reclaim_expired_worktree_leases() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        agent_store.register(&agent).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-reclaim");

        // Claim with very short duration
        agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 1)
            .unwrap();

        // Wait for expiration
        std::thread::sleep(std::time::Duration::from_secs(2));

        // Reclaim expired
        let count = agent_store.reclaim_expired_worktree_leases().unwrap();
        assert_eq!(count, 1);

        // Verify no active lease
        let lease = agent_store.get_worktree_lease(&worktree.id).unwrap();
        assert!(lease.is_none());
    }

    // ============================================
    // TEST: List operations
    // ============================================

    #[test]
    fn test_list_agent_worktree_leases() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        agent_store.register(&agent).unwrap();

        let wt1 = create_test_workspace(&worktree_store, "epic-list-1");
        let wt2 = create_test_workspace(&worktree_store, "epic-list-2");

        agent_store
            .try_claim_worktree(&wt1.id, "agent-1", 600)
            .unwrap();
        agent_store
            .try_claim_worktree(&wt2.id, "agent-1", 600)
            .unwrap();

        let leases = agent_store.list_agent_worktree_leases("agent-1").unwrap();
        assert_eq!(leases.len(), 2);
    }

    #[test]
    fn test_list_active_worktree_leases() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent1 = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
        agent_store.register(&agent1).unwrap();
        agent_store.register(&agent2).unwrap();

        let wt1 = create_test_workspace(&worktree_store, "epic-active-1");
        let wt2 = create_test_workspace(&worktree_store, "epic-active-2");

        agent_store
            .try_claim_worktree(&wt1.id, "agent-1", 600)
            .unwrap();
        agent_store
            .try_claim_worktree(&wt2.id, "agent-2", 600)
            .unwrap();

        let leases = agent_store.list_active_worktree_leases().unwrap();
        assert_eq!(leases.len(), 2);
    }

    // ============================================
    // TEST: Agent death releases worktree leases
    // ============================================

    #[test]
    fn test_mark_dead_releases_worktree_leases() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent = Agent::new("agent-dead".to_string(), "Dead Agent".to_string());
        agent_store.register(&agent).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-dead");

        agent_store
            .try_claim_worktree(&worktree.id, "agent-dead", 600)
            .unwrap();

        // Mark agent as stale
        agent_store.mark_stale("agent-dead").unwrap();

        // Verify no active worktree lease
        let lease = agent_store.get_worktree_lease(&worktree.id).unwrap();
        assert!(lease.is_none());

        // Another agent can now claim
        let agent2 = Agent::new("agent-alive".to_string(), "Alive".to_string());
        agent_store.register(&agent2).unwrap();

        let result = agent_store
            .try_claim_worktree(&worktree.id, "agent-alive", 600)
            .unwrap();
        assert!(result.is_success());
    }

    // ============================================
    // TEST: Graceful shutdown releases worktree leases
    // ============================================

    #[test]
    fn test_graceful_shutdown_releases_worktree_leases() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent = Agent::new("agent-shutdown".to_string(), "Shutdown Agent".to_string());
        agent_store.register(&agent).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-shutdown");

        agent_store
            .try_claim_worktree(&worktree.id, "agent-shutdown", 600)
            .unwrap();

        // Graceful shutdown
        agent_store.graceful_shutdown("agent-shutdown").unwrap();

        // Verify no active worktree lease
        let lease = agent_store.get_worktree_lease(&worktree.id).unwrap();
        assert!(lease.is_none());
    }

    // ============================================
    // TEST: Get worktree lease for epic
    // ============================================

    #[test]
    fn test_get_worktree_lease_for_epic() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        agent_store.register(&agent).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-lookup");

        agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 600)
            .unwrap();

        // Should be able to find lease by epic ID
        let lease = agent_store
            .get_worktree_lease_for_epic("epic-lookup")
            .unwrap();
        assert!(lease.is_some());
        assert_eq!(lease.unwrap().agent_id, "agent-1");

        // Non-existent epic
        let lease = agent_store
            .get_worktree_lease_for_epic("epic-nonexistent")
            .unwrap();
        assert!(lease.is_none());
    }

    // ============================================
    // TEST: Check if agent can work on epic
    // ============================================

    #[test]
    fn test_can_agent_work_on_epic() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent1 = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        let agent2 = Agent::new("agent-2".to_string(), "Agent 2".to_string());
        agent_store.register(&agent1).unwrap();
        agent_store.register(&agent2).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-access");

        // No lock yet - both can work
        assert!(
            agent_store
                .can_agent_work_on_epic("agent-1", "epic-access")
                .unwrap()
        );
        assert!(
            agent_store
                .can_agent_work_on_epic("agent-2", "epic-access")
                .unwrap()
        );

        // Agent 1 claims worktree
        agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 600)
            .unwrap();

        // Agent 1 can still work, agent 2 cannot
        assert!(
            agent_store
                .can_agent_work_on_epic("agent-1", "epic-access")
                .unwrap()
        );
        assert!(
            !agent_store
                .can_agent_work_on_epic("agent-2", "epic-access")
                .unwrap()
        );
    }
}
