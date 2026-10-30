use crate::Result;
use crate::agent_store::{LeaseHistoryEntry, SqliteAgentStore};
use crate::error::StoreError;
use cas_types::{ClaimResult, LeaseStatus, TaskLease};
use chrono::Utc;
use rusqlite::{OptionalExtension, params};

impl SqliteAgentStore {
    pub(crate) fn lease_try_claim(
        &self,
        task_id: &str,
        agent_id: &str,
        duration_secs: i64,
        reason: Option<&str>,
    ) -> Result<ClaimResult> { todo!() }
    pub(crate) fn lease_release_lease(&self, task_id: &str, agent_id: &str) -> Result<()> { todo!() }
    pub(crate) fn lease_release_lease_for_task(&self, task_id: &str) -> Result<bool> { todo!() }
    pub(crate) fn lease_renew_lease(
        &self,
        task_id: &str,
        agent_id: &str,
        duration_secs: i64,
    ) -> Result<()> { todo!() }
    pub(crate) fn lease_get_lease(&self, task_id: &str) -> Result<Option<TaskLease>> { todo!() }
    pub(crate) fn lease_list_agent_leases(&self, agent_id: &str) -> Result<Vec<TaskLease>> { todo!() }
    pub(crate) fn lease_list_active_leases(&self) -> Result<Vec<TaskLease>> { todo!() }
    pub(crate) fn lease_reclaim_expired_leases(&self) -> Result<usize> { todo!() }
    pub(crate) fn lease_get_lease_history(
        &self,
        task_id: &str,
        limit: Option<usize>,
    ) -> Result<Vec<LeaseHistoryEntry>> { todo!() }
    pub(crate) fn lease_get_agent_worked_tasks(
        &self,
        agent_id: &str,
        since: Option<chrono::DateTime<chrono::Utc>>,
    ) -> Result<Vec<String>> { todo!() }
}
