use std::path::PathBuf;

use crate::session::state::*;

#[test]
fn test_session_id_format() {
    let id = generate_session_id();
    assert!(id.starts_with("fs-"));
    assert!(id.len() > 10);
}

// === SessionType tests ===

#[test]
fn test_session_type_display() {
    assert_eq!(SessionType::Factory.to_string(), "factory");
    assert_eq!(SessionType::Managed.to_string(), "managed");
    assert_eq!(SessionType::Recording.to_string(), "recording");
}

#[test]
fn test_session_type_default() {
    assert_eq!(SessionType::default(), SessionType::Factory);
}


// === AgentState tests ===

#[test]
fn test_agent_state_display() {
    assert_eq!(AgentState::Active.to_string(), "active");
    assert_eq!(AgentState::Idle.to_string(), "idle");
    assert_eq!(AgentState::Blocked.to_string(), "blocked");
    assert_eq!(AgentState::Exited.to_string(), "exited");
}

#[test]
fn test_agent_state_default() {
    assert_eq!(AgentState::default(), AgentState::Active);
}


// === SessionSummary tests ===


#[test]
fn test_session_summary_factory() {
    let summary = SessionSummary::factory(
        "factory-1".to_string(),
        PathBuf::from("/project"),
        Some("supervisor-1".to_string()),
    );

    assert!(summary.is_factory());
    assert!(!summary.is_managed());
    assert!(!summary.is_recording());
    assert_eq!(summary.supervisor_name, Some("supervisor-1".to_string()));
}


#[test]
fn test_session_summary_recording() {
    let summary = SessionSummary::recording("recording-1".to_string(), PathBuf::from("/project"));

    assert!(!summary.is_factory());
    assert!(!summary.is_managed());
    assert!(summary.is_recording());
    assert!(summary.recording_enabled);
}


#[test]
fn test_session_summary_output_bytes() {
    let mut summary = SessionSummary::default();

    summary.add_output_bytes(100);
    assert_eq!(summary.total_output_bytes, 100);

    summary.add_output_bytes(250);
    assert_eq!(summary.total_output_bytes, 350);

    // Test saturation (shouldn't overflow)
    summary.total_output_bytes = u64::MAX - 10;
    summary.add_output_bytes(100);
    assert_eq!(summary.total_output_bytes, u64::MAX);
}

#[test]
fn test_session_summary_set_epic() {
    let mut summary = SessionSummary::default();
    assert!(summary.epic_id.is_none());

    summary.set_epic("epic-123");
    assert_eq!(summary.epic_id, Some("epic-123".to_string()));
}


#[test]
fn test_session_summary_serde() {
    let mut summary = SessionSummary::factory(
        "test-serde".to_string(),
        PathBuf::from("/project"),
        Some("supervisor".to_string()),
    );
    summary.set_epic("epic-1");
    summary.set_agent_state("worker-1", AgentState::Active);
    summary.add_output_bytes(1024);

    let json = serde_json::to_string(&summary).unwrap();
    let parsed: SessionSummary = serde_json::from_str(&json).unwrap();

    assert_eq!(parsed.id, "test-serde");
    assert_eq!(parsed.session_type, SessionType::Factory);
    assert_eq!(parsed.supervisor_name, Some("supervisor".to_string()));
    assert_eq!(parsed.epic_id, Some("epic-1".to_string()));
    assert_eq!(parsed.worker_count, 1);
    assert_eq!(parsed.total_output_bytes, 1024);
    assert_eq!(
        parsed.agent_states.get("worker-1"),
        Some(&AgentState::Active)
    );
}

// === SessionCache tests ===




#[test]
fn test_session_cache_update() {
    let cache = SessionCache::new();
    let summary = SessionSummary::factory(
        "session-1".to_string(),
        PathBuf::from("/project"),
        Some("supervisor".to_string()),
    );
    cache.insert(summary);

    let updated = cache.update("session-1", |s| {
        s.set_epic("epic-123");
        s.add_output_bytes(1000);
    });
    assert!(updated);

    let retrieved = cache.get("session-1").unwrap();
    assert_eq!(retrieved.epic_id, Some("epic-123".to_string()));
    assert_eq!(retrieved.total_output_bytes, 1000);

    // Update non-existent session returns false
    let not_updated = cache.update("nonexistent", |_| {});
    assert!(!not_updated);
}

#[test]
fn test_session_cache_remove() {
    let cache = SessionCache::new();
    let summary = SessionSummary::factory("session-1".to_string(), PathBuf::from("/project"), None);
    cache.insert(summary);
    assert_eq!(cache.len(), 1);

    let removed = cache.remove("session-1");
    assert!(removed.is_some());
    assert_eq!(removed.unwrap().id, "session-1");
    assert!(cache.is_empty());

    // Remove non-existent returns None
    assert!(cache.remove("nonexistent").is_none());
}


#[test]
fn test_session_cache_list() {
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

    let sessions = cache.list();
    assert_eq!(sessions.len(), 2);

    let ids: Vec<_> = sessions.iter().map(|s| s.id.as_str()).collect();
    assert!(ids.contains(&"session-1"));
    assert!(ids.contains(&"session-2"));
}

