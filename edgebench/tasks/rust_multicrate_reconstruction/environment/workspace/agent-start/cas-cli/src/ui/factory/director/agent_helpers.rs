//! Shared helpers for agent status display across factory panels.
//!
//! Consolidates heartbeat detection, status icon/color resolution,
//! agent counting, and task lookup logic used by factory_radar,
//! mission_workers, and mission_epic.

use cas_types::{AgentStatus, TaskStatus};
use chrono::Utc;
use ratatui::prelude::Color;

use super::data::DirectorData;
use crate::ui::theme::{Icons, Palette};

/// Agents with no heartbeat for this many seconds are considered disconnected.
pub const HEARTBEAT_TIMEOUT_SECS: i64 = 300;

/// Returns the number of seconds since the agent's last heartbeat,
/// or `i64::MAX` if no heartbeat has been recorded.
pub fn heartbeat_age_secs(agent: &cas_factory::AgentSummary) -> i64 { todo!() }

/// Whether the agent should be treated as disconnected.
pub fn is_disconnected(agent: &cas_factory::AgentSummary) -> bool { todo!() }

/// Resolve the status icon string and color for an agent.
///
/// Takes heartbeat into account: disconnected agents always show the dead icon
/// regardless of their reported status.
pub fn agent_status_icon(
    agent: &cas_factory::AgentSummary,
    palette: &Palette,
) -> (&'static str, Color) { todo!() }

/// Resolve agent status icon using simple Unicode characters (for compact views).
pub fn agent_status_icon_simple(
    agent: &cas_factory::AgentSummary,
    palette: &Palette,
) -> (&'static str, Color) { todo!() }

/// Heartbeat-aware agent status counts.
#[derive(Debug, Default)]
pub struct AgentStatusCounts {
    pub active: usize,
    pub idle: usize,
    pub dead: usize,
}

/// Count agents by effective status, treating disconnected agents as dead.
pub fn count_agent_statuses(agents: &[cas_factory::AgentSummary]) -> AgentStatusCounts { todo!() }

/// Find the task currently assigned to an agent.
///
/// Searches in_progress_tasks first, then ready_tasks.
pub fn find_agent_task<'a>(
    agent: &cas_factory::AgentSummary,
    data: &'a DirectorData,
) -> Option<&'a cas_factory::TaskSummary> { todo!() }

/// Map a task status to a display icon.
pub fn task_status_icon(status: TaskStatus) -> &'static str { todo!() }
