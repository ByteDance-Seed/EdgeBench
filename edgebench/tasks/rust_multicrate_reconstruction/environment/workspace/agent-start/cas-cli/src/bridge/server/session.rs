use anyhow::{Result, bail};
use cas_factory::DirectorData;
use cas_store::{EventStore, SqliteEventStore};
use cas_types::Event;

use crate::store::{find_cas_root_from, open_prompt_queue_store};

use crate::bridge::server::types::{
    AgentLatestActivityJson, AgentSummaryJson, StatusJson, TaskSummaryJson, session_json,
};

pub(crate) fn resolve_session_by_name(
    session_name: &str,
) -> Result<crate::ui::factory::SessionInfo> { todo!() }

pub(crate) fn cas_root_for_session_with_fallback(
    session: &crate::ui::factory::SessionInfo,
    fallback: Option<&std::path::Path>,
) -> Result<std::path::PathBuf> { todo!() }

pub(crate) fn filter_events_for_session_agents(
    events: &mut Vec<Event>,
    allowed: &std::collections::HashSet<String>,
) { todo!() }

pub(crate) fn allowed_agent_names(
    session: &crate::ui::factory::SessionInfo,
) -> std::collections::HashSet<String> { todo!() }

pub(crate) fn build_status_json(
    session: &crate::ui::factory::SessionInfo,
    cas_root: &std::path::Path,
    activity_limit: usize,
) -> Result<StatusJson> { todo!() }

pub(crate) fn wait_for_supervisor_ack(
    cas_root: &std::path::Path,
    message_id: i64,
    timeout_ms: u64,
) -> Result<Option<i64>> { todo!() }
