use crate::RecordingStore;
use crate::recording_store::{
    SqliteRecordingStore, get_active_recording_with_conn, record_agent_event_with_conn,
    record_message_event_with_conn, record_task_event_with_conn,
};
use cas_types::{Recording, RecordingAgent, RecordingEvent, RecordingEventType, RecordingQuery};
use chrono::Utc;
use rusqlite::{Connection, params};
use tempfile::TempDir;

fn create_test_store() -> (TempDir, SqliteRecordingStore) { todo!() }

#[test]
fn test_recording_crud() {
    let (_temp, store) = create_test_store();

    // Create
    let mut recording = Recording::new("/path/to/rec.bin".to_string());
    recording.session_id = Some("session-1".to_string());
    recording.title = Some("Test Recording".to_string());

    store.add(&recording).unwrap();

    // Read
    let fetched = store.get(&recording.id).unwrap();
    assert_eq!(fetched.session_id, Some("session-1".to_string()));
    assert_eq!(fetched.title, Some("Test Recording".to_string()));
    assert_eq!(fetched.file_path, "/path/to/rec.bin");

    // Update
    let mut updated = fetched;
    updated.end();
    updated.file_size = Some(1024);
    store.update(&updated).unwrap();

    let refetched = store.get(&recording.id).unwrap();
    assert!(refetched.ended_at.is_some());
    assert!(refetched.duration_ms.is_some());
    assert_eq!(refetched.file_size, Some(1024));

    // Delete
    store.delete(&recording.id).unwrap();
    assert!(store.get(&recording.id).is_err());
}





#[test]
fn test_list_by_agent() {
    let (_temp, store) = create_test_store();

    let rec1 = Recording::new("/path/1.bin".to_string());
    let rec2 = Recording::new("/path/2.bin".to_string());

    store.add(&rec1).unwrap();
    store.add(&rec2).unwrap();

    // Add agents
    store
        .add_agent(&RecordingAgent::new(
            rec1.id.clone(),
            "swift-fox".to_string(),
            "worker".to_string(),
            "/agent1.bin".to_string(),
        ))
        .unwrap();
    store
        .add_agent(&RecordingAgent::new(
            rec2.id.clone(),
            "proud-finch".to_string(),
            "supervisor".to_string(),
            "/agent2.bin".to_string(),
        ))
        .unwrap();

    let results = store.list_by_agent("swift-fox").unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].id, rec1.id);
}

#[test]
fn test_fts_search() {
    let (_temp, store) = create_test_store();

    let recording = Recording::new("/path/to/rec.bin".to_string());
    store.add(&recording).unwrap();

    // Add FTS content
    store
        .add_fts_content(&recording.id, "hello world test", "output", 1000)
        .unwrap();
    store
        .add_fts_content(&recording.id, "goodbye world", "output", 2000)
        .unwrap();

    // Search
    let results = store.search_fts("hello", 10).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].0, recording.id);
    assert_eq!(results[0].1, 1000);

    let results = store.search_fts("world", 10).unwrap();
    assert_eq!(results.len(), 2);
}


#[test]
fn test_record_recording_event() {
    let (temp, _store) = create_test_store();
    let conn = Connection::open(temp.path().join("cas.db")).unwrap();

    // Create an active recording
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

    // Record an event
    let result = record_task_event_with_conn(
        &conn,
        "session-1",
        RecordingEventType::TaskCreated,
        "cas-1234",
        None,
    )
    .unwrap();
    assert!(result.is_some());

    // Verify event was recorded
    let count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM recording_events WHERE recording_id = ?",
            params![recording.id],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(count, 1);

    // Record another event type
    let result = record_agent_event_with_conn(
        &conn,
        "session-1",
        RecordingEventType::AgentJoined,
        "agent-1",
        Some(r#"{"name": "swift-fox"}"#),
    )
    .unwrap();
    assert!(result.is_some());

    // Verify total events
    let count: i64 = conn
        .query_row(
            "SELECT COUNT(*) FROM recording_events WHERE recording_id = ?",
            params![recording.id],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(count, 2);
}

#[test]
fn test_record_event_no_active_recording() {
    let (temp, _store) = create_test_store();
    let conn = Connection::open(temp.path().join("cas.db")).unwrap();

    // Try to record event without an active recording
    let result = record_task_event_with_conn(
        &conn,
        "session-1",
        RecordingEventType::TaskCreated,
        "cas-1234",
        None,
    )
    .unwrap();

    // Should return None (no active recording)
    assert!(result.is_none());
}

#[test]
fn test_record_message_event() {
    let (temp, _store) = create_test_store();
    let conn = Connection::open(temp.path().join("cas.db")).unwrap();

    // Create an active recording
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

    // Record a message event
    let result =
        record_message_event_with_conn(&conn, "session-1", "swift-fox", "proud-finch").unwrap();
    assert!(result.is_some());

    // Verify event and metadata
    let (event_type, metadata): (String, Option<String>) = conn
        .query_row(
            "SELECT event_type, metadata FROM recording_events WHERE id = ?",
            params![result.unwrap()],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .unwrap();

    assert_eq!(event_type, "message_sent");
    assert!(metadata.is_some());
    let meta: serde_json::Value = serde_json::from_str(&metadata.unwrap()).unwrap();
    assert_eq!(meta["from"], "swift-fox");
    assert_eq!(meta["to"], "proud-finch");
}
