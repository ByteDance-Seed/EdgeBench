use crate::*;


#[test]
fn test_all_session_mode_variants() {
    let variants = vec![SessionMode::Live, SessionMode::Playback];

    for mode in variants {
        let msg = ServerMessage::Connected {
            session_id: "test".to_string(),
            client_id: 1,
            mode,
        };
        let encoded = codec::encode(&msg).unwrap();
        let decoded: ServerMessage = codec::decode(&encoded).unwrap();
        assert_eq!(msg, decoded, "SessionMode {mode:?} roundtrip failed");
    }
}

#[test]
fn test_all_error_code_variants() {
    let variants = vec![
        ErrorCode::VersionMismatch,
        ErrorCode::InvalidMessage,
        ErrorCode::PaneNotFound,
        ErrorCode::RecordingNotFound,
        ErrorCode::InvalidMode,
        ErrorCode::SessionNotFound,
        ErrorCode::Internal,
    ];

    for code in variants {
        let msg = ServerMessage::Error {
            code,
            message: format!("Test error: {code:?}"),
        };
        let encoded = codec::encode(&msg).unwrap();
        let decoded: ServerMessage = codec::decode(&encoded).unwrap();
        assert_eq!(msg, decoded, "ErrorCode {code:?} roundtrip failed");
    }
}

#[test]
fn test_all_pane_kind_variants() {
    let variants = vec![
        PaneKind::Worker,
        PaneKind::Supervisor,
        PaneKind::Director,
        PaneKind::Shell,
    ];

    for kind in variants {
        let pane = PaneInfo {
            id: "test".to_string(),
            kind,
            focused: true,
            title: format!("Test {kind:?}"),
            exited: false,
        };
        let msg = ServerMessage::PaneAdded { pane };
        let encoded = codec::encode(&msg).unwrap();
        let decoded: ServerMessage = codec::decode(&encoded).unwrap();
        assert_eq!(msg, decoded, "PaneKind {kind:?} roundtrip failed");
    }
}

#[test]
fn test_all_style_flag_combinations() {
    let flags_to_test = vec![
        0,
        STYLE_BOLD,
        STYLE_ITALIC,
        STYLE_UNDERLINE,
        STYLE_INVERSE,
        STYLE_STRIKETHROUGH,
        STYLE_FAINT,
        STYLE_BOLD | STYLE_ITALIC,
        STYLE_BOLD | STYLE_UNDERLINE | STYLE_INVERSE,
        STYLE_BOLD | STYLE_ITALIC | STYLE_UNDERLINE | STYLE_STRIKETHROUGH | STYLE_FAINT,
    ];

    for flags in flags_to_test {
        let cell = TerminalCell {
            codepoint: b'X' as u32,
            fg: (255, 255, 255),
            bg: (0, 0, 0),
            flags,
            width: 1,
        };
        let snapshot = TerminalSnapshot {
            cells: vec![cell],
            cursor: CursorPosition { x: 0, y: 0 },
            cols: 1,
            rows: 1,
        };
        let mut snapshots = HashMap::new();
        snapshots.insert("test".to_string(), snapshot);

        let msg = ServerMessage::PlaybackSnapshot {
            timestamp_ms: 0,
            snapshots,
        };
        let encoded = codec::encode(&msg).unwrap();
        let decoded: ServerMessage = codec::decode(&encoded).unwrap();
        assert_eq!(msg, decoded, "Style flags {flags:032b} roundtrip failed");
    }
}

// =============================================================================
// Complex Nested Types
// =============================================================================

