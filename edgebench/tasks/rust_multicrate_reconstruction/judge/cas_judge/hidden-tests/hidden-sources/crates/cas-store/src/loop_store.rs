    #[test]
    fn test_delete_loop() {
        let (store, _dir) = create_test_store();

        let loop_state = Loop::new(
            "loop-test".to_string(),
            "session-123".to_string(),
            "Build something".to_string(),
            "/project".to_string(),
        );

        store.add(&loop_state).unwrap();
        store.delete("loop-test").unwrap();

        let result = store.get("loop-test");
        assert!(result.is_err());
    }

    #[test]
    fn test_loop_with_options() {
        let (store, _dir) = create_test_store();

        let loop_state = Loop::with_options(
            "loop-test".to_string(),
            "session-123".to_string(),
            "Build something".to_string(),
            "/project".to_string(),
            Some("DONE".to_string()),
            10,
            Some("cas-task-1".to_string()),
        );

        store.add(&loop_state).unwrap();

        let retrieved = store.get("loop-test").unwrap();
        assert_eq!(retrieved.completion_promise, Some("DONE".to_string()));
        assert_eq!(retrieved.max_iterations, 10);
        assert_eq!(retrieved.task_id, Some("cas-task-1".to_string()));
    }
