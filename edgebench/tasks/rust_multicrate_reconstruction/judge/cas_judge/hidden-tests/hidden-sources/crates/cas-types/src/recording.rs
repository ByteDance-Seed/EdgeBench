    #[test]
    fn test_recording_end() {
        let mut rec = Recording::new("/path/to/recording.bin".to_string());
        rec.end();

        assert!(rec.ended_at.is_some());
        assert!(rec.duration_ms.is_some());
        assert!(rec.duration_ms.unwrap() >= 0);
    }
