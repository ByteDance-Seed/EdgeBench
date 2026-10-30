use crate::Result;
use crate::agent_store::SqliteAgentStore;
use cas_types::Agent;
use chrono::Utc;
use rusqlite::params;

impl SqliteAgentStore {
    pub(crate) fn coord_get_active_children(&self, agent_id: &str) -> Result<Vec<Agent>> { todo!() }
    pub(crate) fn coord_graceful_shutdown(&self, agent_id: &str) -> Result<Vec<String>> { todo!() }
    pub(crate) fn coord_add_working_epic(&self, agent_id: &str, epic_id: &str) -> Result<()> { todo!() }
    pub(crate) fn coord_get_working_epics(&self, agent_id: &str) -> Result<Vec<String>> { todo!() }
    pub(crate) fn coord_list_all_working_epics(&self) -> Result<Vec<String>> { todo!() }
    pub(crate) fn coord_list_orphaned_working_epics(&self) -> Result<Vec<String>> { todo!() }
    pub(crate) fn coord_remove_working_epic(&self, agent_id: &str, epic_id: &str) -> Result<()> { todo!() }
    pub(crate) fn coord_clear_working_epics(&self, agent_id: &str) -> Result<()> { todo!() }
    pub(crate) fn coord_register_daemon(&self, daemon_id: &str, daemon_type: &str) -> Result<()> { todo!() }
    pub(crate) fn coord_daemon_heartbeat(&self, daemon_id: &str) -> Result<()> { todo!() }
    pub(crate) fn coord_unregister_daemon(&self, daemon_id: &str) -> Result<()> { todo!() }
    pub(crate) fn coord_is_daemon_active(&self, threshold_secs: i64) -> Result<bool> { todo!() }

    // Worktree lease operations
}
