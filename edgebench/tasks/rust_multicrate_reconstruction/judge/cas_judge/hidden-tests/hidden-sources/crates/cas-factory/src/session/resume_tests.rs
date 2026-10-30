#[test]
fn test_unified_session_config_builder() {
    let config = UnifiedSessionConfig::new("/project")
        .with_type(SessionType::Managed)
        .with_supervisor("my-supervisor")
        .with_workers(3)
        .with_worker_names(vec!["w1".to_string(), "w2".to_string()])
        .with_worktrees(false)
        .with_recording(true);

    assert_eq!(config.cwd, PathBuf::from("/project"));
    assert_eq!(config.session_type, SessionType::Managed);
    assert_eq!(config.supervisor_name, Some("my-supervisor".to_string()));
    assert_eq!(config.worker_count, 3);
    assert_eq!(config.worker_names, vec!["w1", "w2"]);
    assert!(!config.enable_worktrees);
    assert!(config.record);
}

#[test]
fn test_unified_session_manager_new() {
    let manager = UnifiedSessionManager::new();
    assert!(manager.is_empty());
    assert_eq!(manager.len(), 0);
}

#[test]
fn test_unified_session_manager_with_capacity() {
    let manager = UnifiedSessionManager::with_capacity(10);
    assert!(manager.is_empty());
}

#[test]
fn test_unified_session_manager_generate_id() {
    let manager = UnifiedSessionManager::new();
    let id1 = manager.generate_id();
    let id2 = manager.generate_id();

    assert!(id1.starts_with("unified-"));
    assert!(id2.starts_with("unified-"));
    assert_ne!(id1, id2);
}

#[test]
fn test_unified_session_manager_filter_by_state() {
    let manager = UnifiedSessionManager::new();

    let mut active = SessionSummary::factory("s1".to_string(), PathBuf::from("/p1"), None);
    active.state = SessionState::Active;
    manager.cache().insert(active);

    let mut paused = SessionSummary::factory("s2".to_string(), PathBuf::from("/p2"), None);
    paused.state = SessionState::Paused;
    manager.cache().insert(paused);

    assert_eq!(manager.filter_by_state(SessionState::Active).len(), 1);
    assert_eq!(manager.filter_by_state(SessionState::Paused).len(), 1);
    assert_eq!(manager.active_sessions().len(), 1);
}

#[test]
fn test_unified_session_manager_is_recording() {
    let manager = UnifiedSessionManager::new();

    let mut summary =
        SessionSummary::factory("test-1".to_string(), PathBuf::from("/project"), None);
    summary.recording_enabled = false;
    manager.cache().insert(summary);

    let mut summary = SessionSummary::recording("test-2".to_string(), PathBuf::from("/project2"));
    summary.recording_enabled = true;
    manager.cache().insert(summary);

    assert!(!manager.is_recording("test-1"));
    assert!(manager.is_recording("test-2"));
}

#[test]
fn test_new_shared_unified_manager() {
    let shared = new_shared_unified_manager();
    assert!(shared.is_empty());

    // Can clone and share across threads
    let shared2 = Arc::clone(&shared);
    assert_eq!(Arc::strong_count(&shared), 2);
    drop(shared2);
    assert_eq!(Arc::strong_count(&shared), 1);
}

#[test]
fn test_unified_manager_with_core_access() {
    let manager = UnifiedSessionManager::new();
    let session_id = manager.create_session(test_unified_config()).unwrap();

    // Should be able to access FactoryCore
    let has_core = manager.with_core_ref(&session_id, |core| {
        // Verify core is properly initialized
        assert!(core.supervisor_name().is_none()); // Not spawned yet
        assert!(core.worker_names().is_empty());
        true
    });
    assert_eq!(has_core, Some(true));

    // Non-existent session returns None
    let no_core = manager.with_core_ref("nonexistent", |_| true);
    assert!(no_core.is_none());
}
