//! Integration tests for DirectorData loading from CAS stores.
//!
//! These tests verify:
//! - DirectorData loads correctly from SQLite stores
//! - Task filtering by status works correctly
//! - Agent summary generation works
//! - Epic grouping logic is correct
//! - Fast loading mode skips git changes

use cas_factory::{AgentSummary, DirectorData, EpicGroup, TaskSummary};
use cas_store::{
    AgentStore, EventStore, SqliteAgentStore, SqliteEventStore, SqliteTaskStore, TaskStore,
};
use cas_types::{
    Agent, AgentRole, AgentStatus, AgentType, Dependency, DependencyType, Priority, Task,
    TaskStatus, TaskType,
};
use tempfile::TempDir;

/// Helper to create a test CAS directory with initialized stores
fn setup_test_cas_dir() -> TempDir { todo!() }

/// Initialize task store with test schema
fn init_task_store(cas_dir: &std::path::Path) -> SqliteTaskStore { todo!() }

/// Initialize agent store with test schema
fn init_agent_store(cas_dir: &std::path::Path) -> SqliteAgentStore { todo!() }

/// Initialize event store with test schema
fn init_event_store(cas_dir: &std::path::Path) -> SqliteEventStore { todo!() }

/// Create a test task with given parameters
fn create_test_task(
    id: &str,
    title: &str,
    status: TaskStatus,
    task_type: TaskType,
    priority: Priority,
    assignee: Option<&str>,
) -> Task { todo!() }

/// Create a test agent with given parameters
fn create_test_agent(id: &str, name: &str, role: AgentRole, status: AgentStatus) -> Agent { todo!() }

// =============================================================================
// DirectorData Loading Tests
// =============================================================================


#[test]
fn test_director_data_load_fast() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    // Initialize stores
    init_task_store(cas_dir);
    init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Fast load should skip git changes
    let result = DirectorData::load_fast(cas_dir);
    assert!(result.is_ok());

    let data = result.unwrap();
    assert!(!data.git_loaded, "Fast load should not load git changes");
    assert!(data.changes.is_empty());
}



#[test]
fn test_director_data_excludes_epics_from_regular_tasks() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    let task_store = init_task_store(cas_dir);
    init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Add an epic task
    let epic = create_test_task(
        "cas-epic",
        "Epic Task",
        TaskStatus::InProgress,
        TaskType::Epic,
        Priority::CRITICAL,
        None,
    );

    // Add a regular task
    let task = create_test_task(
        "cas-0001",
        "Regular Task",
        TaskStatus::InProgress,
        TaskType::Task,
        Priority::HIGH,
        None,
    );

    task_store.add(&epic).expect("Failed to add epic");
    task_store.add(&task).expect("Failed to add task");

    // Load DirectorData
    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");

    // Epic should be in epic_tasks, not in in_progress_tasks
    assert_eq!(data.in_progress_tasks.len(), 1);
    assert_eq!(data.in_progress_tasks[0].id, "cas-0001");

    assert_eq!(data.epic_tasks.len(), 1);
    assert_eq!(data.epic_tasks[0].id, "cas-epic");
}

#[test]
fn test_director_data_loads_agents() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    init_task_store(cas_dir);
    let agent_store = init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Add supervisor and worker agents
    let supervisor = create_test_agent(
        "supervisor-1",
        "quiet-condor",
        AgentRole::Supervisor,
        AgentStatus::Active,
    );
    let worker = create_test_agent(
        "worker-1",
        "swift-fox",
        AgentRole::Worker,
        AgentStatus::Idle,
    );

    agent_store
        .register(&supervisor)
        .expect("Failed to add supervisor");
    agent_store.register(&worker).expect("Failed to add worker");

    // Load DirectorData
    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");

    assert_eq!(data.agents.len(), 2, "Should have 2 agents");
    assert!(data.agents.iter().any(|a| a.name == "quiet-condor"));
    assert!(data.agents.iter().any(|a| a.name == "swift-fox"));
}

#[test]
fn test_director_data_filters_inactive_agents() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    init_task_store(cas_dir);
    let agent_store = init_agent_store(cas_dir);
    init_event_store(cas_dir);

    // Add an inactive agent (should be filtered out)
    let now = chrono::Utc::now();
    let inactive_agent = Agent {
        id: "agent-1".to_string(),
        name: "inactive-agent".to_string(),
        agent_type: AgentType::Primary,
        role: AgentRole::Worker,
        status: AgentStatus::Shutdown, // Inactive
        pid: None,
        ppid: None,
        cc_session_id: None,
        parent_id: None,
        machine_id: None,
        registered_at: now,
        last_heartbeat: now,
        active_tasks: 0,
        metadata: std::collections::HashMap::new(),
    };

    agent_store
        .register(&inactive_agent)
        .expect("Failed to add agent");

    // Load DirectorData
    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");

    // Inactive agents should be filtered out
    assert!(
        data.agents.is_empty(),
        "Inactive agents should be filtered out"
    );
}

