use std::path::PathBuf;
use std::sync::Arc;

use crate::session::resume::{
    UnifiedSessionConfig, UnifiedSessionManager, new_shared_unified_manager,
};
use crate::session::state::{AgentState, SessionState, SessionSummary, SessionType};

// === UnifiedSessionConfig tests ===

#[test]
fn test_unified_session_config_default() {
    let config = UnifiedSessionConfig::default();
    assert_eq!(config.cwd, PathBuf::from("."));
    assert_eq!(config.worker_count, 0);
    assert!(config.worker_names.is_empty());
    assert!(config.supervisor_name.is_none());
    assert!(config.enable_worktrees);
    assert!(!config.record);
    assert_eq!(config.session_type, SessionType::Factory);
}


// === UnifiedSessionManager tests ===




#[test]
fn test_unified_session_manager_get_session() {
    let manager = UnifiedSessionManager::new();

    // Insert directly via cache for testing
    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        Some("supervisor".to_string()),
    ));

    let session = manager.get_session("test-1");
    assert!(session.is_some());
    assert_eq!(session.unwrap().id, "test-1");

    assert!(manager.get_session("nonexistent").is_none());
}

#[test]
fn test_unified_session_manager_contains() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));

    assert!(manager.contains("test-1"));
    assert!(!manager.contains("nonexistent"));
}

#[test]
fn test_unified_session_manager_list_sessions() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project1"),
        None,
    ));
    manager.cache().insert(SessionSummary::managed(
        "test-2".to_string(),
        PathBuf::from("/project2"),
    ));

    let sessions = manager.list_sessions();
    assert_eq!(sessions.len(), 2);

    let ids = manager.list_session_ids();
    assert!(ids.contains(&"test-1".to_string()));
    assert!(ids.contains(&"test-2".to_string()));
}

#[test]
fn test_unified_session_manager_filter_by_type() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "factory-1".to_string(),
        PathBuf::from("/p1"),
        None,
    ));
    manager.cache().insert(SessionSummary::managed(
        "managed-1".to_string(),
        PathBuf::from("/p2"),
    ));
    manager.cache().insert(SessionSummary::recording(
        "recording-1".to_string(),
        PathBuf::from("/p3"),
    ));

    assert_eq!(manager.filter_by_type(SessionType::Factory).len(), 1);
    assert_eq!(manager.filter_by_type(SessionType::Managed).len(), 1);
    assert_eq!(manager.filter_by_type(SessionType::Recording).len(), 1);

    assert_eq!(manager.factory_sessions().len(), 1);
}


#[test]
fn test_unified_session_manager_set_agent_state() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));

    manager.set_agent_state("test-1", "worker-1", AgentState::Active);
    let session = manager.get_session("test-1").unwrap();
    assert_eq!(session.worker_count, 1);
    assert_eq!(
        session.agent_states.get("worker-1"),
        Some(&AgentState::Active)
    );

    manager.set_agent_state("test-1", "worker-1", AgentState::Blocked);
    let session = manager.get_session("test-1").unwrap();
    assert_eq!(
        session.agent_states.get("worker-1"),
        Some(&AgentState::Blocked)
    );

    manager.set_agent_state("test-1", "worker-1", AgentState::Exited);
    let session = manager.get_session("test-1").unwrap();
    assert_eq!(session.worker_count, 0);
    assert!(!session.agent_states.contains_key("worker-1"));
}

#[test]
fn test_unified_session_manager_set_session_state() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));

    let session = manager.get_session("test-1").unwrap();
    assert_eq!(session.state, SessionState::Active);

    manager.set_session_state("test-1", SessionState::Paused);
    let session = manager.get_session("test-1").unwrap();
    assert_eq!(session.state, SessionState::Paused);
}

#[test]
fn test_unified_session_manager_set_epic() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));

    manager.set_epic("test-1", "epic-123");
    let session = manager.get_session("test-1").unwrap();
    assert_eq!(session.epic_id, Some("epic-123".to_string()));
}

