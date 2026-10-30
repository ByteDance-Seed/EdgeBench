#[test]
fn test_session_type_serde() {
    let factory = SessionType::Factory;
    let json = serde_json::to_string(&factory).unwrap();
    assert_eq!(json, "\"factory\"");

    let parsed: SessionType = serde_json::from_str("\"managed\"").unwrap();
    assert_eq!(parsed, SessionType::Managed);
}

#[test]
fn test_agent_state_serde() {
    let active = AgentState::Active;
    let json = serde_json::to_string(&active).unwrap();
    assert_eq!(json, "\"active\"");

    let parsed: AgentState = serde_json::from_str("\"blocked\"").unwrap();
    assert_eq!(parsed, AgentState::Blocked);
}

#[test]
fn test_session_summary_new() {
    let summary = SessionSummary::new(
        "test-123".to_string(),
        SessionType::Factory,
        PathBuf::from("/project"),
    );

    assert_eq!(summary.id, "test-123");
    assert_eq!(summary.session_type, SessionType::Factory);
    assert_eq!(summary.state, SessionState::Active);
    assert_eq!(summary.worker_count, 0);
    assert!(summary.supervisor_name.is_none());
    assert_eq!(summary.project_dir, PathBuf::from("/project"));
    assert!(!summary.recording_enabled);
    assert!(summary.epic_id.is_none());
    assert_eq!(summary.total_output_bytes, 0);
    assert!(summary.agent_states.is_empty());
}

#[test]
fn test_session_summary_managed() {
    let summary = SessionSummary::managed("managed-1".to_string(), PathBuf::from("/project"));

    assert!(!summary.is_factory());
    assert!(summary.is_managed());
    assert!(!summary.is_recording());
}

#[test]
fn test_session_summary_agent_states() {
    let mut summary = SessionSummary::factory(
        "test".to_string(),
        PathBuf::from("/project"),
        Some("supervisor".to_string()),
    );

    // Add agents
    summary.set_agent_state("worker-1", AgentState::Active);
    summary.set_agent_state("worker-2", AgentState::Idle);
    summary.set_agent_state("worker-3", AgentState::Blocked);

    assert_eq!(summary.worker_count, 3);
    assert_eq!(summary.active_agent_count(), 3);
    assert_eq!(
        summary.agent_states.get("worker-1"),
        Some(&AgentState::Active)
    );
    assert_eq!(
        summary.agent_states.get("worker-2"),
        Some(&AgentState::Idle)
    );

    // Exit an agent - should remove from map and update count
    summary.set_agent_state("worker-1", AgentState::Exited);
    assert_eq!(summary.worker_count, 2);
    assert_eq!(summary.active_agent_count(), 2);
    assert!(!summary.agent_states.contains_key("worker-1"));
}

#[test]
fn test_session_summary_touch() {
    let mut summary = SessionSummary::default();
    let initial = summary.last_activity;

    std::thread::sleep(std::time::Duration::from_millis(10));
    summary.touch();

    assert!(summary.last_activity > initial);
}

#[test]
fn test_session_cache_new() {
    let cache = SessionCache::new();
    assert!(cache.is_empty());
    assert_eq!(cache.len(), 0);
}

#[test]
fn test_session_cache_insert_and_get() {
    let cache = SessionCache::new();
    let summary = SessionSummary::factory(
        "session-1".to_string(),
        PathBuf::from("/project"),
        Some("supervisor".to_string()),
    );

    assert!(cache.insert(summary).is_none());
    assert_eq!(cache.len(), 1);
    assert!(!cache.is_empty());

    let retrieved = cache.get("session-1");
    assert!(retrieved.is_some());
    let retrieved = retrieved.unwrap();
    assert_eq!(retrieved.id, "session-1");
    assert_eq!(retrieved.supervisor_name, Some("supervisor".to_string()));
}

#[test]
fn test_session_cache_insert_replace() {
    let cache = SessionCache::new();

    let summary1 = SessionSummary::factory(
        "session-1".to_string(),
        PathBuf::from("/project1"),
        Some("supervisor-1".to_string()),
    );
    cache.insert(summary1);

    let summary2 = SessionSummary::factory(
        "session-1".to_string(),
        PathBuf::from("/project2"),
        Some("supervisor-2".to_string()),
    );
    let old = cache.insert(summary2);

    assert!(old.is_some());
    assert_eq!(old.unwrap().project_dir, PathBuf::from("/project1"));

    let current = cache.get("session-1").unwrap();
    assert_eq!(current.project_dir, PathBuf::from("/project2"));
    assert_eq!(current.supervisor_name, Some("supervisor-2".to_string()));
}

#[test]
fn test_session_cache_contains() {
    let cache = SessionCache::new();
    assert!(!cache.contains("session-1"));

    cache.insert(SessionSummary::factory(
        "session-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));
    assert!(cache.contains("session-1"));
    assert!(!cache.contains("session-2"));
}

#[test]
fn test_session_cache_clear() {
    let cache = SessionCache::new();

    cache.insert(SessionSummary::factory(
        "session-1".to_string(),
        PathBuf::from("/project1"),
        None,
    ));
    cache.insert(SessionSummary::factory(
        "session-2".to_string(),
        PathBuf::from("/project2"),
        None,
    ));

    assert_eq!(cache.len(), 2);
    cache.clear();
    assert!(cache.is_empty());
    assert_eq!(cache.len(), 0);
}
