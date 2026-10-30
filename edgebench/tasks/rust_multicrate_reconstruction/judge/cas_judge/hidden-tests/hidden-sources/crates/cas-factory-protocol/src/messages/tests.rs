    #[test]
    fn test_client_message_serde() {
        let msg = ClientMessage::Connect {
            client_type: ClientType::Tui,
            protocol_version: "1.0.0".to_string(),
            auth_token: None,
            session_id: Some("test-session".to_string()),
            capabilities: ClientCapabilities::default(),
        };
        let json = serde_json::to_string(&msg).unwrap();
        let decoded: ClientMessage = serde_json::from_str(&json).unwrap();
        assert_eq!(msg, decoded);
    }

    #[test]
    fn test_terminal_snapshot_empty() {
        let snapshot = TerminalSnapshot::empty(80, 24);
        assert_eq!(snapshot.cells.len(), 80 * 24);
        assert_eq!(snapshot.cols, 80);
        assert_eq!(snapshot.rows, 24);
    }

    #[test]
    fn test_row_data_serde() {
        let row = RowData {
            row: 5,
            runs: vec![
                StyleRun::new("prefix: "),
                StyleRun::with_style("error", (255, 0, 0), (0, 0, 0), 0),
            ],
        };
        let json = serde_json::to_string(&row).unwrap();
        let decoded: RowData = serde_json::from_str(&json).unwrap();
        assert_eq!(row, decoded);
    }

    #[test]
    fn test_scroll_without_cache_window_backward_compatible() {
        // Test that messages without cache_window (old format) can be decoded
        let json = r#"{"type":"scroll","pane_id":"test","delta":5}"#;
        let decoded: ClientMessage = serde_json::from_str(json).unwrap();
        match decoded {
            ClientMessage::Scroll { cache_window, .. } => {
                assert_eq!(cache_window, 0);
            }
            _ => panic!("Expected Scroll"),
        }
    }

    #[test]
    fn test_scroll_zero_cache_window_skipped() {
        // Test that cache_window=0 is not serialized (skip_serializing_if)
        let msg = ClientMessage::Scroll {
            pane_id: "worker-1".to_string(),
            delta: 5,
            cache_window: 0,
            target_offset: None,
            request_id: None,
        };
        let json = serde_json::to_string(&msg).unwrap();
        assert!(!json.contains("cache_window"));
    }

    #[test]
    fn test_reconnect_message_serde() {
        let msg = ClientMessage::Reconnect {
            protocol_version: PROTOCOL_VERSION.to_string(),
            auth_token: Some("token-abc".to_string()),
            client_type: ClientType::Tui,
            capabilities: ClientCapabilities {
                raw_pty_output: false,
                row_snapshots: true,
            },
            session_id: "session-123".to_string(),
            client_id: "client-456".to_string(),
            last_seq: 42,
        };
        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("reconnect"));
        assert!(json.contains("protocol_version"));
        assert!(json.contains("client_type"));
        assert!(json.contains("capabilities"));
        assert!(json.contains("session_id"));
        assert!(json.contains("client_id"));
        assert!(json.contains("last_seq"));
        assert!(json.contains("auth_token"));
        let decoded: ClientMessage = serde_json::from_str(&json).unwrap();
        assert_eq!(msg, decoded);
    }

    #[test]
    fn test_connection_health_message_serde() {
        let qualities = [
            ConnectionQuality::Excellent,
            ConnectionQuality::Good,
            ConnectionQuality::Fair,
            ConnectionQuality::Poor,
            ConnectionQuality::Degraded,
        ];

        for quality in qualities {
            let msg = ServerMessage::ConnectionHealth {
                rtt_ms: 50,
                quality,
            };
            let json = serde_json::to_string(&msg).unwrap();
            assert!(json.contains("connection_health"));
            assert!(json.contains("rtt_ms"));
            assert!(json.contains("quality"));
            let decoded: ServerMessage = serde_json::from_str(&json).unwrap();
            assert_eq!(msg, decoded);
        }
    }

    #[test]
    fn test_boot_progress_serde() {
        let msg = ServerMessage::BootProgress {
            step: "Loading configuration".to_string(),
            step_num: 1,
            total_steps: 5,
            completed: false,
        };
        let json = serde_json::to_string(&msg).unwrap();
        assert!(json.contains("boot_progress"));
        assert!(json.contains("Loading configuration"));
        assert!(json.contains("step_num"));
        assert!(json.contains("total_steps"));
        let decoded: ServerMessage = serde_json::from_str(&json).unwrap();
        assert_eq!(msg, decoded);

        // Test completed step
        let completed = ServerMessage::BootProgress {
            step: "Loading configuration".to_string(),
            step_num: 1,
            total_steps: 5,
            completed: true,
        };
        let json_completed = serde_json::to_string(&completed).unwrap();
        let decoded_completed: ServerMessage = serde_json::from_str(&json_completed).unwrap();
        assert_eq!(completed, decoded_completed);
    }
