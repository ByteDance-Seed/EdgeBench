    #[test]
    fn test_event_type_from_str() {
        assert_eq!(
            EventType::from_str("agent_registered").unwrap(),
            EventType::AgentRegistered
        );
        assert_eq!(
            EventType::from_str("TASK_STARTED").unwrap(),
            EventType::TaskStarted
        );
    }

    #[test]
    fn test_event_new() {
        let event = Event::new(
            EventType::TaskStarted,
            EventEntityType::Task,
            "cas-abc1",
            "Task started: Fix the bug",
        );
        assert_eq!(event.event_type, EventType::TaskStarted);
        assert_eq!(event.entity_id, "cas-abc1");
        assert_eq!(event.icon(), "◔");
    }
