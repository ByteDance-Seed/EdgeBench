use crate::Result;
use crate::agent_store::{AGENT_SCHEMA, SqliteAgentStore};
use crate::error::StoreError;
use crate::event_store::record_event_with_conn;
use crate::recording_store::capture_agent_event;
use cas_types::{Agent, AgentStatus, Event, EventEntityType, EventType, RecordingEventType};
use chrono::Utc;
use rusqlite::{OptionalExtension, params};

impl SqliteAgentStore {
    pub(crate) fn agent_init(&self) -> Result<()> { todo!() }
    pub(crate) fn agent_register(&self, agent: &Agent) -> Result<()> { todo!() }
    pub(crate) fn agent_get(&self, id: &str) -> Result<Agent> { todo!() }
    pub(crate) fn agent_update(&self, agent: &Agent) -> Result<()> { todo!() }
    pub(crate) fn agent_unregister(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn agent_list(&self, status: Option<AgentStatus>) -> Result<Vec<Agent>> { todo!() }
    pub(crate) fn agent_list_stale(&self, timeout_secs: i64) -> Result<Vec<Agent>> { todo!() }
    pub(crate) fn agent_heartbeat(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn agent_mark_stale(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn agent_revive(&self, id: &str) -> Result<()> { todo!() }
    pub(crate) fn agent_get_by_cc_pid(&self, cc_pid: u32) -> Result<Option<Agent>> { todo!() }
}