#[test]
fn test_session_cache_ids() {
    let cache = SessionCache::new();

    cache.insert(SessionSummary::factory(
        "session-1".to_string(),
        PathBuf::from("/project1"),
        None,
    ));
    cache.insert(SessionSummary::managed(
        "session-2".to_string(),
        PathBuf::from("/project2"),
    ));

    let ids = cache.ids();
    assert_eq!(ids.len(), 2);
    assert!(ids.contains(&"session-1".to_string()));
    assert!(ids.contains(&"session-2".to_string()));
}

#[test]
fn test_session_cache_filter_by_type() {
    let cache = SessionCache::new();

    cache.insert(SessionSummary::factory(
        "factory-1".to_string(),
        PathBuf::from("/project1"),
        None,
    ));
    cache.insert(SessionSummary::factory(
        "factory-2".to_string(),
        PathBuf::from("/project2"),
        None,
    ));
    cache.insert(SessionSummary::managed(
        "managed-1".to_string(),
        PathBuf::from("/project3"),
    ));
    cache.insert(SessionSummary::recording(
        "recording-1".to_string(),
        PathBuf::from("/project4"),
    ));

    let factory = cache.filter_by_type(SessionType::Factory);
    assert_eq!(factory.len(), 2);

    let managed = cache.filter_by_type(SessionType::Managed);
    assert_eq!(managed.len(), 1);
    assert_eq!(managed[0].id, "managed-1");

    let recording = cache.filter_by_type(SessionType::Recording);
    assert_eq!(recording.len(), 1);
    assert_eq!(recording[0].id, "recording-1");
}

#[test]
fn test_session_cache_convenience_filters() {
    let cache = SessionCache::new();

    cache.insert(SessionSummary::factory(
        "factory-1".to_string(),
        PathBuf::from("/project1"),
        None,
    ));
    cache.insert(SessionSummary::managed(
        "managed-1".to_string(),
        PathBuf::from("/project2"),
    ));
    cache.insert(SessionSummary::recording(
        "recording-1".to_string(),
        PathBuf::from("/project3"),
    ));

    assert_eq!(cache.factory_sessions().len(), 1);
    assert_eq!(cache.managed_sessions().len(), 1);
    assert_eq!(cache.recording_sessions().len(), 1);
}

#[test]
fn test_session_cache_filter_by_state() {
    let cache = SessionCache::new();

    let mut active =
        SessionSummary::factory("active-1".to_string(), PathBuf::from("/project1"), None);
    active.state = SessionState::Active;
    cache.insert(active);

    let mut paused =
        SessionSummary::factory("paused-1".to_string(), PathBuf::from("/project2"), None);
    paused.state = SessionState::Paused;
    cache.insert(paused);

    let active_sessions = cache.filter_by_state(SessionState::Active);
    assert_eq!(active_sessions.len(), 1);
    assert_eq!(active_sessions[0].id, "active-1");

    let paused_sessions = cache.filter_by_state(SessionState::Paused);
    assert_eq!(paused_sessions.len(), 1);
    assert_eq!(paused_sessions[0].id, "paused-1");

    // All active (convenience method)
    assert_eq!(cache.active_sessions().len(), 1);
}


#[test]
fn test_session_cache_get_or_insert_with() {
    let cache = SessionCache::new();

    // First call should insert
    let session1 = cache.get_or_insert_with("session-1", || {
        SessionSummary::factory(
            "session-1".to_string(),
            PathBuf::from("/project1"),
            Some("supervisor-1".to_string()),
        )
    });
    assert_eq!(session1.supervisor_name, Some("supervisor-1".to_string()));
    assert_eq!(cache.len(), 1);

    // Second call should return existing (not call closure)
    let session2 = cache.get_or_insert_with("session-1", || {
        // This closure should not be called
        SessionSummary::factory(
            "session-1".to_string(),
            PathBuf::from("/different"),
            Some("different-supervisor".to_string()),
        )
    });
    assert_eq!(session2.supervisor_name, Some("supervisor-1".to_string()));
    assert_eq!(session2.project_dir, PathBuf::from("/project1"));
    assert_eq!(cache.len(), 1);
}

#[test]
fn test_session_cache_clone() {
    let cache1 = SessionCache::new();
    cache1.insert(SessionSummary::factory(
        "session-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));

    // Clone shares the same underlying data
    let cache2 = cache1.clone();
    assert_eq!(cache2.len(), 1);

    // Modifications through one handle are visible in the other
    cache1.insert(SessionSummary::factory(
        "session-2".to_string(),
        PathBuf::from("/project2"),
        None,
    ));
    assert_eq!(cache2.len(), 2);
}

#[test]
fn test_session_cache_thread_safety() {
    use std::sync::Arc;
    use std::thread;

    let cache = Arc::new(SessionCache::new());
    let mut handles = vec![];

    // Spawn multiple threads that insert sessions
    for i in 0..10 {
        let cache_clone = Arc::clone(&cache);
        let handle = thread::spawn(move || {
            cache_clone.insert(SessionSummary::factory(
                format!("session-{i}"),
                PathBuf::from(format!("/project-{i}")),
                None,
            ));
        });
        handles.push(handle);
    }

    // Wait for all threads to complete
    for handle in handles {
        handle.join().unwrap();
    }

    // Verify all sessions were inserted
    assert_eq!(cache.len(), 10);
}
