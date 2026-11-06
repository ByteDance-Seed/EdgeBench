#[test]
fn test_decode_empty_bytes() {
    let result = codec::decode::<ClientMessage>(&[]);
    assert!(result.is_err());
}

#[test]
fn test_decode_wrong_message_type() {
    // Encode a ClientMessage but try to decode as ServerMessage
    // Using InjectPrompt since it doesn't have a matching variant in ServerMessage
    let msg = ClientMessage::InjectPrompt {
        pane_id: "test-pane".to_string(),
        prompt: "Hello".to_string(),
    };
    let encoded = codec::encode(&msg).unwrap();

    // This should fail because the message structure doesn't match
    let result = codec::decode::<ServerMessage>(&encoded);
    assert!(result.is_err());
}

#[test]
fn test_max_u16_dimensions() {
    let msg = ClientMessage::Resize {
        cols: u16::MAX,
        rows: u16::MAX,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_extreme_color_values() {
    let cells = vec![
        TerminalCell {
            codepoint: b'X' as u32,
            fg: (0, 0, 0),       // Black
            bg: (255, 255, 255), // White
            flags: 0,
            width: 1,
        },
        TerminalCell {
            codepoint: b'Y' as u32,
            fg: (255, 0, 0), // Pure red
            bg: (0, 255, 0), // Pure green
            flags: STYLE_BOLD,
            width: 1,
        },
        TerminalCell {
            codepoint: b'Z' as u32,
            fg: (0, 0, 255),     // Pure blue
            bg: (128, 128, 128), // Gray
            flags: 0,
            width: 1,
        },
    ];

    let snapshot = TerminalSnapshot {
        cells,
        cursor: CursorPosition { x: 0, y: 0 },
        cols: 3,
        rows: 1,
    };

    let mut snapshots = HashMap::new();
    snapshots.insert("colors".to_string(), snapshot);

    let msg = ServerMessage::PlaybackSnapshot {
        timestamp_ms: 0,
        snapshots,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}
