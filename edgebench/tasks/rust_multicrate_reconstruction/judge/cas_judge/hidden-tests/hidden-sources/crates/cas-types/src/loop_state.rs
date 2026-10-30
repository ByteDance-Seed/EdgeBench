    #[test]
    fn test_loop_status() {
        assert_eq!(LoopStatus::from_str("active").unwrap(), LoopStatus::Active);
        assert_eq!(
            LoopStatus::from_str("completed").unwrap(),
            LoopStatus::Completed
        );
        assert_eq!(
            LoopStatus::from_str("cancelled").unwrap(),
            LoopStatus::Cancelled
        );
    }

    #[test]
    fn test_complete_loop() {
        let mut loop_state = Loop::new(
            "loop-a1b2".to_string(),
            "session-123".to_string(),
            "prompt".to_string(),
            "/project".to_string(),
        );

        loop_state.complete("Promise detected");
        assert_eq!(loop_state.status, LoopStatus::Completed);
        assert!(loop_state.ended_at.is_some());
        assert_eq!(loop_state.end_reason, Some("Promise detected".to_string()));
    }

    #[test]
    fn test_loop_status_display() {
        assert_eq!(LoopStatus::Active.to_string(), "active");
        assert_eq!(LoopStatus::Completed.to_string(), "completed");
        assert_eq!(LoopStatus::MaxIterations.to_string(), "max_iterations");
    }
