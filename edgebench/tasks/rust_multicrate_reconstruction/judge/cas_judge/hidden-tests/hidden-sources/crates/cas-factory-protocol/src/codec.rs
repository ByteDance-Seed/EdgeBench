    #[test]
    fn test_roundtrip_server_message() {
        let messages = vec![
            ServerMessage::Connected {
                session_id: "test-session-123".to_string(),
                client_id: 1,
                mode: SessionMode::Live,
            },
            ServerMessage::Pong { id: 42 },
            ServerMessage::Error {
                code: crate::ErrorCode::PaneNotFound,
                message: "Pane 'worker-99' not found".to_string(),
            },
            ServerMessage::PaneRowsUpdate {
                pane_id: "supervisor".to_string(),
                rows: vec![crate::RowData {
                    row: 0,
                    runs: vec![crate::StyleRun::new("Hello, world!")],
                }],
                cursor: Some(crate::CursorPosition { x: 0, y: 0 }),
                seq: 1,
            },
            ServerMessage::PaneExited {
                pane_id: "worker-1".to_string(),
                exit_code: Some(0),
            },
            ServerMessage::PaneAdded {
                pane: crate::PaneInfo {
                    id: "worker-2".to_string(),
                    kind: crate::PaneKind::Worker,
                    focused: false,
                    title: "Worker 2".to_string(),
                    exited: false,
                },
            },
            ServerMessage::PaneRemoved {
                pane_id: "worker-1".to_string(),
            },
        ];

        for msg in messages {
            let encoded = encode(&msg).expect("encode failed");
            let decoded: ServerMessage = decode(&encoded).expect("decode failed");
            assert_eq!(msg, decoded, "roundtrip failed for {msg:?}");
        }
    }

    #[test]
    fn test_framed_encoding() {
        let msg = ClientMessage::Ping { id: 99 };
        let framed = encode_framed(&msg).expect("framed encode failed");

        // Check header
        assert!(framed.len() > FRAME_HEADER_SIZE);
        let header: [u8; 4] = framed[..4].try_into().unwrap();
        let payload_len = read_frame_length(&header);
        assert_eq!(payload_len, framed.len() - FRAME_HEADER_SIZE);

        // Decode payload
        let payload = &framed[FRAME_HEADER_SIZE..];
        let decoded: ClientMessage = decode(payload).expect("decode failed");
        assert_eq!(msg, decoded);
    }

    #[test]
    fn test_small_message_uncompressed() {
        use crate::compression::PREFIX_UNCOMPRESSED;

        let msg = ClientMessage::Ping { id: 42 };
        let encoded = encode(&msg).expect("encode failed");

        // Small messages should have uncompressed prefix
        assert_eq!(encoded[0], PREFIX_UNCOMPRESSED);
    }
