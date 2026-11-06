#[test]
fn test_frame_length_accuracy() {
    // Test various payload sizes
    let sizes = vec![0, 1, 127, 128, 255, 256, 1024, 65535, 65536, 100_000];

    for size in sizes {
        let data: Vec<u8> = (0..size).map(|i| (i % 256) as u8).collect();
        let msg = ClientMessage::SendInput {
            pane_id: "test".to_string(),
            data,
        };

        let framed = codec::encode_framed(&msg).unwrap();
        let header: [u8; 4] = framed[..4].try_into().unwrap();
        let reported_len = codec::read_frame_length(&header);
        let actual_len = framed.len() - codec::FRAME_HEADER_SIZE;

        assert_eq!(
            reported_len, actual_len,
            "Frame length mismatch for payload size {size}"
        );
    }
}

#[test]
fn test_pane_rows_update_with_styles() {
    let msg = ServerMessage::PaneRowsUpdate {
        pane_id: "supervisor".to_string(),
        rows: vec![
            RowData {
                row: 0,
                runs: vec![
                    StyleRun::new("$ "),
                    StyleRun::with_style("cargo", (0, 255, 0), (0, 0, 0), STYLE_BOLD),
                    StyleRun::new(" build"),
                ],
            },
            RowData {
                row: 1,
                runs: vec![StyleRun::with_style(
                    "   Compiling cas-factory-protocol v0.1.0",
                    (128, 128, 128),
                    (0, 0, 0),
                    0,
                )],
            },
            RowData {
                row: 2,
                runs: vec![StyleRun::with_style(
                    "error[E0599]: no variant named `InvalidVariant`",
                    (255, 0, 0),
                    (0, 0, 0),
                    STYLE_BOLD,
                )],
            },
        ],
        cursor: Some(CursorPosition { x: 0, y: 3 }),
        seq: 42,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_pane_rows_update_incremental() {
    // Test that only dirty rows need to be sent
    let msg = ServerMessage::PaneRowsUpdate {
        pane_id: "worker-1".to_string(),
        rows: vec![RowData {
            row: 5, // Only row 5 changed
            runs: vec![StyleRun::new("Updated content on row 5")],
        }],
        cursor: None, // Cursor didn't change
        seq: 100,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}
