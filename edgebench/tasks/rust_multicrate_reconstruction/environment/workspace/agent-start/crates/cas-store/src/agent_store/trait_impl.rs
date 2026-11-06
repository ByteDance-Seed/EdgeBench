use crate::Result;
use crate::agent_store::{AgentStore, LeaseHistoryEntry, SqliteAgentStore};
use cas_types::{Agent, AgentStatus, ClaimResult, TaskLease, WorktreeClaimResult, WorktreeLease};

impl AgentStore for SqliteAgentStore {
    fn init(&self) -> Result<()> { todo!() }
    fn register(&self, agent: &Agent) -> Result<()> { todo!() }
    fn get(&self, id: &str) -> Result<Agent> { todo!() }
    fn update(&self, agent: &Agent) -> Result<()> { todo!() }
    fn unregister(&self, id: &str) -> Result<()> { todo!() }
    fn list(&self, status: Option<AgentStatus>) -> Result<Vec<Agent>> { todo!() }
    fn list_stale(&self, timeout_secs: i64) -> Result<Vec<Agent>> { todo!() }
    fn heartbeat(&self, id: &str) -> Result<()> { todo!() }
    fn mark_stale(&self, id: &str) -> Result<()> { todo!() }
    fn revive(&self, id: &str) -> Result<()> { todo!() }
    fn get_by_cc_pid(&self, cc_pid: u32) -> Result<Option<Agent>> { todo!() }

    fn try_claim(
        &self,
        task_id: &str,
        agent_id: &str,
        duration_secs: i64,
        reason: Option<&str>,
    ) -> Result<ClaimResult> { todo!() }
    fn release_lease(&self, task_id: &str, agent_id: &str) -> Result<()> { todo!() }
    fn release_lease_for_task(&self, task_id: &str) -> Result<bool> { todo!() }
    fn renew_lease(&self, task_id: &str, agent_id: &str, duration_secs: i64) -> Result<()> { todo!() }
    fn get_lease(&self, task_id: &str) -> Result<Option<TaskLease>> { todo!() }
    fn list_agent_leases(&self, agent_id: &str) -> Result<Vec<TaskLease>> { todo!() }
    fn list_active_leases(&self) -> Result<Vec<TaskLease>> { todo!() }
    fn reclaim_expired_leases(&self) -> Result<usize> { todo!() }
    fn get_lease_history(
        &self,
        task_id: &str,
        limit: Option<usize>,
    ) -> Result<Vec<LeaseHistoryEntry>> { todo!() }
    fn get_agent_worked_tasks(
        &self,
        agent_id: &str,
        since: Option<chrono::DateTime<chrono::Utc>>,
    ) -> Result<Vec<String>> { todo!() }

    fn get_active_children(&self, agent_id: &str) -> Result<Vec<Agent>> { todo!() }
    fn graceful_shutdown(&self, agent_id: &str) -> Result<Vec<String>> { todo!() }
    fn add_working_epic(&self, agent_id: &str, epic_id: &str) -> Result<()> { todo!() }
    fn get_working_epics(&self, agent_id: &str) -> Result<Vec<String>> { todo!() }
    fn list_all_working_epics(&self) -> Result<Vec<String>> { todo!() }
    fn list_orphaned_working_epics(&self) -> Result<Vec<String>> { todo!() }
    fn remove_working_epic(&self, agent_id: &str, epic_id: &str) -> Result<()> { todo!() }
    fn clear_working_epics(&self, agent_id: &str) -> Result<()> { todo!() }
    fn register_daemon(&self, daemon_id: &str, daemon_type: &str) -> Result<()> { todo!() }
    fn daemon_heartbeat(&self, daemon_id: &str) -> Result<()> { todo!() }
    fn unregister_daemon(&self, daemon_id: &str) -> Result<()> { todo!() }
    fn is_daemon_active(&self, threshold_secs: i64) -> Result<bool> { todo!() }

    fn try_claim_worktree(
        &self,
        worktree_id: &str,
        agent_id: &str,
        duration_secs: i64,
    ) -> Result<WorktreeClaimResult> { todo!() }
    fn release_worktree_lease(&self, worktree_id: &str, agent_id: &str) -> Result<()> { todo!() }
    fn renew_worktree_lease(
        &self,
        worktree_id: &str,
        agent_id: &str,
        duration_secs: i64,
    ) -> Result<()> { todo!() }
    fn get_worktree_lease(&self, worktree_id: &str) -> Result<Option<WorktreeLease>> { todo!() }
    fn get_worktree_lease_for_epic(&self, epic_id: &str) -> Result<Option<WorktreeLease>> { todo!() }
    fn list_agent_worktree_leases(&self, agent_id: &str) -> Result<Vec<WorktreeLease>> { todo!() }
    fn list_active_worktree_leases(&self) -> Result<Vec<WorktreeLease>> { todo!() }
    fn reclaim_expired_worktree_leases(&self) -> Result<usize> { todo!() }
    fn can_agent_work_on_epic(&self, agent_id: &str, epic_id: &str) -> Result<bool> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}
