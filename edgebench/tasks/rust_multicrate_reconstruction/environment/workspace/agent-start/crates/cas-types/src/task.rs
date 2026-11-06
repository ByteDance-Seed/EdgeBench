//! Task type definitions
//!
//! Tasks are work items tracked by CAS

// Dead code check enabled - all items used

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;
use crate::scope::Scope;

/// Status of a task in its lifecycle
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum TaskStatus {
    /// Not yet started
    #[default]
    Open,
    /// Currently being worked on
    InProgress,
    /// Waiting on something
    Blocked,
    /// Completed
    Closed,
}

impl fmt::Display for TaskStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for TaskStatus {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Type of task
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum TaskType {
    /// Standard work item
    #[default]
    Task,
    /// Defect or problem
    Bug,
    /// New functionality
    Feature,
    /// Large work with subtasks
    Epic,
    /// Maintenance or cleanup
    Chore,
    /// Investigation or research (produces understanding, not code)
    Spike,
}

impl fmt::Display for TaskType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for TaskType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Priority level (0 = highest, 4 = lowest)
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize, Deserialize, Default)]
pub struct Priority(pub i32);

impl Priority {
    pub const CRITICAL: Priority = Priority(0);
    pub const HIGH: Priority = Priority(1);
    pub const MEDIUM: Priority = Priority(2);
    pub const LOW: Priority = Priority(3);
    pub const BACKLOG: Priority = Priority(4);

    pub fn label(&self) -> &'static str { todo!() }
}

impl fmt::Display for Priority {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl From<i32> for Priority {
    fn from(v: i32) -> Self { todo!() }
}

/// Deliverables captured when closing a task
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct TaskDeliverables {
    /// Files changed (excluding deletions)
    #[serde(default)]
    pub files_changed: Vec<String>,
    /// Commit hash created during auto-commit (if any)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub commit_hash: Option<String>,
    /// Merge commit hash for associated worktree (if any)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub merge_commit: Option<String>,
}

impl TaskDeliverables {
    pub fn is_empty(&self) -> bool { todo!() }
}

/// A task (work item) tracked by CAS
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Task {
    /// Unique identifier (e.g., cas-a1b2)
    pub id: String,

    /// Storage scope (global or project)
    /// Project scope is the default for tasks
    #[serde(default)]
    pub scope: Scope,

    /// Task title
    pub title: String,

    /// Problem statement, context (immutable after creation)
    #[serde(default)]
    pub description: String,

    /// Technical approach, architecture decisions
    #[serde(default)]
    pub design: String,

    /// Concrete deliverables checklist
    #[serde(default)]
    pub acceptance_criteria: String,

    /// Session handoff notes (COMPLETED/IN_PROGRESS/NEXT)
    #[serde(default)]
    pub notes: String,

    /// Current status
    #[serde(default)]
    pub status: TaskStatus,

    /// Priority level (0-4)
    #[serde(default)]
    pub priority: Priority,

    /// Type of task
    #[serde(default)]
    pub task_type: TaskType,

    /// Who is working on this
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub assignee: Option<String>,

    /// Optional labels for categorization
    #[serde(default)]
    pub labels: Vec<String>,

    /// When the task was created
    pub created_at: DateTime<Utc>,

    /// When the task was last updated
    pub updated_at: DateTime<Utc>,

    /// When the task was closed (if closed)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub closed_at: Option<DateTime<Utc>>,

    /// Why the task was closed
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub close_reason: Option<String>,

    /// Link to external tracker (GitHub, JIRA, etc.)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub external_ref: Option<String>,

    /// Content hash for deduplication
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub content_hash: Option<String>,

    /// Git branch this task is scoped to (None = visible from all branches)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub branch: Option<String>,

    /// Worktree this task was created in (for auto-cleanup)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub worktree_id: Option<String>,

    /// Whether this task is awaiting verification before close
    /// When true, the agent is "jailed" - only task-verifier can run
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    pub pending_verification: bool,

    /// Whether this task (epic) is awaiting worktree merge before close
    /// When true, the agent is "jailed" - only worktree-merger can run
    #[serde(default, skip_serializing_if = "std::ops::Not::not")]
    pub pending_worktree_merge: bool,

    /// Agent ID responsible for epic verification (supervisor in factory mode)
    /// When set, this agent (not the task closer) gets jailed for epic verification
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub epic_verification_owner: Option<String>,

    /// Task deliverables captured on close
    #[serde(default, skip_serializing_if = "TaskDeliverables::is_empty")]
    pub deliverables: TaskDeliverables,

    /// Team ID this task belongs to (None = personal/not shared with team)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub team_id: Option<String>,

    /// What can be demonstrated when this task is complete
    /// e.g., "Type a query, results filter live"
    #[serde(default)]
    pub demo_statement: String,
}

impl Task {
    /// Create a new task with the given ID and title
    pub fn new(id: String, title: String) -> Self { todo!() }

