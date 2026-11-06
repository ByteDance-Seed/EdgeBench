    #[test]
    fn test_list_for_entity() {
        let (store, _dir) = setup_store();

        store
            .record(&Event::new(
                EventType::TaskStarted,
                EventEntityType::Task,
                "cas-abc",
                "Started",
            ))
            .unwrap();

        store
            .record(&Event::new(
                EventType::TaskCompleted,
                EventEntityType::Task,
                "cas-abc",
                "Completed",
            ))
            .unwrap();

        store
            .record(&Event::new(
                EventType::TaskStarted,
                EventEntityType::Task,
                "cas-def",
                "Started another",
            ))
            .unwrap();

        let events = store
            .list_for_entity(EventEntityType::Task, "cas-abc", 10)
            .unwrap();
        assert_eq!(events.len(), 2);
    }

    #[test]
    fn test_count_by_type() {
        let (store, _dir) = setup_store();

        for _ in 0..3 {
            store
                .record(&Event::new(
                    EventType::TaskStarted,
                    EventEntityType::Task,
                    "task",
                    "Started",
                ))
                .unwrap();
        }

        for _ in 0..2 {
            store
                .record(&Event::new(
                    EventType::MemoryStored,
                    EventEntityType::Entry,
                    "entry",
                    "Stored",
                ))
                .unwrap();
        }

        let counts = store.count_by_type().unwrap();

        let task_count = counts.iter().find(|(t, _)| *t == EventType::TaskStarted);
        assert_eq!(task_count.map(|(_, c)| *c), Some(3));

        let memory_count = counts.iter().find(|(t, _)| *t == EventType::MemoryStored);
        assert_eq!(memory_count.map(|(_, c)| *c), Some(2));
    }

    #[test]
    fn test_list_by_session() {
        let (store, _dir) = setup_store();

        // Create events with different session IDs
        let mut event1 = Event::new(
            EventType::TaskStarted,
            EventEntityType::Task,
            "cas-1",
            "Started task 1",
        );
        event1.session_id = Some("session-abc".to_string());
        store.record(&event1).unwrap();

        let mut event2 = Event::new(
            EventType::TaskCompleted,
            EventEntityType::Task,
            "cas-1",
            "Completed task 1",
        );
        event2.session_id = Some("session-abc".to_string());
        store.record(&event2).unwrap();

        let mut event3 = Event::new(
            EventType::TaskStarted,
            EventEntityType::Task,
            "cas-2",
            "Started task 2",
        );
        event3.session_id = Some("session-xyz".to_string());
        store.record(&event3).unwrap();

        // Query by session ID
        let abc_events = store.list_by_session("session-abc", 10).unwrap();
        assert_eq!(abc_events.len(), 2);
        assert!(
            abc_events
                .iter()
                .all(|e| e.session_id == Some("session-abc".to_string()))
        );

        let xyz_events = store.list_by_session("session-xyz", 10).unwrap();
        assert_eq!(xyz_events.len(), 1);
        assert_eq!(xyz_events[0].entity_id, "cas-2");

        // Query non-existent session
        let empty_events = store.list_by_session("session-nonexistent", 10).unwrap();
        assert!(empty_events.is_empty());
    }
