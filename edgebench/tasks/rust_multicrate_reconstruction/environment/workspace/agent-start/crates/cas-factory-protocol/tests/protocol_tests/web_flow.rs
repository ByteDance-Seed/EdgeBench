use crate::*;

#[test]
fn test_raw_pty_output_small() {
    // Small raw PTY output (below compression threshold)
    let msg = ServerMessage::PaneOutput {
        pane_id: "worker-1".to_string(),
        data: b"Hello, terminal!\r\n".to_vec(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_raw_pty_output_with_ansi_codes() {
    // Raw PTY output with ANSI escape codes (typical Claude output)
    let ansi_data = b"\x1b[1;34m\xe2\x9d\xaf\x1b[0m Let me help you with that.\r\n\
        \x1b[38;5;243m```rust\x1b[0m\r\n\
        \x1b[38;5;208mfn\x1b[0m \x1b[38;5;33mmain\x1b[0m() {\r\n\
        \x1b[38;5;243m```\x1b[0m\r\n";

    let msg = ServerMessage::PaneOutput {
        pane_id: "supervisor".to_string(),
        data: ansi_data.to_vec(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_raw_pty_output_large_compressed() {
    // Large raw PTY output (above compression threshold, should compress)
    // Simulates a large code block or verbose output
    let mut large_data = Vec::with_capacity(5000);
    for i in 0..100 {
        large_data.extend_from_slice(
            format!(
            "\x1b[38;5;243m{i:4}\x1b[0m│ fn function_{i}() {{ println!(\"Hello from {i}\"); }}\r\n"
        )
            .as_bytes(),
        );
    }

    let msg = ServerMessage::PaneOutput {
        pane_id: "worker-1".to_string(),
        data: large_data.clone(),
    };
    let encoded = codec::encode(&msg).unwrap();

    // Verify compression happened (encoded should be smaller than data)
    assert!(
        encoded.len() < large_data.len(),
        "Large PTY data should compress"
    );

    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_batch_with_pane_output() {
    // Batch message containing multiple PaneOutput messages
    let msg = ServerMessage::Batch {
        messages: vec![
            ServerMessage::PaneOutput {
                pane_id: "worker-1".to_string(),
                data: b"Output from worker 1\r\n".to_vec(),
            },
            ServerMessage::PaneOutput {
                pane_id: "worker-2".to_string(),
                data: b"Output from worker 2\r\n".to_vec(),
            },
            ServerMessage::PaneOutput {
                pane_id: "supervisor".to_string(),
                data: b"\x1b[32m\xe2\x9c\x93\x1b[0m Task complete\r\n".to_vec(),
            },
        ],
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_batch_mixed_messages() {
    // Batch with mixed message types (common in web client scenario)
    let msg = ServerMessage::Batch {
        messages: vec![
            ServerMessage::PaneOutput {
                pane_id: "worker-1".to_string(),
                data: b"Processing...\r\n".to_vec(),
            },
            ServerMessage::DirectorUpdate {
                data: DirectorData {
                    ready_tasks: vec![],
                    in_progress_tasks: vec![TaskSummary {
                        id: "task-1".to_string(),
                        title: "Test task".to_string(),
                        status: "in_progress".to_string(),
                        priority: 2,
                        assignee: Some("worker-1".to_string()),
                        task_type: "task".to_string(),
                        epic: None,
                        branch: None,
                    }],
                    epic_tasks: vec![],
                    agents: vec![],
                    activity: vec![],
                    changes: vec![],
                },
            },
            ServerMessage::PaneOutput {
                pane_id: "worker-1".to_string(),
                data: b"Done!\r\n".to_vec(),
            },
        ],
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_client_capabilities_raw_pty() {
    // Verify raw_pty_output capability in Connect message
    let msg = ClientMessage::Connect {
        client_type: ClientType::Desktop,
        protocol_version: PROTOCOL_VERSION.to_string(),
        auth_token: None,
        session_id: None,
        capabilities: ClientCapabilities {
            raw_pty_output: true, // Web client uses ghostty-web
            row_snapshots: false,
        },
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);

    // Verify the capability is correctly set
    if let ClientMessage::Connect { capabilities, .. } = decoded {
        assert!(capabilities.raw_pty_output);
        assert!(!capabilities.row_snapshots);
    } else {
        panic!("Expected Connect message");
    }
}

#[test]
fn test_connection_health_message() {
    // ConnectionHealth message for web client monitoring
    let msg = ServerMessage::ConnectionHealth {
        rtt_ms: 42,
        quality: cas_factory_protocol::ConnectionQuality::Good,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_reconnect_flow() {
    // Test Reconnect request message
    let reconnect_msg = ClientMessage::Reconnect {
        protocol_version: PROTOCOL_VERSION.to_string(),
        auth_token: Some("token-abc".to_string()),
        client_type: ClientType::Tui,
        capabilities: ClientCapabilities {
            raw_pty_output: false,
            row_snapshots: true,
        },
        session_id: "session-123".to_string(),
        client_id: "client-456".to_string(),
        last_seq: 100,
    };
    let encoded = codec::encode(&reconnect_msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(reconnect_msg, decoded);

    // Test ReconnectAccepted response
    let accepted_msg = ServerMessage::ReconnectAccepted {
        new_client_id: "client-789".to_string(),
        resync_needed: false,
    };
    let encoded = codec::encode(&accepted_msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(accepted_msg, decoded);

    // Test with resync needed
    let resync_msg = ServerMessage::ReconnectAccepted {
        new_client_id: "client-999".to_string(),
        resync_needed: true,
    };
    let encoded = codec::encode(&resync_msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(resync_msg, decoded);
}

