use crate::Result;
use crate::agent_store::SqliteAgentStore;
use crate::error::StoreError;
use cas_types::{LeaseStatus, WorktreeClaimResult, WorktreeLease};
use chrono::Utc;
use rusqlite::{OptionalExtension, params};

impl SqliteAgentStore {
    pub(crate) fn worktree_try_claim_worktree(
        &self,
        worktree_id: &str,
        agent_id: &str,
        duration_secs: i64,
    ) -> Result<WorktreeClaimResult> { todo!() }
    pub(crate) fn worktree_release_worktree_lease(
        &self,
        worktree_id: &str,
        agent_id: &str,
    ) -> Result<()> { todo!() }
    pub(crate) fn worktree_renew_worktree_lease(
        &self,
        worktree_id: &str,
        agent_id: &str,
        duration_secs: i64,
    ) -> Result<()> { todo!() }
    pub(crate) fn worktree_get_worktree_lease(
        &self,
        worktree_id: &str,
    ) -> Result<Option<WorktreeLease>> { todo!() }
    pub(crate) fn worktree_get_worktree_lease_for_epic(
        &self,
        epic_id: &str,
    ) -> Result<Option<WorktreeLease>> { todo!() }
    pub(crate) fn worktree_list_agent_worktree_leases(
        &self,
        agent_id: &str,
    ) -> Result<Vec<WorktreeLease>> { todo!() }
    pub(crate) fn worktree_list_active_worktree_leases(&self) -> Result<Vec<WorktreeLease>> { todo!() }
    pub(crate) fn worktree_reclaim_expired_worktree_leases(&self) -> Result<usize> { todo!() }
    pub(crate) fn worktree_can_agent_work_on_epic(
        &self,
        agent_id: &str,
        epic_id: &str,
    ) -> Result<bool> { todo!() }
    pub(crate) fn worktree_close(&self) -> Result<()> { todo!() }
}
