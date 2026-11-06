    #[test]
    fn test_parse_session_start_input() {
        let json = r#"{
            "session_id": "abc123",
            "cwd": "/test/dir",
            "hook_event_name": "SessionStart",
            "source": "startup"
        }"#;

        let input: HookInput = serde_json::from_str(json).unwrap();
        assert_eq!(input.session_id, "abc123");
        assert_eq!(input.hook_event_name, "SessionStart");
        assert_eq!(input.source, Some("startup".to_string()));
    }

    #[test]
    fn test_continue_field_name() {
        let output = HookOutput {
            continue_session: Some(false),
            stop_reason: Some("test".to_string()),
            ..Default::default()
        };
        let json = serde_json::to_string(&output).unwrap();
        assert!(
            json.contains("\"continue\""),
            "Expected 'continue' but got: {json}"
        );
        assert!(
            json.contains("\"stopReason\""),
            "Expected 'stopReason' but got: {json}"
        );
    }

    #[test]
    fn test_block_stop_output() {
        let output = HookOutput::block_stop("Continue working on remaining tasks".to_string());
        let json = serde_json::to_string(&output).unwrap();
        assert!(
            json.contains("\"decision\":\"block\""),
            "Expected decision:block but got: {json}"
        );
        assert!(
            json.contains("\"reason\":\"Continue working"),
            "Expected reason but got: {json}"
        );
    }
