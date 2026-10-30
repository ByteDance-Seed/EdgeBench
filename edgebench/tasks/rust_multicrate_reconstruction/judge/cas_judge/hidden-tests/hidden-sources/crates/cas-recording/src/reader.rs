    #[tokio::test]
    async fn test_reader_iterates_events() {
        let dir = TempDir::new().unwrap();
        let path = create_test_recording(&dir).await;

        let reader = RecordingReader::open(&path).unwrap();
        let events: Vec<_> = reader.read_all_events().collect();

        // 5 events: Output, Output, Resize, Keyframe, Output
        assert_eq!(events.len(), 5);

        // Check first event
        match &events[0] {
            Ok(RecordingEvent::Output { data, .. }) => {
                assert_eq!(data, b"Hello, ");
            }
            _ => panic!("Expected Output event"),
        }

        // Check resize event (index 2)
        match &events[2] {
            Ok(RecordingEvent::Resize { cols, rows, .. }) => {
                assert_eq!(*cols, 120);
                assert_eq!(*rows, 40);
            }
            _ => panic!("Expected Resize event"),
        }

        // Check keyframe event (index 3)
        match &events[3] {
            Ok(RecordingEvent::Keyframe { .. }) => {}
            _ => panic!("Expected Keyframe event"),
        }

        // Check last output event (index 4)
        match &events[4] {
            Ok(RecordingEvent::Output { data, .. }) => {
                assert_eq!(data, b"After keyframe");
            }
            _ => panic!("Expected Output event after keyframe"),
        }
    }

    #[tokio::test]
    async fn test_reader_seek_to_keyframe() {
        let dir = TempDir::new().unwrap();
        let path = create_test_recording(&dir).await;

        let reader = RecordingReader::open(&path).unwrap();

        // Seek to a time after the keyframe should find the keyframe
        let position = reader.seek_to(50).unwrap();

        // Should be at or near the keyframe timestamp
        assert!(position.timestamp_ms <= 50 || reader.keyframe_count() == 0);
    }
