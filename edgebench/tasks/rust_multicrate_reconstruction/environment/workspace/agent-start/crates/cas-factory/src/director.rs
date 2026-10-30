//! Data loading for the director panel.
//!
//! This module provides DirectorData aggregation from CAS stores,
//! without any TUI/rendering dependencies.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::process::Command;

use cas_store::{
    AgentStore, EventStore, Reminder, ReminderStore, SqliteAgentStore, SqliteEventStore,
    SqliteReminderStore, SqliteTaskStore, SqliteWorktreeStore, TaskStore, WorktreeStore,
};
use cas_types::{
    AgentRole, AgentStatus, DependencyType, Event, EventType, Priority, Task, TaskStatus, TaskType,
    WorktreeStatus,
};

use crate::changes::{FileChangeInfo, GitFileStatus, SourceChangesInfo};

/// A summary of a task for display
#[derive(Debug, Clone)]
pub struct TaskSummary {
    pub id: String,
    pub title: String,
    pub status: TaskStatus,
    pub priority: Priority,
    pub assignee: Option<String>,
    pub task_type: TaskType,
    /// Parent epic ID (if this is a subtask)
    pub epic: Option<String>,
    /// Branch name (for epics)
    pub branch: Option<String>,
}

/// A summary of an agent for display
#[derive(Debug, Clone)]
pub struct AgentSummary {
    pub id: String,
    pub name: String,
    pub status: AgentStatus,
    pub current_task: Option<String>,
    /// Latest activity (description, timestamp)
    pub latest_activity: Option<(String, chrono::DateTime<chrono::Utc>)>,
    /// Last heartbeat timestamp
    pub last_heartbeat: Option<chrono::DateTime<chrono::Utc>>,
}

/// A group of tasks under an epic
#[derive(Debug, Clone)]
pub struct EpicGroup {
    /// The epic task itself
    pub epic: TaskSummary,
    /// Subtasks belonging to this epic
    pub subtasks: Vec<TaskSummary>,
    /// Whether any subtask is in_progress
    pub has_active: bool,
}

/// Data for the director panel
#[derive(Debug, Clone)]
pub struct DirectorData {
    /// Ready tasks (open, not blocked)
    pub ready_tasks: Vec<TaskSummary>,
    /// In-progress tasks
    pub in_progress_tasks: Vec<TaskSummary>,
    /// Epic tasks (for tracking epic status)
    pub epic_tasks: Vec<TaskSummary>,
    /// Active agents
    pub agents: Vec<AgentSummary>,
    /// Recent activity events
    pub activity: Vec<Event>,
    /// Map of agent ID to name
    pub agent_id_to_name: HashMap<String, String>,
    /// Git changes by source (main repo + worktrees)
    pub changes: Vec<SourceChangesInfo>,
    /// Whether git changes have been loaded (for lazy loading)
    pub git_loaded: bool,
    /// Pending reminders (across all supervisors in this session)
    pub reminders: Vec<Reminder>,
    /// Count of closed subtasks per epic (epic_id -> closed_count)
    pub epic_closed_counts: HashMap<String, usize>,
}

impl DirectorData {
    /// Load data from CAS stores
    ///
    /// # Arguments
    /// * `cas_dir` - Path to the CAS directory
    /// * `worktree_root` - Optional path to the worktree directory for factory workers
    pub fn load(cas_dir: &Path, worktree_root: Option<&Path>) -> anyhow::Result<Self> { todo!() }

    /// Fast load without git changes (for initial startup)
    ///
    /// Git changes are loaded lazily on first refresh to speed up daemon startup.
    pub fn load_fast(cas_dir: &Path) -> anyhow::Result<Self> { todo!() }

    /// Load data with optional git change collection.
    ///
    /// This allows callers to refresh CAS data frequently while throttling expensive git ops.
    pub fn load_with_git(
        cas_dir: &Path,
        worktree_root: Option<&Path>,
        load_git: bool,
    ) -> anyhow::Result<Self> { todo!() }

    /// Refresh only git changes while preserving already-loaded task/agent/activity data.
    pub fn refresh_git_changes(
        &mut self,
        cas_dir: &Path,
        worktree_root: Option<&Path>,
    ) -> anyhow::Result<()> { todo!() }

    /// Load data with configurable options
    fn load_with_options(
        cas_dir: &Path,
        worktree_root: Option<&Path>,
        load_git: bool,
    ) -> anyhow::Result<Self> { todo!() }

    /// Get all tasks (in_progress + ready) grouped by epic
    ///
    /// Returns (epic_groups, standalone_tasks) where:
    /// - epic_groups: Tasks grouped under their parent epic
    /// - standalone_tasks: Tasks without a parent epic
    pub fn tasks_by_epic(&self) -> (Vec<EpicGroup>, Vec<TaskSummary>) { todo!() }
}

/// A repo to check for git changes
struct RepoToCheck {
    path: PathBuf,
    name: String,
    agent_name: Option<String>,
}

/// Load git changes from main repo and factory worktrees
///
/// Uses rayon for parallel git operations to support 1000+ workers.
fn load_all_git_changes(
    cas_dir: &Path,
    worktree_root: Option<&Path>,
    agent_id_to_name: &HashMap<String, String>,
) -> anyhow::Result<Vec<SourceChangesInfo>> { todo!() }

/// Get git changes for a single source directory
fn get_source_changes(
    path: &Path,
    name: &str,
    agent_name: Option<String>,
) -> Option<SourceChangesInfo> { todo!() }

/// Get git changes for a directory
fn get_git_changes(repo_path: &Path) -> Vec<FileChangeInfo> { todo!() }

/// Parse git diff --numstat output
fn parse_diff_numstat(output: &str, line_counts: &mut HashMap<String, (usize, usize)>) { todo!() }

/// Count lines in a file (for new/untracked files)
fn count_file_lines(path: &Path) -> (usize, usize) { todo!() }
