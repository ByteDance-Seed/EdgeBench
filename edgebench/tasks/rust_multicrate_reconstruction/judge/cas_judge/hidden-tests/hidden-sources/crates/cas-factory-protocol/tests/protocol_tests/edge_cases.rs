#[test]
fn test_empty_vec_fields() {
    // Empty data in SendInput
    let msg = ClientMessage::SendInput {
        pane_id: "test".to_string(),
        data: vec![],
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);

    // Empty names in SpawnWorkers
    let msg = ClientMessage::SpawnWorkers {
        count: 3,
        names: vec![],
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);

    // Empty PaneRowsUpdate
    let msg = ServerMessage::PaneRowsUpdate {
        pane_id: "test".to_string(),
        rows: vec![],
        cursor: None,
        seq: 0,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_empty_terminal_snapshot() {
    // 0x0 terminal
    let snapshot = TerminalSnapshot {
        cells: vec![],
        cursor: CursorPosition { x: 0, y: 0 },
        cols: 0,
        rows: 0,
    };

    let mut snapshots = HashMap::new();
    snapshots.insert("empty".to_string(), snapshot);

    let msg = ServerMessage::PlaybackSnapshot {
        timestamp_ms: 0,
        snapshots,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_empty_snapshots_map() {
    let msg = ServerMessage::PlaybackSnapshot {
        timestamp_ms: 12345,
        snapshots: HashMap::new(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_large_terminal_snapshot() {
    // 4K terminal (240 cols x 67 rows = 16080 cells)
    let cols = 240;
    let rows = 67;
    let cell_count = cols * rows;

    let cells: Vec<TerminalCell> = (0..cell_count)
        .map(|i| TerminalCell {
            codepoint: (b'A' as u32) + ((i % 26) as u32),
            fg: ((i % 256) as u8, 128, 255),
            bg: (0, 0, (i % 128) as u8),
            flags: if i % 3 == 0 { STYLE_BOLD } else { 0 },
            width: if i % 50 == 0 { 2 } else { 1 },
        })
        .collect();

    let snapshot = TerminalSnapshot {
        cells,
        cursor: CursorPosition {
            x: (cols / 2) as u16,
            y: (rows / 2) as u16,
        },
        cols: cols as u16,
        rows: rows as u16,
    };

    let mut snapshots = HashMap::new();
    snapshots.insert("large".to_string(), snapshot.clone());

    let msg = ServerMessage::PlaybackSnapshot {
        timestamp_ms: 999999,
        snapshots,
    };
    let encoded = codec::encode(&msg).unwrap();
    assert!(encoded.len() > 100_000); // Should be substantial

    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    match decoded {
        ServerMessage::PlaybackSnapshot { snapshots, .. } => {
            let decoded_snapshot = snapshots.get("large").unwrap();
            assert_eq!(decoded_snapshot.cells.len(), cell_count);
            assert_eq!(decoded_snapshot.cols, cols as u16);
            assert_eq!(decoded_snapshot.rows, rows as u16);
        }
        _ => panic!("Wrong message type"),
    }
}

#[test]
fn test_unicode_strings() {
    // Various Unicode content
    let unicode_texts = vec![
        "Hello, 世界! 🌍",           // Mixed ASCII, CJK, emoji
        "日本語テキスト",            // Japanese
        "Привет мир",                // Cyrillic
        "مرحبا بالعالم",             // Arabic (RTL)
        "🚀🔥💻🎉",                  // Emoji only
        "\u{0000}\u{FFFF}\u{10000}", // Edge codepoints
        "café résumé naïve",         // Latin extended
        "∑∏∫∂∇",                     // Math symbols
    ];

    for text in unicode_texts {
        let msg = ClientMessage::InjectPrompt {
            pane_id: text.to_string(),
            prompt: text.to_string(),
        };
        let encoded = codec::encode(&msg).unwrap();
        let decoded: ClientMessage = codec::decode(&encoded).unwrap();
        assert_eq!(msg, decoded, "Unicode roundtrip failed for: {text}");
    }
}

#[test]
fn test_terminal_escape_sequences() {
    // Common terminal escape sequences
    let escape_data = vec![
        0x1b, 0x5b, 0x32, 0x4a, // Clear screen: ESC[2J
        0x1b, 0x5b, 0x31, 0x3b, 0x31, 0x48, // Move to 1,1: ESC[1;1H
        0x1b, 0x5b, 0x33, 0x31, 0x6d, // Red foreground: ESC[31m
        0x1b, 0x5b, 0x30, 0x6d, // Reset: ESC[0m
        0x07, // Bell
        0x08, // Backspace
        0x09, // Tab
        0x0a, // Newline
        0x0d, // Carriage return
    ];

    let msg = ClientMessage::SendInput {
        pane_id: "test".to_string(),
        data: escape_data.clone(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();

    match decoded {
        ClientMessage::SendInput { data, .. } => {
            assert_eq!(data, escape_data);
        }
        _ => panic!("Wrong message type"),
    }
}
