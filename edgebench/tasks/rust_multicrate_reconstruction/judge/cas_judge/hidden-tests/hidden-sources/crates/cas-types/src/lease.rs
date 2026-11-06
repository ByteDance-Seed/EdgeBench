    #[test]
    fn test_lease_with_reason() {
        let lease = TaskLease::with_reason(
            "task-1".to_string(),
            "agent-1".to_string(),
            600,
            "Working on feature X".to_string(),
        );
        assert_eq!(lease.claim_reason, Some("Working on feature X".to_string()));
    }
