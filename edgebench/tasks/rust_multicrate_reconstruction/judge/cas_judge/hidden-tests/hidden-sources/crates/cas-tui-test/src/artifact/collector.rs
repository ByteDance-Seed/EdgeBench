    #[test]
    fn test_iso8601_now() {
        let ts = iso8601_now();
        // Should match pattern like "2026-01-31T10:30:00Z"
        assert!(ts.contains("T"));
        assert!(ts.ends_with("Z"));
        assert_eq!(ts.len(), 20);
    }

    #[test]
    fn test_max_pty_log_size() {
        let config = ArtifactConfig {
            max_pty_log_size: 10,
            ..Default::default()
        };
        let mut collector = ArtifactCollector::with_config("test", config);

        collector.record_pty_output(b"12345678901234567890"); // 20 bytes
        assert_eq!(collector.pty_log().len(), 10); // Capped at 10
    }