#[test]
fn test_director_data_builds_agent_id_to_name_map() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    init_task_store(cas_dir);
    let agent_store = init_agent_store(cas_dir);
    init_event_store(cas_dir);

    let agent = create_test_agent(
        "agent-123",
        "cool-panda",
        AgentRole::Worker,
        AgentStatus::Active,
    );

    agent_store.register(&agent).expect("Failed to add agent");

    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");

    // Check agent_id_to_name map
    assert!(data.agent_id_to_name.contains_key("agent-123"));
    assert_eq!(
        data.agent_id_to_name.get("agent-123"),
        Some(&"cool-panda".to_string())
    );
}

// =============================================================================
// Epic Grouping Tests
// =============================================================================

#[test]
fn test_tasks_by_epic_empty() {
    let temp_dir = setup_test_cas_dir();
    let cas_dir = temp_dir.path();

    init_task_store(cas_dir);
    init_agent_store(cas_dir);
    init_event_store(cas_dir);

    let data = DirectorData::load_fast(cas_dir).expect("Failed to load DirectorData");

    let (groups, standalone) = data.tasks_by_epic();

    assert!(groups.is_empty());
    assert!(standalone.is_empty());
}



// =============================================================================
// TaskSummary Tests
// =============================================================================

#[test]
fn test_task_summary_fields() {
    let summary = TaskSummary {
        id: "cas-1234".to_string(),
        title: "Test Task".to_string(),
        status: TaskStatus::InProgress,
        priority: Priority::HIGH,
        assignee: Some("agent-1".to_string()),
        task_type: TaskType::Feature,
        epic: Some("cas-epic".to_string()),
        branch: Some("feature/test".to_string()),
    };

    assert_eq!(summary.id, "cas-1234");
    assert_eq!(summary.title, "Test Task");
    assert_eq!(summary.status, TaskStatus::InProgress);
    assert_eq!(summary.priority, Priority::HIGH);
    assert_eq!(summary.assignee, Some("agent-1".to_string()));
    assert_eq!(summary.task_type, TaskType::Feature);
    assert_eq!(summary.epic, Some("cas-epic".to_string()));
    assert_eq!(summary.branch, Some("feature/test".to_string()));
}

// =============================================================================
// AgentSummary Tests
// =============================================================================

#[test]
fn test_agent_summary_fields() {
    let now = chrono::Utc::now();
    let summary = AgentSummary {
        id: "agent-123".to_string(),
        name: "swift-fox".to_string(),
        status: AgentStatus::Active,
        current_task: Some("cas-1234".to_string()),
        latest_activity: Some(("Edited file".to_string(), now)),
        last_heartbeat: Some(now),
    };

    assert_eq!(summary.id, "agent-123");
    assert_eq!(summary.name, "swift-fox");
    assert_eq!(summary.status, AgentStatus::Active);
    assert_eq!(summary.current_task, Some("cas-1234".to_string()));
    assert!(summary.latest_activity.is_some());
    assert!(summary.last_heartbeat.is_some());
}

// =============================================================================
// EpicGroup Tests
// =============================================================================

#[test]
fn test_epic_group_fields() {
    let epic = TaskSummary {
        id: "cas-epic".to_string(),
        title: "Test Epic".to_string(),
        status: TaskStatus::InProgress,
        priority: Priority::CRITICAL,
        assignee: None,
        task_type: TaskType::Epic,
        epic: None,
        branch: Some("epic/test".to_string()),
    };

    let subtask = TaskSummary {
        id: "cas-0001".to_string(),
        title: "Subtask 1".to_string(),
        status: TaskStatus::InProgress,
        priority: Priority::HIGH,
        assignee: Some("agent-1".to_string()),
        task_type: TaskType::Task,
        epic: Some("cas-epic".to_string()),
        branch: None,
    };

    let group = EpicGroup {
        epic,
        subtasks: vec![subtask],
        has_active: true,
    };

    assert_eq!(group.epic.id, "cas-epic");
    assert_eq!(group.subtasks.len(), 1);
    assert!(group.has_active);
}
