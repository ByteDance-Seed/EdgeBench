use crate::*;

#[test]
fn test_protocol_version_constant() {
    assert!(!PROTOCOL_VERSION.is_empty());
    let parts: Vec<&str> = PROTOCOL_VERSION.split('.').collect();
    assert_eq!(parts.len(), 3, "Protocol version should be semver format");
    for part in parts {
        assert!(
            part.parse::<u32>().is_ok(),
            "Version part should be numeric"
        );
    }
}

#[test]
fn test_framed_encoding_all_message_types() {
    let messages: Vec<ClientMessage> = vec![
        ClientMessage::Connect {
            client_type: ClientType::Desktop,
            protocol_version: PROTOCOL_VERSION.to_string(),
            auth_token: None,
            session_id: None,
            capabilities: ClientCapabilities::default(),
        },
        ClientMessage::Ping { id: 12345 },
        ClientMessage::SendInput {
            pane_id: "test".to_string(),
            data: vec![0x1b, 0x5b, 0x41],
        },
        ClientMessage::Resize {
            cols: 120,
            rows: 40,
        },
        ClientMessage::Focus {
            pane_id: "supervisor".to_string(),
        },
        ClientMessage::SpawnWorkers {
            count: 3,
            names: vec!["worker-1".to_string()],
        },
        ClientMessage::ShutdownWorkers {
            count: None,
            names: vec![],
            force: false,
        },
        ClientMessage::InjectPrompt {
            pane_id: "worker".to_string(),
            prompt: "Test prompt".to_string(),
        },
        ClientMessage::PlaybackLoad {
            recording_path: "/path/to/recording.rec".to_string(),
        },
        ClientMessage::PlaybackSeek { timestamp_ms: 5000 },
        ClientMessage::PlaybackSetSpeed { speed: 2.0 },
        ClientMessage::PlaybackClose,
    ];

    for msg in messages {
        let framed = codec::encode_framed(&msg).unwrap();

        // Verify frame header
        assert!(framed.len() > codec::FRAME_HEADER_SIZE);
        let header: [u8; 4] = framed[..4].try_into().unwrap();
        let payload_len = codec::read_frame_length(&header);
        assert_eq!(payload_len, framed.len() - codec::FRAME_HEADER_SIZE);

        // Verify payload decodes correctly
        let payload = &framed[codec::FRAME_HEADER_SIZE..];
        let decoded: ClientMessage = codec::decode(payload).unwrap();
        assert_eq!(msg, decoded);
    }
}


// =============================================================================
// PaneRowsUpdate Tests
// =============================================================================



#[test]
fn test_pane_rows_update_unicode_styles() {
    let msg = ServerMessage::PaneRowsUpdate {
        pane_id: "supervisor".to_string(),
        rows: vec![RowData {
            row: 0,
            runs: vec![
                StyleRun::new("🚀 "),
                StyleRun::with_style("日本語", (255, 255, 0), (0, 0, 128), STYLE_BOLD),
                StyleRun::new(" "),
                StyleRun::with_style("Привет", (0, 255, 255), (0, 0, 0), STYLE_ITALIC),
            ],
        }],
        cursor: Some(CursorPosition { x: 10, y: 0 }),
        seq: 1,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

// =============================================================================
