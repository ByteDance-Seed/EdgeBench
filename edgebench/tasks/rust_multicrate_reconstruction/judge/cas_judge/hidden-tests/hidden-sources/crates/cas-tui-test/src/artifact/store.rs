    #[test]
    fn test_mismatch_snapshot() {
        let temp_dir = TempDir::new().unwrap();
        let config = SnapshotStoreConfig::default().with_dir(temp_dir.path());
        let store = SnapshotStore::with_config("test_mismatch", config);

        let buffer1 = make_buffer_with_text("Original");
        let buffer2 = make_buffer_with_text("Changed");

        // Create with original
        store.assert_snapshot("main", &buffer1).unwrap();

        // Should fail with changed
        let err = store.assert_snapshot("main", &buffer2).unwrap_err();
        assert!(matches!(err, SnapshotError::Mismatch { .. }));
    }

    #[test]
    fn test_update_mode() {
        let temp_dir = TempDir::new().unwrap();
        let config = SnapshotStoreConfig::default()
            .with_dir(temp_dir.path())
            .with_update_mode(true);
        let store = SnapshotStore::with_config("test_update", config);

        let buffer1 = make_buffer_with_text("Original");
        let buffer2 = make_buffer_with_text("Updated");

        // Create snapshot
        store.assert_snapshot("main", &buffer1).unwrap();

        // Update should succeed even with different content
        let result = store.assert_snapshot("main", &buffer2).unwrap();
        assert_eq!(result, SnapshotResult::Updated);

        // Verify the snapshot was updated
        let snapshot = Snapshot::load(store.snapshot_path("main")).unwrap();
        assert!(snapshot.contains_text("Updated"));
    }
