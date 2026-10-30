#[test]
fn test_debouncing() {
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

    // First assignment - should emit event
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

    let events1 = detector.detect_changes(&data2);
    assert_eq!(events1.len(), 1);
    assert!(matches!(
        &events1[0],
        DirectorEvent::TaskAssigned { task_id, .. } if task_id == "task-1"
    ));

    // Re-initialize and try again immediately - should be debounced
    detector.last_state = DirectorState::from_data(&data1);
    let events2 = detector.detect_changes(&data2);
    assert!(
        events2.is_empty(),
        "Expected debounced event, but got {events2:?}"
    );
}

#[test]
fn test_detect_epic_started() {
    let mut detector =
        DirectorEventDetector::new(vec!["swift-fox".to_string()], "supervisor".to_string());

    // Initial state: epic is open
    let data1 = DirectorData {
        ready_tasks: vec![],
        in_progress_tasks: vec![],
        epic_tasks: vec![make_epic("epic-1", "Test Epic", TaskStatus::Open)],
        agents: vec![],
        activity: vec![],
        agent_id_to_name: HashMap::new(),
        changes: vec![],
        git_loaded: true,
        reminders: vec![],
        epic_closed_counts: HashMap::new(),
    };
    detector.initialize(&data1);

    // New state: epic started (in progress)
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

    assert!(events.iter().any(|e| matches!(
        e,
        DirectorEvent::EpicStarted { epic_id, epic_title }
            if epic_id == "epic-1" && epic_title == "Test Epic"
    )));
}