#[test]
fn test_unified_session_manager_touch() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));

    let initial = manager.get_session("test-1").unwrap().last_activity;
    std::thread::sleep(std::time::Duration::from_millis(10));
    manager.touch("test-1");
    let updated = manager.get_session("test-1").unwrap().last_activity;

    assert!(updated > initial);
}

#[test]
fn test_unified_session_manager_supervisor_name() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        Some("my-supervisor".to_string()),
    ));

    assert_eq!(
        manager.supervisor_name("test-1"),
        Some("my-supervisor".to_string())
    );
    assert!(manager.supervisor_name("nonexistent").is_none());
}

#[test]
fn test_unified_session_manager_has_active_workers() {
    let manager = UnifiedSessionManager::new();

    manager.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));

    assert!(!manager.has_active_workers("test-1"));

    manager.set_agent_state("test-1", "worker-1", AgentState::Active);
    assert!(manager.has_active_workers("test-1"));
}


#[test]
fn test_unified_session_manager_clone() {
    let manager1 = UnifiedSessionManager::new();
    manager1.cache().insert(SessionSummary::factory(
        "test-1".to_string(),
        PathBuf::from("/project"),
        None,
    ));

    let manager2 = manager1.clone();
    assert_eq!(manager2.len(), 1);

    // Both share the same underlying cache
    manager1.set_epic("test-1", "epic-456");
    let session = manager2.get_session("test-1").unwrap();
    assert_eq!(session.epic_id, Some("epic-456".to_string()));
}

#[test]
fn test_unified_session_manager_default() {
    let manager = UnifiedSessionManager::default();
    assert!(manager.is_empty());
}


// === Integration tests for UnifiedSessionManager with FactoryCore ===

fn test_unified_config() -> UnifiedSessionConfig { todo!() }

#[test]
fn test_unified_manager_create_session_integration() {
    let manager = UnifiedSessionManager::new();
    let config = test_unified_config();

    let result = manager.create_session(config);
    assert!(result.is_ok());

    let session_id = result.unwrap();
    assert!(session_id.starts_with("unified-"));

    // Verify cache was populated
    assert_eq!(manager.len(), 1);
    assert!(manager.contains(&session_id));

    // Verify session summary has correct values
    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.id, session_id);
    assert_eq!(summary.session_type, SessionType::Factory);
    assert_eq!(summary.state, SessionState::Active);
    assert_eq!(summary.supervisor_name, Some("test-supervisor".to_string()));
    assert_eq!(summary.project_dir, std::env::temp_dir());
    assert!(!summary.recording_enabled);
}

#[test]
fn test_unified_manager_create_multiple_sessions() {
    let manager = UnifiedSessionManager::new();

    let id1 = manager.create_session(test_unified_config()).unwrap();
    let id2 = manager.create_session(test_unified_config()).unwrap();
    let id3 = manager.create_session(test_unified_config()).unwrap();

    // All sessions should exist and have unique IDs
    assert_eq!(manager.len(), 3);
    assert_ne!(id1, id2);
    assert_ne!(id2, id3);
    assert_ne!(id1, id3);

    // All should be retrievable
    assert!(manager.get_session(&id1).is_some());
    assert!(manager.get_session(&id2).is_some());
    assert!(manager.get_session(&id3).is_some());
}


#[test]
fn test_unified_manager_close_session_removes_from_cache() {
    let manager = UnifiedSessionManager::new();
    let session_id = manager.create_session(test_unified_config()).unwrap();

    assert_eq!(manager.len(), 1);

    // Close the session
    let result = manager.close_session(&session_id);
    assert!(result.is_ok());

    // Session should be removed from cache
    assert_eq!(manager.len(), 0);
    assert!(!manager.contains(&session_id));
    assert!(manager.get_session(&session_id).is_none());
}

#[test]
fn test_unified_manager_managed_session_type() {
    let manager = UnifiedSessionManager::new();
    let config = UnifiedSessionConfig::new(std::env::temp_dir()).with_type(SessionType::Managed);

    let session_id = manager.create_session(config).unwrap();

    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.session_type, SessionType::Managed);
    assert!(summary.is_managed());
    assert!(!summary.is_factory());
}