    /// Create a new task with a specific scope
    pub fn new_with_scope(id: String, title: String, scope: Scope) -> Self { todo!() }

    /// Check if the task is open (not closed)
    pub fn is_open(&self) -> bool { todo!() }

    /// Check if the task is ready to work on (open, not blocked)
    pub fn is_ready(&self) -> bool { todo!() }

    /// Get a short preview of the title
    pub fn preview(&self, max_len: usize) -> String { todo!() }
}

impl Default for Task {
    fn default() -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::task::*;

    #[test]
    fn test_task_status_from_str() {
        assert_eq!(TaskStatus::from_str("open").unwrap(), TaskStatus::Open);
        assert_eq!(
            TaskStatus::from_str("in_progress").unwrap(),
            TaskStatus::InProgress
        );
        assert_eq!(
            TaskStatus::from_str("in-progress").unwrap(),
            TaskStatus::InProgress
        );
        assert_eq!(
            TaskStatus::from_str("blocked").unwrap(),
            TaskStatus::Blocked
        );
        assert_eq!(TaskStatus::from_str("closed").unwrap(), TaskStatus::Closed);
        assert!(TaskStatus::from_str("invalid").is_err());
    }

    #[test]
    fn test_task_type_from_str() {
        assert_eq!(TaskType::from_str("task").unwrap(), TaskType::Task);
        assert_eq!(TaskType::from_str("bug").unwrap(), TaskType::Bug);
        assert_eq!(TaskType::from_str("feature").unwrap(), TaskType::Feature);
        assert_eq!(TaskType::from_str("epic").unwrap(), TaskType::Epic);
        assert_eq!(TaskType::from_str("chore").unwrap(), TaskType::Chore);
        assert_eq!(TaskType::from_str("spike").unwrap(), TaskType::Spike);
    }

    #[test]
    fn test_spike_task_type() {
        let spike = TaskType::Spike;
        assert_eq!(spike.to_string(), "spike");
        assert_eq!(TaskType::from_str("spike").unwrap(), TaskType::Spike);

        // Verify round-trip
        let s = spike.to_string();
        assert_eq!(TaskType::from_str(&s).unwrap(), TaskType::Spike);
    }

    #[test]
    fn test_priority() {
        assert!(Priority::CRITICAL < Priority::HIGH);
        assert!(Priority::HIGH < Priority::MEDIUM);
        assert_eq!(Priority::from(5), Priority(4)); // Clamped to max
        assert_eq!(Priority::from(-1), Priority(0)); // Clamped to min
    }

    #[test]
    fn test_task_new() {
        let task = Task::new("cas-a1b2".to_string(), "Test task".to_string());
        assert_eq!(task.id, "cas-a1b2");
        assert_eq!(task.title, "Test task");
        assert_eq!(task.status, TaskStatus::Open);
        assert_eq!(task.priority, Priority::MEDIUM);
        assert!(task.is_open());
        assert!(task.is_ready());
    }
}
