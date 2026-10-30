    #[test]
    fn test_create_event_reminder() {
        let (_temp, store) = create_test_store();

        let filter = serde_json::json!({"task_id": "cas-a1b2"});
        let id = store
            .create(
                "supervisor-1",
                None,
                "Review task output",
                ReminderTriggerType::Event,
                None,
                Some("task_completed"),
                Some(&filter),
                3600,
            )
            .unwrap();

        assert!(id > 0);

        let pending = store.list_pending("supervisor-1").unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].trigger_event.as_deref(), Some("task_completed"));
        assert_eq!(
            pending[0].trigger_filter,
            Some(serde_json::json!({"task_id": "cas-a1b2"}))
        );
    }

    #[test]
    fn test_get_event_reminders() {
        let (_temp, store) = create_test_store();

        store
            .create(
                "supervisor-1",
                None,
                "On task complete",
                ReminderTriggerType::Event,
                None,
                Some("task_completed"),
                None,
                3600,
            )
            .unwrap();

        store
            .create(
                "supervisor-1",
                None,
                "On worker idle",
                ReminderTriggerType::Event,
                None,
                Some("worker_idle"),
                None,
                3600,
            )
            .unwrap();

        let reminders = store.get_event_reminders("task_completed").unwrap();
        assert_eq!(reminders.len(), 1);
        assert_eq!(reminders[0].message, "On task complete");

        let reminders = store.get_event_reminders("worker_idle").unwrap();
        assert_eq!(reminders.len(), 1);
        assert_eq!(reminders[0].message, "On worker idle");

        let reminders = store.get_event_reminders("epic_completed").unwrap();
        assert!(reminders.is_empty());
    }

    #[test]
    fn test_cancel() {
        let (_temp, store) = create_test_store();

        let id = store
            .create(
                "supervisor-1",
                None,
                "Cancel me",
                ReminderTriggerType::Event,
                None,
                Some("task_completed"),
                None,
                3600,
            )
            .unwrap();

        // Cancel by wrong owner should fail
        assert!(store.cancel(id, "supervisor-2").is_err());

        // Cancel by correct owner should succeed
        store.cancel(id, "supervisor-1").unwrap();

        let pending = store.list_pending("supervisor-1").unwrap();
        assert!(pending.is_empty());

        // Double-cancel should fail
        assert!(store.cancel(id, "supervisor-1").is_err());
    }
