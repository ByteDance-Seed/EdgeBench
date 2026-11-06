#[test]
fn test_factory_config_with_recording() {
    let config = FactoryConfig {
        record: true,
        session_id: Some("session-123".to_string()),
        ..Default::default()
    };

    assert!(config.record);
    assert_eq!(config.session_id, Some("session-123".to_string()));
}

#[test]
fn test_epic_state_default() {
    let state = EpicState::default();

    assert!(matches!(state, EpicState::Idle));
    assert!(!state.is_active());
}

#[test]
fn test_notify_config_default() {
    let config = NotifyConfig::default();

    assert!(!config.enabled);
    assert!(!config.also_bell);
    // Backend is detected based on environment
}

#[test]
fn test_notify_backend_detect() {
    // This will return Native on macOS/Linux/Windows, Bell otherwise
    let backend = NotifyBackend::detect();

    // We can't assert a specific backend since it depends on environment
    // Just verify it's a valid variant
    match backend {
        NotifyBackend::Native | NotifyBackend::Bell | NotifyBackend::ITerm2 => {
            // Valid backend detected
        }
    }
}

#[test]
fn test_factory_core_initial_state() {
    let config = test_config();
    let core = FactoryCore::new(config).unwrap();

    // Initially no panes
    assert!(core.panes().is_empty());
    assert!(core.supervisor_name().is_none());
    assert!(core.worker_names().is_empty());

    // Terminal size should be valid
    let (cols, rows) = core.terminal_size();
    assert!(cols > 0);
    assert!(rows > 0);
}

#[test]
fn test_shutdown_nonexistent_worker_fails() {
    let config = test_config();
    let mut core = FactoryCore::new(config).unwrap();

    // Shutting down non-existent worker should fail
    let result = core.shutdown_worker("nonexistent");
    assert!(matches!(result, Err(FactoryError::WorkerNotFound(_))));
}

#[test]
fn test_set_cas_root() {
    let config = test_config();
    let mut core = FactoryCore::new(config).unwrap();

    let cas_root = PathBuf::from("/path/to/.cas");
    core.set_cas_root(cas_root);

    // No direct getter, but this should not panic
}

#[test]
fn test_git_file_status_symbol() {
    assert_eq!(GitFileStatus::Modified.symbol(), "M");
    assert_eq!(GitFileStatus::Added.symbol(), "A");
    assert_eq!(GitFileStatus::Deleted.symbol(), "D");
    assert_eq!(GitFileStatus::Renamed.symbol(), "R");
    assert_eq!(GitFileStatus::Untracked.symbol(), "?");
}

#[test]
fn test_file_change_info_creation() {
    let change = FileChangeInfo {
        file_path: "src/lib.rs".to_string(),
        lines_added: 50,
        lines_removed: 10,
        status: GitFileStatus::Modified,
        staged: true,
    };

    assert_eq!(change.file_path, "src/lib.rs");
    assert_eq!(change.lines_added, 50);
    assert_eq!(change.lines_removed, 10);
    assert_eq!(change.status, GitFileStatus::Modified);
    assert!(change.staged);
}

#[test]
fn test_source_changes_info_creation() {
    let changes = vec![
        FileChangeInfo {
            file_path: "src/main.rs".to_string(),
            lines_added: 100,
            lines_removed: 20,
            status: GitFileStatus::Modified,
            staged: true,
        },
        FileChangeInfo {
            file_path: "src/new.rs".to_string(),
            lines_added: 50,
            lines_removed: 0,
            status: GitFileStatus::Added,
            staged: false,
        },
    ];

    let source = SourceChangesInfo {
        source_name: "worker-1".to_string(),
        source_path: PathBuf::from("/tmp/worktrees/worker-1"),
        agent_name: Some("swift-fox".to_string()),
        changes,
        total_added: 150,
        total_removed: 20,
    };

    assert_eq!(source.source_name, "worker-1");
    assert_eq!(source.agent_name, Some("swift-fox".to_string()));
    assert_eq!(source.changes.len(), 2);
    assert_eq!(source.total_added, 150);
    assert_eq!(source.total_removed, 20);
}
