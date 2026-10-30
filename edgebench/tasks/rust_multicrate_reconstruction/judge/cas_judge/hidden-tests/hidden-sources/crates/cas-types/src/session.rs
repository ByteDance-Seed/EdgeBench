    #[test]
    fn test_compute_outcome_tasks_completed() {
        let mut session = Session::default();
        session.increment_tasks();
        session.increment_entries(); // Also has entries, but tasks take priority
        session.compute_outcome();

        assert_eq!(session.outcome, Some(SessionOutcome::TasksCompleted));
    }

    #[test]
    fn test_compute_outcome_learnings_created() {
        let mut session = Session::default();
        session.increment_entries();
        session.increment_tool_uses();
        session.compute_outcome();

        assert_eq!(session.outcome, Some(SessionOutcome::LearningsCreated));
    }
