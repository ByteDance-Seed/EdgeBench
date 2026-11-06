//! Status line command for Claude Code integration
//!
//! Outputs a single-line status suitable for Claude Code's statusLine feature.
//! Designed to be fast and informative at a glance.

use std::path::Path;

use clap::Parser;
use serde::{Deserialize, Serialize};
use std::io::{self, Read, Write};

use crate::cli::statusline::data_and_format::{collect_status_data, format_status_line};
use crate::types::AgentRole;

use crate::cli::Cli;

/// ANSI color codes for terminal output
mod colors {
    pub const RESET: &str = "\x1b[0m";
    pub const GREEN: &str = "\x1b[32m";
    pub const YELLOW: &str = "\x1b[33m";
    pub const RED: &str = "\x1b[31m";
    pub const CYAN: &str = "\x1b[36m";
    pub const DIM: &str = "\x1b[2m";
    pub const BOLD: &str = "\x1b[1m";
}

#[derive(Parser)]
pub struct StatusLineArgs {
    /// Output raw JSON data instead of formatted line
    #[arg(long)]
    pub json: bool,

    /// Disable colors in output
    #[arg(long)]
    pub no_color: bool,

    /// Show minimal output (just counts)
    #[arg(long, short)]
    pub minimal: bool,

    /// Include session info from stdin (Claude Code passes JSON)
    #[arg(long)]
    pub with_session: bool,
}

/// Input from Claude Code's status line feature
#[derive(Debug, Deserialize)]
#[serde(rename_all = "snake_case")]
#[allow(dead_code)]
struct ClaudeCodeInput {
    hook_event_name: Option<String>,
    session_id: Option<String>,
    cwd: Option<String>,
    model: Option<ModelInfo>,
    workspace: Option<WorkspaceInfo>,
    cost: Option<CostInfo>,
    context_window: Option<ContextWindowInfo>,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct ModelInfo {
    id: Option<String>,
    display_name: Option<String>,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct WorkspaceInfo {
    current_dir: Option<String>,
    project_dir: Option<String>,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct CostInfo {
    total_cost_usd: Option<f64>,
    total_duration_ms: Option<u64>,
}

#[derive(Debug, Deserialize)]
#[allow(dead_code)]
struct ContextWindowInfo {
    total_input_tokens: Option<u64>,
    total_output_tokens: Option<u64>,
    context_window_size: Option<u64>,
}

/// Status line data structure for JSON output
#[derive(Debug, Serialize)]
pub struct StatusLineData {
    pub agents: AgentCounts,
    pub tasks: TaskCounts,
    pub memories: MemoryCounts,
    pub rules: RuleCounts,
    pub skills: SkillCounts,
    pub worktrees: WorktreeCounts,
    pub health: HealthStatus,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub update: Option<UpdateInfo>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session: Option<SessionInfo>,
    /// Multi-agent context: my tasks and other agents' work
    pub agent_context: AgentContext,
}

#[derive(Debug, Serialize)]
pub struct AgentCounts {
    pub active: usize,
    pub total: usize,
    pub claimed_tasks: usize,
}

#[derive(Debug, Serialize)]
pub struct TaskCounts {
    pub ready: usize,
    pub in_progress: usize,
    pub blocked: usize,
    pub claimed: usize,
    pub available: usize,
    pub total_open: usize,
    /// Tasks that are InProgress but have no active lease (orphaned/interrupted work)
    pub orphaned: usize,
}

#[derive(Debug, Serialize)]
pub struct MemoryCounts {
    pub total: usize,
    pub pinned: usize,
    pub helpful: usize,
    pub pending_extraction: usize,
}

#[derive(Debug, Serialize)]
pub struct RuleCounts {
    pub total: usize,
    pub proven: usize,
    pub stale: usize,
}

#[derive(Debug, Serialize)]
pub struct SkillCounts {
    pub total: usize,
    pub enabled: usize,
}

#[derive(Debug, Serialize)]
pub struct WorktreeCounts {
    pub active: usize,
    pub orphaned: usize,
    pub in_worktree: bool,
    pub current_branch: Option<String>,
}

#[derive(Debug, Serialize)]
pub struct HealthStatus {
    pub daemon_running: bool,
    pub has_pending_work: bool,
    pub has_blocked_tasks: bool,
    pub status: String, // "ok", "pending", "blocked", "degraded"
}

#[derive(Debug, Serialize)]
pub struct UpdateInfo {
    pub latest_version: String,
}

#[derive(Debug, Serialize)]
pub struct SessionInfo {
    pub model: Option<String>,
    pub context_pct: Option<u8>,
    /// Session ID for agent lookup
    #[serde(skip)]
    pub session_id: Option<String>,
}

/// Info about current agent's active task
#[derive(Debug, Clone, Serialize)]
pub struct MyTaskInfo {
    pub id: String,
    pub title: String,
    pub priority: i32,
    pub blocked_by: Vec<String>,
}

/// Info about other agents' work
#[derive(Debug, Clone, Serialize)]
pub struct OtherAgentWork {
    pub agent_id: String,
    pub agent_name: String,
    pub task_title: String,
}

/// Current agent context for multi-agent awareness
#[derive(Debug, Serialize)]
pub struct AgentContext {
    /// Current agent's ID (if identified via session)
    pub my_agent_id: Option<String>,
    /// Tasks I'm actively working on (claimed by me)
    pub my_tasks: Vec<MyTaskInfo>,
    /// Other agents that are actively working
    pub other_agents_working: Vec<OtherAgentWork>,
}

pub fn execute(args: &StatusLineArgs, cli: &Cli, cas_root: &Path) -> anyhow::Result<()> { todo!() }

fn read_claude_code_input() -> Option<SessionInfo> { todo!() }

mod data_and_format;
