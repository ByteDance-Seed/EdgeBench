    #[test]
    fn test_delete_for_recording() {
        let (store, _dir) = setup_store();

        store
            .index_text("session-to-delete", "agent", 1000, "some content")
            .unwrap();

        store
            .index_text("session-to-keep", "agent", 1000, "other content")
            .unwrap();

        let deleted = store.delete_for_recording("session-to-delete").unwrap();
        assert_eq!(deleted, 1);

        let entries = store.list_for_recording("session-to-delete").unwrap();
        assert!(entries.is_empty());

        let entries = store.list_for_recording("session-to-keep").unwrap();
        assert_eq!(entries.len(), 1);
    }
