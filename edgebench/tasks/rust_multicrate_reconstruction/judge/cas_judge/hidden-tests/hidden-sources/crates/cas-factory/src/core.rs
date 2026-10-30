    #[test]
    fn test_shutdown_nonexistent_worker_fails() {
        let config = test_config();
        let mut core = FactoryCore::new(config).unwrap();

        let result = core.shutdown_worker("nonexistent");
        assert!(matches!(result, Err(FactoryError::WorkerNotFound(_))));
    }

    #[test]
    fn test_poll_events_empty() {
        let config = test_config();
        let mut core = FactoryCore::new(config).unwrap();

        let events = core.poll_events();
        assert!(events.is_empty());
    }
