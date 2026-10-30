    #[tokio::test]
    async fn test_writer_keyframes() {
        let dir = TempDir::new().unwrap();
        let config = test_config(&dir);

        let mut writer = RecordingWriter::new(80, 24, "agent-1", "session-123", "worker", config)
            .await
            .unwrap();

        writer.write_output(b"before keyframe").await.unwrap();
        writer
            .write_keyframe(b"snapshot data here".to_vec())
            .await
            .unwrap();
        writer.write_output(b"after keyframe").await.unwrap();

        let stats = writer.close().await.unwrap();

        assert_eq!(stats.total_events, 3); // 2 outputs + 1 keyframe
        assert_eq!(stats.keyframe_count, 1);
    }
