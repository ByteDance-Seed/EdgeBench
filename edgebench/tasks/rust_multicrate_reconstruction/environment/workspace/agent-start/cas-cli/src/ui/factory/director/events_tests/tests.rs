use crate::ui::factory::director::data::AgentSummary;
use crate::ui::factory::director::events::*;
use cas_types::{AgentStatus, TaskType};

fn make_task(id: &str, title: &str, status: TaskStatus, assignee: Option<&str>) -> TaskSummary { todo!() }

fn make_epic(id: &str, title: &str, status: TaskStatus) -> TaskSummary { todo!() }

fn make_agent(id: &str, name: &str, current_task: Option<&str>) -> AgentSummary { todo!() }

#[test]
fn test_detect_task_assigned() {
    let mut detector =
        DirectorEventDetector::new(vec!["swift-fox".to_string()], "supervisor".to_string());

    // Initial state: task unassigned
    let data1 = DirectorData {
        ready_tasks: vec![make_task("task-1", "Test Task", TaskStatus::Open, None)],
        in_progress_tasks: vec![],
        epic_tasks: vec![],
        agents: vec![make_agent("agent-1", "swift-fox", None)],
        activity: vec![],
        agent_id_to_name: [("agent-1".to_string(), "swift-fox".to_string())]
            .into_iter()
            .collect(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };
    detector.initialize(&data1);

    // New state: task assigned to swift-fox
    let data2 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![make_task(
            "task-1",
            "Test Task",
            TaskStatus::InProgress,
            Some("agent-1"),
        )],
        epic_tasks: vec![],
        agents: vec![make_agent("agent-1", "swift-fox", Some("task-1"))],
        activity: vec![],
        agent_id_to_name: [("agent-1".to_string(), "swift-fox".to_string())]
            .into_iter()
            .collect(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };

    let events = detector.detect_changes(&data2);

    assert!(events.iter().any(|e| matches!(
        e,
        DirectorEvent::TaskAssigned { task_id, worker, .. }
            if task_id == "task-1" && worker == "swift-fox"
    )));
}

#[test]
fn test_detect_task_completed() {
    let mut detector =
        DirectorEventDetector::new(vec!["swift-fox".to_string()], "supervisor".to_string());

    // Initial state: task in progress
    let data1 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![make_task(
            "task-1",
            "Test Task",
            TaskStatus::InProgress,
            Some("agent-1"),
        )],
        epic_tasks: vec![],
        agents: vec![make_agent("agent-1", "swift-fox", Some("task-1"))],
        activity: vec![],
        agent_id_to_name: [("agent-1".to_string(), "swift-fox".to_string())]
            .into_iter()
            .collect(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };
    detector.initialize(&data1);

    // New state: task completed (no longer in in_progress_tasks)
    let data2 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![],
        epic_tasks: vec![],
        agents: vec![make_agent("agent-1", "swift-fox", None)],
        activity: vec![],
        agent_id_to_name: [("agent-1".to_string(), "swift-fox".to_string())]
            .into_iter()
            .collect(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };

    let events = detector.detect_changes(&data2);

    assert!(events.iter().any(|e| matches!(
        e,
        DirectorEvent::TaskCompleted { task_id, worker, .. }
            if task_id == "task-1" && worker == "swift-fox"
    )));
}

#[test]
fn test_detect_worker_idle() {
    let mut detector =
        DirectorEventDetector::new(vec!["swift-fox".to_string()], "supervisor".to_string());

    // Initial state: worker has task
    let data1 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![make_task(
            "task-1",
            "Test Task",
            TaskStatus::InProgress,
            Some("agent-1"),
        )],
        epic_tasks: vec![],
        agents: vec![make_agent("agent-1", "swift-fox", Some("task-1"))],
        activity: vec![],
        agent_id_to_name: [("agent-1".to_string(), "swift-fox".to_string())]
            .into_iter()
            .collect(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };
    detector.initialize(&data1);

    // New state: worker idle
    let data2 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![],
        epic_tasks: vec![],
        agents: vec![make_agent("agent-1", "swift-fox", None)],
        activity: vec![],
        agent_id_to_name: [("agent-1".to_string(), "swift-fox".to_string())]
            .into_iter()
            .collect(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };

    let events = detector.detect_changes(&data2);

    assert!(events.iter().any(|e| matches!(
        e,
        DirectorEvent::WorkerIdle { worker } if worker == "swift-fox"
    )));
}

#[test]
fn test_ignore_non_factory_agents() {
    let mut detector =
        DirectorEventDetector::new(vec!["swift-fox".to_string()], "supervisor".to_string());

    // Initial state
    let data1 = DirectorData {
        ready_tasks: vec![make_task("task-1", "Test Task", TaskStatus::Open, None)],
        in_progress_tasks: vec![],
        epic_tasks: vec![],
        agents: vec![],
        activity: vec![],
        agent_id_to_name: HashMap::new(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };
    detector.initialize(&data1);

    // New state: task assigned to agent not in factory
    let data2 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![make_task(
            "task-1",
            "Test Task",
            TaskStatus::InProgress,
            Some("other-agent"),
        )],
        epic_tasks: vec![],
        agents: vec![make_agent("other-agent", "other-agent", Some("task-1"))],
        activity: vec![],
        agent_id_to_name: HashMap::new(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };

    let events = detector.detect_changes(&data2);

    // Should not detect assignment since "other-agent" is not in factory
    assert!(
        !events
            .iter()
            .any(|e| matches!(e, DirectorEvent::TaskAssigned { .. }))
    );
}


#[test]
fn test_debounce_key_uniqueness() {
    // Different event types should have different keys
    let assigned = DirectorEvent::TaskAssigned {
        task_id: "task-1".to_string(),
        task_title: "Title".to_string(),
        worker: "worker-1".to_string(),
    };
    let completed = DirectorEvent::TaskCompleted {
        task_id: "task-1".to_string(),
        task_title: "Title".to_string(),
        worker: "worker-1".to_string(),
    };

    assert_ne!(assigned.debounce_key(), completed.debounce_key());

    // Same event type with different tasks should have different keys
    let assigned2 = DirectorEvent::TaskAssigned {
        task_id: "task-2".to_string(),
        task_title: "Title".to_string(),
        worker: "worker-1".to_string(),
    };

    assert_ne!(assigned.debounce_key(), assigned2.debounce_key());

    // Same event type with same task but different worker should have different keys
    let assigned3 = DirectorEvent::TaskAssigned {
        task_id: "task-1".to_string(),
        task_title: "Title".to_string(),
        worker: "worker-2".to_string(),
    };

    assert_ne!(assigned.debounce_key(), assigned3.debounce_key());
}


#[test]
fn test_detect_epic_completed() {
    let mut detector =
        DirectorEventDetector::new(vec!["swift-fox".to_string()], "supervisor".to_string());

    // Initial state: epic is in progress
    let data1 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![],
        epic_tasks: vec![make_epic("epic-1", "Test Epic", TaskStatus::InProgress)],
        agents: vec![],
        activity: vec![],
        agent_id_to_name: HashMap::new(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };
    detector.initialize(&data1);

    // New state: epic completed
    let data2 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![],
        epic_tasks: vec![make_epic("epic-1", "Test Epic", TaskStatus::Closed)],
        agents: vec![],
        activity: vec![],
        agent_id_to_name: HashMap::new(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };

    let events = detector.detect_changes(&data2);

    assert!(events.iter().any(|e| matches!(
        e,
        DirectorEvent::EpicCompleted { epic_id } if epic_id == "epic-1"
    )));
}

#[test]
fn test_no_epic_event_when_unchanged() {
    let mut detector =
        DirectorEventDetector::new(vec!["swift-fox".to_string()], "supervisor".to_string());

    // Initial state: epic is in progress
    let data1 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![],
        epic_tasks: vec![make_epic("epic-1", "Test Epic", TaskStatus::InProgress)],
        agents: vec![],
        activity: vec![],
        agent_id_to_name: HashMap::new(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };
    detector.initialize(&data1);

    // Same state: epic still in progress
    let data2 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![],
        epic_tasks: vec![make_epic("epic-1", "Test Epic", TaskStatus::InProgress)],
        agents: vec![],
        activity: vec![],
        agent_id_to_name: HashMap::new(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };

    let events = detector.detect_changes(&data2);

    // No epic events should be emitted
    assert!(!events.iter().any(|e| matches!(
        e,
        DirectorEvent::EpicStarted { .. } | DirectorEvent::EpicCompleted { .. }
    )));
}
