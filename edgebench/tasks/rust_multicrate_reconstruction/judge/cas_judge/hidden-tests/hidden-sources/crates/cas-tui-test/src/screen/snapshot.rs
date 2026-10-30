    #[test]
    fn test_frame_history() {
        let mut history = FrameHistory::new(3);

        for i in 0..5 {
            let buffer = make_buffer_with_text(&format!("Frame {i}"));
            history.push(Frame::new(buffer, vec![]));
        }

        // Should only keep last 3
        assert_eq!(history.len(), 3);
        let latest = history.latest().unwrap();
        assert!(latest.buffer.contains_text("Frame 4"));
    }

    #[test]
    fn test_snapshot_contains_text() {
        let buffer = make_buffer_with_text("Welcome to the application");
        let snapshot = Snapshot::from_buffer("test", &buffer);

        assert!(snapshot.contains_text("Welcome"));
        assert!(snapshot.contains_text("application"));
        assert!(!snapshot.contains_text("Goodbye"));
    }
