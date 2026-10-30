use rmcp::schemars::JsonSchema;
use serde::Deserialize;

use crate::mcp::tools::types::defaults::{default_agent_type, default_lease_duration};

#[derive(Debug, Deserialize, JsonSchema)]
pub struct SessionStartRequest {
    /// Optional session ID (if omitted, CAS generates one)
    #[schemars(description = "Optional session ID to use as the agent ID")]
    #[serde(default)]
    pub session_id: Option<String>,

    /// Optional agent name override
    #[schemars(description = "Human-readable agent name (optional)")]
    #[serde(default)]
    pub name: Option<String>,

    /// Optional agent type/role hint (e.g., worker, supervisor, primary)
    #[schemars(
        description = "Optional agent type/role hint for registration (worker, supervisor, primary, sub_agent, ci)"
    )]
    #[serde(default)]
    pub agent_type: Option<String>,

    /// Parent agent ID (for sub-agents)
    #[schemars(description = "Parent agent ID if this is a sub-agent")]
    #[serde(default)]
    pub parent_id: Option<String>,

    /// Permission mode hint (plan, acceptEdits, bypassPermissions)
    #[schemars(description = "Optional permission mode hint")]
    #[serde(default)]
    pub permission_mode: Option<String>,

    /// Working directory for context (defaults to project root)
    #[schemars(description = "Working directory for context (optional)")]
    #[serde(default)]
    pub cwd: Option<String>,

    /// Context entry limit
    #[schemars(description = "Maximum context entries to include (default: 5)")]
    #[serde(default)]
    pub limit: Option<usize>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct SessionEndRequest {
    /// Session ID to end (defaults to current agent session)
    #[schemars(description = "Session ID to end (optional)")]
    #[serde(default)]
    pub session_id: Option<String>,

    /// End reason (optional)
    #[schemars(description = "Reason for ending the session")]
    #[serde(default)]
    pub reason: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct AgentRegisterRequest {
    /// Agent name
    #[schemars(description = "Human-readable name for the agent (e.g., 'Claude Code - main')")]
    pub name: String,

    /// Agent type
    #[schemars(description = "Type: 'primary' (default), 'sub_agent', 'worker', 'ci'")]
    #[serde(default = "default_agent_type")]
    pub agent_type: String,

    /// Session ID from Claude Code
    #[schemars(description = "Session ID from Claude Code (optional)")]
    #[serde(default)]
    pub session_id: Option<String>,

    /// Parent agent ID (for sub-agents)
    #[schemars(description = "Parent agent ID if this is a sub-agent")]
    #[serde(default)]
    pub parent_id: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct TaskClaimRequest {
    /// Task ID to claim
    #[schemars(description = "ID of the task to claim")]
    pub task_id: String,

    /// Lease duration in seconds
    #[schemars(description = "Lease duration in seconds (default: 600 = 10 minutes)")]
    #[serde(default = "default_lease_duration")]
    pub duration_secs: i64,

    /// Reason for claiming
    #[schemars(description = "Optional reason for claiming the task")]
    #[serde(default)]
    pub reason: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct TaskReleaseRequest {
    /// Task ID to release
    #[schemars(description = "ID of the task to release")]
    pub task_id: String,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct LeaseRenewRequest {
    /// Task ID to renew lease for
    #[schemars(description = "ID of the task to renew lease for")]
    pub task_id: String,

    /// New lease duration in seconds
    #[schemars(description = "New lease duration in seconds (default: 600)")]
    #[serde(default = "default_lease_duration")]
    pub duration_secs: i64,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct TaskTransferRequest {
    /// Task ID to transfer
    #[schemars(description = "ID of the task to transfer")]
    pub task_id: String,

    /// Target agent ID
    #[schemars(description = "ID of the agent to transfer the task to")]
    pub to_agent: String,

    /// Handoff notes
    #[schemars(description = "Notes for the receiving agent about the work done and what remains")]
    #[serde(default)]
    pub note: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct AgentCleanupRequest {
    /// Stale threshold in seconds
    #[schemars(
        description = "Seconds since last heartbeat to consider an agent stale (default: 120)"
    )]
    #[serde(default)]
    pub stale_threshold_secs: Option<i64>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct LeaseHistoryRequest {
    /// Task ID to get history for
    #[schemars(description = "Task ID to get lease history for")]
    pub task_id: String,

    /// Maximum events to return
    #[schemars(description = "Maximum number of history events to return")]
    #[serde(default)]
    pub limit: Option<usize>,
}
