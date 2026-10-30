#[test]
fn test_recording_agents() {
    let (_temp, store) = create_test_store();

    let recording = Recording::new("/path/to/rec.bin".to_string());
    store.add(&recording).unwrap();

    // Add agents
    let agent1 = RecordingAgent::new(
        recording.id.clone(),
        "swift-fox".to_string(),
        "worker".to_string(),
        "/path/to/swift-fox.bin".to_string(),
    );
    let agent2 = RecordingAgent::new(
        recording.id.clone(),
        "proud-finch".to_string(),
        "supervisor".to_string(),
        "/path/to/proud-finch.bin".to_string(),
    );

    store.add_agent(&agent1).unwrap();
    store.add_agent(&agent2).unwrap();

    // Get agents
    let agents = store.get_agents(&recording.id).unwrap();
    assert_eq!(agents.len(), 2);

    // Delete agents
    store.delete_agents(&recording.id).unwrap();
    let agents = store.get_agents(&recording.id).unwrap();
    assert_eq!(agents.len(), 0);
}

#[test]
fn test_recording_events() {
    let (_temp, store) = create_test_store();

    let recording = Recording::new("/path/to/rec.bin".to_string());
    store.add(&recording).unwrap();

    // Add events
    let event1 = RecordingEvent::for_entity(
        recording.id.clone(),
        1000,
        RecordingEventType::TaskCreated,
        "task".to_string(),
        "cas-1234".to_string(),
    );
    let event2 = RecordingEvent::for_entity(
        recording.id.clone(),
        2000,
        RecordingEventType::TaskCompleted,
        "task".to_string(),
        "cas-1234".to_string(),
    );

    store.add_event(&event1).unwrap();
    store.add_event(&event2).unwrap();

    // Get events
    let events = store.get_events(&recording.id).unwrap();
    assert_eq!(events.len(), 2);
    assert_eq!(events[0].timestamp_ms, 1000);
    assert_eq!(events[1].timestamp_ms, 2000);

    // Get events in range
    let events = store.get_events_in_range(&recording.id, 500, 1500).unwrap();
    assert_eq!(events.len(), 1);
    assert_eq!(events[0].timestamp_ms, 1000);

    // Get events for entity
    let events = store
        .get_events_for_entity(&recording.id, "task", "cas-1234")
        .unwrap();
    assert_eq!(events.len(), 2);
}

#[test]
fn test_query_recordings() {
    let (_temp, store) = create_test_store();

    // Create recordings
    let rec1 = Recording::for_session("session-1".to_string(), "/path/1.bin".to_string());
    let rec2 = Recording::for_session("session-2".to_string(), "/path/2.bin".to_string());
    let rec3 = Recording::for_session("session-1".to_string(), "/path/3.bin".to_string());

    store.add(&rec1).unwrap();
    store.add(&rec2).unwrap();
    store.add(&rec3).unwrap();

    // Add agent to rec1
    let agent = RecordingAgent::new(
        rec1.id.clone(),
        "swift-fox".to_string(),
        "worker".to_string(),
        "/path/agent.bin".to_string(),
    );
    store.add_agent(&agent).unwrap();

    // Query by session
    let query = RecordingQuery::new().for_session("session-1".to_string());
    let results = store.query(&query).unwrap();
    assert_eq!(results.len(), 2);

    // Query by agent
    let query = RecordingQuery::new().by_agent("swift-fox".to_string());
    let results = store.query(&query).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].id, rec1.id);

    // Query with limit
    let query = RecordingQuery::new().with_limit(2);
    let results = store.query(&query).unwrap();
    assert_eq!(results.len(), 2);
}

#[test]
fn test_list_by_session() {
    let (_temp, store) = create_test_store();

    let rec1 = Recording::for_session("session-1".to_string(), "/path/1.bin".to_string());
    let rec2 = Recording::for_session("session-2".to_string(), "/path/2.bin".to_string());
    let rec3 = Recording::for_session("session-1".to_string(), "/path/3.bin".to_string());

    store.add(&rec1).unwrap();
    store.add(&rec2).unwrap();
    store.add(&rec3).unwrap();

    let results = store.list_by_session("session-1").unwrap();
    assert_eq!(results.len(), 2);
}

#[test]
fn test_get_active_recording() {
    let (temp, _store) = create_test_store();
    let conn = Connection::open(temp.path().join("cas.db")).unwrap();

    // Create a recording with session_id
    let recording = Recording::for_session("session-1".to_string(), "/path/rec.bin".to_string());
    conn.execute(
        "INSERT INTO recordings (id, session_id, started_at, file_path, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5)",
        params![
            recording.id,
            recording.session_id,
            recording.started_at.to_rfc3339(),
            recording.file_path,
            recording.created_at.to_rfc3339(),
        ],
    )
    .unwrap();

    // Should find active recording (ended_at is NULL)
    let active = get_active_recording_with_conn(&conn, "session-1").unwrap();
    assert!(active.is_some());
    let (id, _) = active.unwrap();
    assert_eq!(id, recording.id);

    // Should not find active recording for different session
    let active = get_active_recording_with_conn(&conn, "session-2").unwrap();
    assert!(active.is_none());

    // End the recording
    conn.execute(
        "UPDATE recordings SET ended_at = ? WHERE id = ?",
        params![Utc::now().to_rfc3339(), recording.id],
    )
    .unwrap();

    // Should not find active recording after ending
    let active = get_active_recording_with_conn(&conn, "session-1").unwrap();
    assert!(active.is_none());
}