#[test]
fn test_full_session_state() {
    let state = SessionState {
        focused_pane: Some("supervisor".to_string()),
        panes: vec![
            PaneInfo {
                id: "supervisor".to_string(),
                kind: PaneKind::Supervisor,
                focused: true,
                title: "Supervisor (zealous-octopus)".to_string(),
                exited: false,
            },
            PaneInfo {
                id: "worker-1".to_string(),
                kind: PaneKind::Worker,
                focused: false,
                title: "Worker (bright-shark)".to_string(),
                exited: false,
            },
            PaneInfo {
                id: "director".to_string(),
                kind: PaneKind::Director,
                focused: false,
                title: "Director".to_string(),
                exited: false,
            },
        ],
        epic_id: Some("cas-402d".to_string()),
        epic_title: Some("CAS Factory Client-Server Architecture".to_string()),
        cols: 120,
        rows: 40,
    };

    let msg = ServerMessage::FullState { state };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_full_director_data() {
    let data = DirectorData {
        ready_tasks: vec![
            TaskSummary {
                id: "cas-1234".to_string(),
                title: "Implement feature X".to_string(),
                status: "open".to_string(),
                priority: 1,
                assignee: None,
                task_type: "feature".to_string(),
                epic: Some("cas-402d".to_string()),
                branch: None,
            },
            TaskSummary {
                id: "cas-5678".to_string(),
                title: "Fix bug Y".to_string(),
                status: "open".to_string(),
                priority: 0,
                assignee: None,
                task_type: "bug".to_string(),
                epic: None,
                branch: None,
            },
        ],
        in_progress_tasks: vec![TaskSummary {
            id: "cas-81bb".to_string(),
            title: "Add integration tests".to_string(),
            status: "in_progress".to_string(),
            priority: 2,
            assignee: Some("bright-shark".to_string()),
            task_type: "task".to_string(),
            epic: Some("cas-402d".to_string()),
            branch: Some("feature/cas-81bb".to_string()),
        }],
        epic_tasks: vec![TaskSummary {
            id: "cas-402d".to_string(),
            title: "CAS Factory Client-Server Architecture".to_string(),
            status: "in_progress".to_string(),
            priority: 1,
            assignee: Some("zealous-octopus".to_string()),
            task_type: "epic".to_string(),
            epic: None,
            branch: Some("epic/cas-402d".to_string()),
        }],
        agents: vec![
            AgentSummary {
                id: "agent-001".to_string(),
                name: "zealous-octopus".to_string(),
                status: "active".to_string(),
                current_task: Some("cas-402d".to_string()),
                latest_activity: Some("Assigned task to worker".to_string()),
                last_heartbeat: Some("2026-01-28T12:00:00Z".to_string()),
            },
            AgentSummary {
                id: "agent-002".to_string(),
                name: "bright-shark".to_string(),
                status: "active".to_string(),
                current_task: Some("cas-81bb".to_string()),
                latest_activity: Some("Writing tests".to_string()),
                last_heartbeat: Some("2026-01-28T12:00:05Z".to_string()),
            },
        ],
        activity: vec![
            ActivityEvent {
                event_type: "task_started".to_string(),
                summary: "bright-shark started cas-81bb".to_string(),
                session_id: Some("agent-002".to_string()),
                task_id: Some("cas-81bb".to_string()),
                created_at: "2026-01-28T11:55:00Z".to_string(),
            },
            ActivityEvent {
                event_type: "task_completed".to_string(),
                summary: "proud-tiger completed cas-xyz".to_string(),
                session_id: Some("agent-003".to_string()),
                task_id: Some("cas-xyz".to_string()),
                created_at: "2026-01-28T11:50:00Z".to_string(),
            },
        ],
        changes: vec![
            SourceChanges {
                source_name: "bright-shark".to_string(),
                source_path: "/tmp/worktrees/bright-shark".to_string(),
                agent_name: Some("bright-shark".to_string()),
                changes: vec![
                    FileChange {
                        file_path: "crates/cas-factory-protocol/tests/protocol_tests.rs"
                            .to_string(),
                        lines_added: 500,
                        lines_removed: 0,
                        status: "added".to_string(),
                        staged: true,
                    },
                    FileChange {
                        file_path: "crates/cas-factory-protocol/src/codec.rs".to_string(),
                        lines_added: 10,
                        lines_removed: 5,
                        status: "modified".to_string(),
                        staged: false,
                    },
                ],
                total_added: 510,
                total_removed: 5,
            },
            SourceChanges {
                source_name: "main".to_string(),
                source_path: "/tmp/repo".to_string(),
                agent_name: None,
                changes: vec![],
                total_added: 0,
                total_removed: 0,
            },
        ],
    };

    let msg = ServerMessage::DirectorUpdate { data };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_playback_metadata() {
    let metadata = PlaybackMetadata {
        duration_ms: 3_600_000, // 1 hour
        keyframe_count: 1800,   // Every 2 seconds
        cols: 120,
        rows: 40,
        agent_name: "zealous-octopus".to_string(),
        session_id: "session-12345".to_string(),
        agent_role: "supervisor".to_string(),
        created_at: "2026-01-28T10:00:00Z".to_string(),
    };

    let msg = ServerMessage::PlaybackOpened { metadata };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_multiple_pane_snapshots() {
    let mut snapshots = HashMap::new();

    // Supervisor pane
    snapshots.insert("supervisor".to_string(), TerminalSnapshot::empty(120, 40));

    // Worker panes
    for i in 1..=3 {
        snapshots.insert(format!("worker-{i}"), TerminalSnapshot::empty(80, 24));
    }

    // Director pane
    snapshots.insert("director".to_string(), TerminalSnapshot::empty(60, 30));

    let msg = ServerMessage::PlaybackSnapshot {
        timestamp_ms: 60_000,
        snapshots,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

// =============================================================================
