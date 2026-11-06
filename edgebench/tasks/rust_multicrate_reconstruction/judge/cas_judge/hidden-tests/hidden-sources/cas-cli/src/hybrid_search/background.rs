    #[test]
    fn test_in_memory_indexer() {
        let indexer = BackgroundIndexer::in_memory().unwrap();
        assert!(indexer.is_operational());
    }

    #[test]
    fn test_process_empty_pending() {
        let indexer = BackgroundIndexer::in_memory().unwrap();
        let store = MockStore::new();

        let config = IndexingConfig::default();
        let result = indexer.process_pending(&store, &config).unwrap();

        assert_eq!(result.indexed, 0);
        assert!(result.errors.is_empty());
    }
