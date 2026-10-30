//! Event detection for the Director
//!
//! Detects state changes in CAS data by comparing snapshots.
//! Used to trigger auto-prompting and activity logging.

use std::collections::{HashMap, HashSet};
use std::time::{Duration, Instant};

use crate::ui::factory::director::data::{DirectorData, TaskSummary};
use cas_types::TaskStatus;

/// Debounce duration for events (don't emit same event within this window)
const DEBOUNCE_DURATION: Duration = Duration::from_secs(30);

/// Events detected from CAS state changes
#[derive(Debug, Clone)]
pub enum DirectorEvent {
    /// A task was assigned to a worker
    TaskAssigned {
        task_id: String,
        task_title: String,
        worker: String,
    },
    /// A task was completed
    TaskCompleted {
        task_id: String,
        task_title: String,
        worker: String,
    },
    /// A task was blocked
    TaskBlocked {
        task_id: String,
        task_title: String,
        worker: String,
    },
    /// A worker became idle (no in-progress tasks)
    WorkerIdle { worker: String },
    /// A new agent registered
    AgentRegistered {
        agent_id: String,
        agent_name: String,
    },
    /// An epic was started (detected by new epic-type task)
    EpicStarted { epic_id: String, epic_title: String },
    /// All tasks in an epic are complete
    EpicCompleted { epic_id: String },
}

impl DirectorEvent {
    /// Get the worker/agent this event targets (for prompt injection)
    pub fn target(&self) -> Option<&str> { todo!() }

    /// Get a description of the event for logging
    pub fn description(&self) -> String { todo!() }

    /// Get a unique key for debouncing this event
    ///
    /// Events with the same key are considered duplicates within the debounce window.
    pub fn debounce_key(&self) -> String { todo!() }

    /// Get the event type as a string (for recording export)
    pub fn event_type(&self) -> &'static str { todo!() }

    /// Convert event data to JSON (for recording export)
    pub fn to_json(&self) -> serde_json::Value { todo!() }
}

/// State snapshot for comparison
#[derive(Debug, Clone, Default)]
struct DirectorState {
    /// Map of task_id -> (status, assignee)
    tasks: HashMap<String, (TaskStatus, Option<String>)>,
    /// Map of task_id -> title (for lookup when tasks disappear from active sets)
    task_titles: HashMap<String, String>,
    /// Set of active agent IDs
    active_agents: HashSet<String>,
    /// Map of agent_id -> current_task_id
    agent_tasks: HashMap<String, Option<String>>,
    /// Map of epic_id -> status
    epic_statuses: HashMap<String, TaskStatus>,
}

impl DirectorState {
    fn from_data(data: &DirectorData) -> Self { todo!() }
}

/// Detects events by comparing CAS state snapshots
pub struct DirectorEventDetector {
    /// Previous state snapshot
    last_state: DirectorState,
    /// Factory worker names (for filtering)
    worker_names: Vec<String>,
    /// Supervisor name
    supervisor_name: String,
    /// Last prompt times for debouncing (event key -> instant)
    last_prompt_times: HashMap<String, Instant>,
}

impl DirectorEventDetector {
    /// Create a new event detector
    pub fn new(worker_names: Vec<String>, supervisor_name: String) -> Self { todo!() }

    /// Initialize with current state (call after first data load)
    pub fn initialize(&mut self, data: &DirectorData) { todo!() }

    /// Add a worker to the tracked list (call when spawning workers dynamically)
    pub fn add_worker(&mut self, name: String) { todo!() }

    /// Remove a worker from the tracked list (call when shutting down workers)
    pub fn remove_worker(&mut self, name: &str) { todo!() }

    /// Detect changes between the last state and new data
    ///
    /// Returns a list of detected events. Call this after each refresh.
    pub fn detect_changes(&mut self, data: &DirectorData) -> Vec<DirectorEvent> { todo!() }

    /// Filter out events that were emitted recently (within DEBOUNCE_DURATION)
    fn debounce_events(&mut self, events: Vec<DirectorEvent>, now: Instant) -> Vec<DirectorEvent> { todo!() }

    /// Check if an agent ID belongs to this factory session
    fn is_factory_agent(&self, agent_id: &str, data: &DirectorData) -> bool { todo!() }

    /// Check if an agent name belongs to this factory session
    fn is_factory_agent_name(&self, name: &str) -> bool { todo!() }

    /// Resolve agent ID to display name
    fn resolve_agent_name(&self, agent_id: &str, data: &DirectorData) -> String { todo!() }
}

#[cfg(test)]
#[path = "events_tests/tests.rs"]
mod tests;
