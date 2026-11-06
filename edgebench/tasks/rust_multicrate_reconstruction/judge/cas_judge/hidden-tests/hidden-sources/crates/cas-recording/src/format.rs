    #[test]
    fn test_event_timestamps() {
        let output = RecordingEvent::output(100, vec![b'h', b'e', b'l', b'l', b'o']);
        assert_eq!(output.timestamp_ms(), 100);

        let resize = RecordingEvent::resize(200, 120, 40);
        assert_eq!(resize.timestamp_ms(), 200);

        let keyframe = RecordingEvent::keyframe(300, 1024, 512);
        assert_eq!(keyframe.timestamp_ms(), 300);
    }
