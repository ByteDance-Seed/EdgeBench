use std::io;

use crate::cli::{Cli, ListArgs};
use crate::store::{find_cas_root_from, open_agent_store, open_prompt_queue_store};
use crate::ui::components::{Formatter, KeyValue, Renderable, StatusLine};
use crate::ui::factory::{SessionInfo, SessionManager, list_sessions};
use crate::ui::theme::ActiveTheme;
use anyhow::{Result, anyhow, bail};
use cas_factory::{DirectorData, SessionType};
use cas_types::{AgentStatus, Event};
use serde::Serialize;

/// List running factory sessions
pub fn execute_list(cli: &Cli, args: &ListArgs) -> Result<()> { todo!() }

pub(super) fn execute_sessions(cli: &Cli, attachable_only: bool) -> Result<()> { todo!() }

pub(super) fn execute_agents(
    cli: &Cli,
    session_name: Option<&str>,
    project_dir: Option<&std::path::Path>,
    all: bool,
    cas_root_override: Option<&std::path::Path>,
) -> Result<()> { todo!() }

pub(super) fn execute_activity(
    cli: &Cli,
    session_name: Option<&str>,
    project_dir: Option<&std::path::Path>,
    all: bool,
    limit: usize,
    cas_root_override: Option<&std::path::Path>,
) -> Result<()> { todo!() }

pub(super) fn execute_targets(
    cli: &Cli,
    session_name: Option<&str>,
    project_dir: Option<&std::path::Path>,
) -> Result<()> { todo!() }

pub(super) fn execute_status(
    cli: &Cli,
    session_name: Option<&str>,
    project_dir: Option<&std::path::Path>,
    activity_limit: usize,
    cas_root_override: Option<&std::path::Path>,
) -> Result<()> { todo!() }

#[allow(clippy::too_many_arguments)]
pub(super) fn execute_message(
    cli: &Cli,
    session_name: Option<&str>,
    project_dir: Option<&std::path::Path>,
    target: &str,
    message: &str,
    from: &str,
    no_wrap: bool,
    wait_ack: bool,
    timeout_ms: u64,
    cas_root_override: Option<&std::path::Path>,
) -> Result<()> { todo!() }

fn resolve_project_dir(project_dir: Option<&std::path::Path>) -> Result<std::path::PathBuf> { todo!() }

fn resolve_session(
    session_name: Option<&str>,
    project_dir: &std::path::Path,
) -> Result<SessionInfo> { todo!() }

fn cas_root_for_session(session: &SessionInfo) -> Result<std::path::PathBuf> { todo!() }

fn session_agent_name_set(session: &SessionInfo) -> std::collections::HashSet<String> { todo!() }

fn filter_events_for_session_agents(
    events: &mut Vec<Event>,
    allowed_names: &std::collections::HashSet<String>,
) { todo!() }

fn session_type_badge_plain(session_type: SessionType) -> &'static str { todo!() }

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct SessionListJson {
    schema_version: u32,
    sessions: Vec<SessionJson>,
}

impl SessionListJson {
    fn new(sessions: Vec<SessionJson>) -> Self { todo!() }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct SessionJson {
    name: String,
    created_at: String,
    daemon_pid: u32,
    socket_path: String,
    ws_port: Option<u16>,
    project_dir: Option<String>,
    epic_id: Option<String>,
    supervisor: String,
    workers: Vec<String>,
    is_running: bool,
    socket_exists: bool,
    can_attach: bool,

    #[serde(skip_serializing_if = "Option::is_none")]
    metadata: Option<serde_json::Value>,
}

impl SessionJson {
    fn from_session_info(session: &SessionInfo, include_metadata: bool) -> Self { todo!() }
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct AgentsJson {
    schema_version: u32,
    session: SessionJson,
    agents: Vec<AgentJson>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct AgentJson {
    id: String,
    name: String,
    role: String,
    status: String,
    last_heartbeat_rfc3339: String,
    seconds_since_heartbeat: i64,
    #[serde(skip_serializing_if = "std::collections::HashMap::is_empty")]
    metadata: std::collections::HashMap<String, String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct ActivityJson {
    schema_version: u32,
    session: SessionJson,
    events: Vec<Event>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct TargetsJson {
    schema_version: u32,
    session: SessionJson,
    supervisor: String,
    workers: Vec<String>,
    aliases: std::collections::HashMap<String, String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct StatusJson {
    schema_version: u32,
    session: SessionJson,
    prompt_queue_pending: usize,
    prompt_queue_peek: Vec<QueuedPromptJson>,
    tasks_ready: Vec<TaskSummaryJson>,
    tasks_in_progress: Vec<TaskSummaryJson>,
    epics: Vec<TaskSummaryJson>,
    agents: Vec<AgentSummaryJson>,
    activity: Vec<Event>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct TaskSummaryJson {
    id: String,
    title: String,
    status: String,
    priority: i32,
    assignee: Option<String>,
    task_type: String,
    epic: Option<String>,
    branch: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct AgentSummaryJson {
    id: String,
    name: String,
    status: String,
    current_task: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    latest_activity: Option<AgentLatestActivityJson>,
    #[serde(skip_serializing_if = "Option::is_none")]
    last_heartbeat_rfc3339: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct AgentLatestActivityJson {
    summary: String,
    created_at_rfc3339: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
struct QueuedPromptJson {
    id: i64,
    source: String,
    target: String,
    created_at_rfc3339: String,
}
