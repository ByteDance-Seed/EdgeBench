use crate::*;

#[test]
fn test_empty_string_fields() {
    // Empty pane_id
    let msg = ClientMessage::Focus {
        pane_id: String::new(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);

    // Empty prompt
    let msg = ClientMessage::InjectPrompt {
        pane_id: "test".to_string(),
        prompt: String::new(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);

    // Empty recording path
    let msg = ClientMessage::PlaybackLoad {
        recording_path: String::new(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}




// =============================================================================
// Edge Cases - Large Payloads
// =============================================================================

#[test]
fn test_large_terminal_data() {
    // 1MB of terminal output data
    let large_data: Vec<u8> = (0..=255).cycle().take(1024 * 1024).collect();

    let msg = ClientMessage::SendInput {
        pane_id: "test".to_string(),
        data: large_data.clone(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();

    match decoded {
        ClientMessage::SendInput { data, .. } => {
            assert_eq!(data.len(), large_data.len());
            assert_eq!(data, large_data);
        }
        _ => panic!("Wrong message type"),
    }
}


#[test]
fn test_large_prompt_text() {
    // 100KB prompt
    let large_prompt: String = "x".repeat(100 * 1024);

    let msg = ClientMessage::InjectPrompt {
        pane_id: "worker-1".to_string(),
        prompt: large_prompt.clone(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();

    match decoded {
        ClientMessage::InjectPrompt { prompt, .. } => {
            assert_eq!(prompt.len(), large_prompt.len());
        }
        _ => panic!("Wrong message type"),
    }
}

#[test]
fn test_many_worker_names() {
    // 100 worker names
    let names: Vec<String> = (0..100).map(|i| format!("worker-{i}")).collect();

    let msg = ClientMessage::SpawnWorkers {
        count: 100,
        names: names.clone(),
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();

    match decoded {
        ClientMessage::SpawnWorkers {
            count,
            names: decoded_names,
        } => {
            assert_eq!(count, 100);
            assert_eq!(decoded_names, names);
        }
        _ => panic!("Wrong message type"),
    }
}

// =============================================================================
// Edge Cases - Unicode and Special Characters
// =============================================================================



#[test]
fn test_unicode_codepoints_in_cells() {
    // Test wide characters and emoji in terminal cells
    let cells = vec![
        TerminalCell {
            codepoint: 0x4E2D, // 中
            fg: (255, 255, 255),
            bg: (0, 0, 0),
            flags: 0,
            width: 2, // Wide character
        },
        TerminalCell {
            codepoint: 0x1F600, // 😀
            fg: (255, 255, 255),
            bg: (0, 0, 0),
            flags: 0,
            width: 2, // Emoji
        },
        TerminalCell {
            codepoint: 0, // Empty/space
            fg: (255, 255, 255),
            bg: (0, 0, 0),
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
    snapshots.insert("unicode".to_string(), snapshot);

    let msg = ServerMessage::PlaybackSnapshot {
        timestamp_ms: 0,
        snapshots,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

// =============================================================================
