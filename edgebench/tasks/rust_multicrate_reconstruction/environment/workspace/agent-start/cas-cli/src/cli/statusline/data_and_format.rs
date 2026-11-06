use crate::cli::statusline::colors;
use crate::cli::statusline::{
    AgentContext, AgentCounts, HealthStatus, MemoryCounts, MyTaskInfo, OtherAgentWork, RuleCounts,
    SessionInfo, SkillCounts, StatusLineData, TaskCounts, UpdateInfo, WorktreeCounts,
};
use crate::config::Config;
use crate::store::{
    open_agent_store, open_rule_store, open_skill_store, open_store, open_task_store,
    open_worktree_store,
};
use crate::types::{AgentStatus, RuleStatus, SkillStatus, TaskStatus};
use crate::worktree::GitOperations;
use cas_core::Syncer;
use cas_types::DependencyType;
use serde::{Deserialize, Serialize};
use std::time::{Duration, SystemTime, UNIX_EPOCH};

const UPDATE_CHECK_CACHE_TTL_SECS: u64 = 24 * 60 * 60;
const UPDATE_CHECK_CACHE_FAILURE_TTL_SECS: u64 = 60 * 60;
const UPDATE_CHECK_TIMEOUT_MS: u64 = 1200;
const UPDATE_CHECK_URL: &str = "https://example.invalid/cas/releases/latest";
const UPDATE_CHECK_CACHE_RELATIVE: &str = "cache/update-check.json";

#[derive(Debug, Clone, Serialize, Deserialize, Default)]
struct UpdateCheckCache {
    checked_at_unix: u64,
    latest_version: Option<String>,
    update_available: bool,
    failed: bool,
}

pub(crate) fn collect_status_data(
    session_info: Option<SessionInfo>,
    cas_root: std::path::PathBuf,
) -> anyhow::Result<StatusLineData> { todo!() }

fn get_update_info(cas_root: &std::path::Path, current_version: &str) -> Option<UpdateInfo> { todo!() }

fn read_update_cache(path: &std::path::Path) -> Option<UpdateCheckCache> { todo!() }

fn fetch_and_store_update_cache(
    cache_path: &std::path::Path,
    current_version: &str,
    checked_at_unix: u64,
    previous: Option<&UpdateCheckCache>,
) -> UpdateCheckCache { todo!() }

fn fetch_latest_version(current_version: &str) -> anyhow::Result<String> { todo!() }

fn now_unix() -> u64 { todo!() }

fn is_newer_version(new: &str, current: &str) -> bool { todo!() }

pub(crate) fn format_status_line(data: &StatusLineData, no_color: bool, minimal: bool) -> String { todo!() }

/// Format the status line in working mode (task-focused view)
fn format_working_mode(data: &StatusLineData, use_color: bool) -> String { todo!() }

/// Format the status line in idle mode (stats overview)
fn format_idle_mode(data: &StatusLineData, use_color: bool) -> String { todo!() }

fn format_minimal(data: &StatusLineData, use_color: bool) -> String { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_data() -> StatusLineData {
        StatusLineData {
            agents: AgentCounts {
                active: 1,
                total: 1,
                claimed_tasks: 0,
            },
            tasks: TaskCounts {
                ready: 2,
                in_progress: 0,
                blocked: 0,
                claimed: 0,
                available: 2,
                total_open: 2,
                orphaned: 0,
            },
            memories: MemoryCounts {
                total: 10,
                pinned: 0,
                helpful: 0,
                pending_extraction: 0,
            },
            rules: RuleCounts {
                total: 2,
                proven: 2,
                stale: 0,
            },
            skills: SkillCounts {
                total: 3,
                enabled: 2,
            },
            worktrees: WorktreeCounts {
                active: 0,
                orphaned: 0,
                in_worktree: false,
                current_branch: None,
            },
            health: HealthStatus {
                daemon_running: true,
                has_pending_work: false,
                has_blocked_tasks: false,
                status: "ok".to_string(),
            },
            update: None,
            session: None,
            agent_context: AgentContext {
                my_agent_id: None,
                my_tasks: vec![],
                other_agents_working: vec![],
            },
        }
    }

    #[test]
    fn newer_version_detection_handles_semver() {
        assert!(is_newer_version("0.5.5", "0.5.4"));
        assert!(is_newer_version("v1.0.0", "0.9.9"));
        assert!(!is_newer_version("0.5.4", "0.5.4"));
        assert!(!is_newer_version("0.5.3", "0.5.4"));
    }

    #[test]
    fn idle_mode_shows_update_segment() {
        let mut data = sample_data();
        data.update = Some(UpdateInfo {
            latest_version: "0.6.0".to_string(),
        });

        let line = format_idle_mode(&data, false);
        assert!(line.contains("⬆ v0.6.0 available"));
    }

    #[test]
    fn minimal_mode_shows_update_segment() {
        let mut data = sample_data();
        data.update = Some(UpdateInfo {
            latest_version: "0.6.0".to_string(),
        });

        let line = format_minimal(&data, false);
        assert!(line.contains("↑0.6.0"));
    }
}
