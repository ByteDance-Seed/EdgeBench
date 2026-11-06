    #[test]
    fn test_wait_for_regex_invalid() {
        let mut runner = PtyRunner::new();
        runner.spawn("echo", &["test"]).expect("spawn failed");

        let config = WaitConfig::with_timeout_ms(100);
        let result = wait_for_regex(&mut runner, r"[invalid", &config);
        assert!(matches!(result, Err(WaitError::InvalidPattern(_))));
    }
