use cas_types::Event;
use serde::{Deserialize, Serialize};

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct ServeInfo {
    pub(crate) schema_version: u32,
    pub(crate) bind: String,
    pub(crate) port: u16,
    pub(crate) base_url: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub(crate) cas_root: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub(crate) token: Option<String>,
    pub(crate) auth_enabled: bool,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct Health {
    pub(crate) schema_version: u32,
    pub(crate) ok: bool,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct StartFactoryRequest {
    pub(crate) project_dir: String,
    #[serde(default)]
    pub(crate) workers: Option<u8>,
    #[serde(default)]
    pub(crate) name: Option<String>,
    #[serde(default)]
    pub(crate) supervisor_cli: Option<String>,
    #[serde(default)]
    pub(crate) worker_cli: Option<String>,
    #[serde(default)]
    pub(crate) no_worktrees: bool,
    #[serde(default)]
    pub(crate) worktree_root: Option<String>,
    #[serde(default)]
    pub(crate) notify: bool,
    #[serde(default)]
    pub(crate) tabbed: bool,
    #[serde(default)]
    pub(crate) record: bool,
    #[serde(default)]
    pub(crate) reuse_existing: bool,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct StartFactoryResponse {
    pub(crate) schema_version: u32,
    pub(crate) started: bool,
    pub(crate) reused_existing: bool,
    pub(crate) session: SessionJson,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct PingJson {
    pub(crate) schema_version: u32,
    pub(crate) ok: bool,
    pub(crate) session: SessionJson,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub(crate) cas_root: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct ActivityJson {
    pub(crate) schema_version: u32,
    pub(crate) session: SessionJson,
    pub(crate) activity: Vec<Event>,
    pub(crate) latest_id: Option<i64>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct InboxPeekJson {
    pub(crate) schema_version: u32,
    pub(crate) session: SessionJson,
    pub(crate) inbox_id: String,
    pub(crate) pending_count: usize,
    pub(crate) notifications: Vec<cas_store::SupervisorNotification>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct InboxPollJson {
    pub(crate) schema_version: u32,
    pub(crate) session: SessionJson,
    pub(crate) inbox_id: String,
    pub(crate) polled: usize,
    pub(crate) notifications: Vec<cas_store::SupervisorNotification>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct InboxAckJson {
    pub(crate) schema_version: u32,
    pub(crate) session: SessionJson,
    pub(crate) inbox_id: String,
    pub(crate) acked: bool,
    pub(crate) notification_id: i64,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct InboxCountJson {
    pub(crate) schema_version: u32,
    pub(crate) session: SessionJson,
    pub(crate) inbox_id: String,
    pub(crate) pending_count: usize,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct InboxAckRequest {
    pub(crate) notification_id: i64,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct SessionListJson {
    pub(crate) schema_version: u32,
    pub(crate) sessions: Vec<SessionJson>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct SessionJson {
    pub(crate) name: String,
    pub(crate) created_at: String,
    pub(crate) daemon_pid: u32,
    pub(crate) socket_path: String,
    pub(crate) ws_port: Option<u16>,
    pub(crate) project_dir: Option<String>,
    pub(crate) epic_id: Option<String>,
    pub(crate) supervisor: String,
    pub(crate) workers: Vec<String>,
    pub(crate) is_running: bool,
    pub(crate) socket_exists: bool,
    pub(crate) can_attach: bool,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct TargetsJson {
    pub(crate) schema_version: u32,
    pub(crate) session: SessionJson,
    pub(crate) supervisor: String,
    pub(crate) workers: Vec<String>,
    pub(crate) aliases: std::collections::HashMap<String, String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct StatusJson {
    pub(crate) schema_version: u32,
    pub(crate) session: SessionJson,
    pub(crate) prompt_queue_pending: usize,
    pub(crate) activity: Vec<Event>,
    pub(crate) agents: Vec<AgentSummaryJson>,
    pub(crate) tasks_ready: Vec<TaskSummaryJson>,
    pub(crate) tasks_in_progress: Vec<TaskSummaryJson>,
    pub(crate) epics: Vec<TaskSummaryJson>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct TaskSummaryJson {
    pub(crate) id: String,
    pub(crate) title: String,
    pub(crate) status: String,
    pub(crate) priority: i32,
    pub(crate) assignee: Option<String>,
    pub(crate) task_type: String,
    pub(crate) epic: Option<String>,
    pub(crate) branch: Option<String>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct AgentLatestActivityJson {
    pub(crate) summary: String,
    pub(crate) created_at_rfc3339: String,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct AgentSummaryJson {
    pub(crate) id: String,
    pub(crate) name: String,
    pub(crate) status: String,
    pub(crate) current_task: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub(crate) latest_activity: Option<AgentLatestActivityJson>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub(crate) last_heartbeat_rfc3339: Option<String>,
}

#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct MessageRequest {
    pub(crate) target: String,
    pub(crate) message: String,
    #[serde(default)]
    pub(crate) from: Option<String>,
    #[serde(default)]
    pub(crate) no_wrap: bool,
    #[serde(default)]
    pub(crate) wait_ack: bool,
    #[serde(default)]
    pub(crate) timeout_ms: Option<u64>,
}

#[derive(Debug, Serialize)]
#[serde(rename_all = "snake_case")]
pub(crate) struct MessageResponse {
    pub(crate) schema_version: u32,
    pub(crate) session: String,
    pub(crate) target: String,
    pub(crate) enqueued: bool,
    pub(crate) message_id: i64,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub(crate) ack_event_id: Option<i64>,
}

pub(crate) fn session_json(s: &crate::ui::factory::SessionInfo) -> SessionJson { todo!() }