#[test]
fn test_unified_manager_recording_session_type() {
    let manager = UnifiedSessionManager::new();
    let config = UnifiedSessionConfig::new(std::env::temp_dir())
        .with_type(SessionType::Recording)
        .with_recording(true);

    let session_id = manager.create_session(config).unwrap();

    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.session_type, SessionType::Recording);
    assert!(summary.is_recording());
    assert!(summary.recording_enabled);
}

#[test]
fn test_unified_manager_poll_events_empty_initially() {
    let manager = UnifiedSessionManager::new();
    let session_id = manager.create_session(test_unified_config()).unwrap();

    // No events initially
    let events = manager.poll_events(&session_id);
    assert!(events.is_empty());

    // Poll all also empty
    let all_events = manager.poll_all_events();
    assert!(all_events.is_empty());
}

#[test]
fn test_unified_manager_worker_names_empty_initially() {
    let manager = UnifiedSessionManager::new();
    let session_id = manager.create_session(test_unified_config()).unwrap();

    let workers = manager.worker_names(&session_id);
    assert!(workers.is_empty());
}

// Note: Concurrent access test removed because FactoryCore contains
// PTY handles that are not Send-safe. In practice, UnifiedSessionManager
// is accessed from a single event loop (Tauri/Tokio), not multiple OS threads.

#[test]
fn test_unified_manager_filter_sessions_after_create() {
    let manager = UnifiedSessionManager::new();

    // Create different session types
    manager
        .create_session(
            UnifiedSessionConfig::new(std::env::temp_dir()).with_type(SessionType::Factory),
        )
        .unwrap();
    manager
        .create_session(
            UnifiedSessionConfig::new(std::env::temp_dir()).with_type(SessionType::Factory),
        )
        .unwrap();
    manager
        .create_session(
            UnifiedSessionConfig::new(std::env::temp_dir()).with_type(SessionType::Managed),
        )
        .unwrap();

    assert_eq!(manager.len(), 3);
    assert_eq!(manager.factory_sessions().len(), 2);
    assert_eq!(manager.filter_by_type(SessionType::Managed).len(), 1);
    assert_eq!(manager.active_sessions().len(), 3);
}

#[test]
fn test_unified_manager_cache_invalidation_on_state_change() {
    let manager = UnifiedSessionManager::new();
    let session_id = manager.create_session(test_unified_config()).unwrap();

    // Initial state
    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.state, SessionState::Active);
    assert_eq!(summary.worker_count, 0);

    // Change state
    manager.set_session_state(&session_id, SessionState::Paused);

    // Verify cache was updated
    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.state, SessionState::Paused);

    // Add agent state
    manager.set_agent_state(&session_id, "worker-1", AgentState::Active);

    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.worker_count, 1);
    assert_eq!(
        summary.agent_states.get("worker-1"),
        Some(&AgentState::Active)
    );

    // Remove agent (mark as exited)
    manager.set_agent_state(&session_id, "worker-1", AgentState::Exited);

    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.worker_count, 0);
    assert!(!summary.agent_states.contains_key("worker-1"));
}

#[test]
fn test_unified_manager_metadata_accuracy() {
    let manager = UnifiedSessionManager::new();
    let config = UnifiedSessionConfig::new(std::env::temp_dir())
        .with_supervisor("my-supervisor")
        .with_workers(3)
        .with_recording(true);

    let session_id = manager.create_session(config).unwrap();

    // Verify all metadata is accurate
    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.supervisor_name, Some("my-supervisor".to_string()));
    assert!(summary.recording_enabled);
    assert_eq!(summary.project_dir, std::env::temp_dir());
    assert_eq!(summary.session_type, SessionType::Factory);
    assert_eq!(summary.state, SessionState::Active);
    assert_eq!(summary.total_output_bytes, 0);
    assert!(summary.epic_id.is_none());

    // Set epic
    manager.set_epic(&session_id, "epic-test-123");
    let summary = manager.get_session(&session_id).unwrap();
    assert_eq!(summary.epic_id, Some("epic-test-123".to_string()));
}
