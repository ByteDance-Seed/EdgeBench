    #[test]
    fn test_clear() {
        let (_temp, store) = create_test_store();

        store
            .notify("supervisor-1", "event1", "{}", NotificationPriority::Normal)
            .unwrap();
        store
            .notify("supervisor-1", "event2", "{}", NotificationPriority::Normal)
            .unwrap();
        store
            .notify("supervisor-2", "event3", "{}", NotificationPriority::Normal)
            .unwrap();

        // Clear supervisor-1's notifications
        let cleared = store.clear("supervisor-1").unwrap();
        assert_eq!(cleared, 2);

        // supervisor-1 should have no pending
        let count = store.pending_count("supervisor-1").unwrap();
        assert_eq!(count, 0);

        // supervisor-2 should still have 1
        let count = store.pending_count("supervisor-2").unwrap();
        assert_eq!(count, 1);
    }
