    #[test]
    fn test_prompt_creation() {
        let prompt = Prompt::new(
            "prompt-abc123".to_string(),
            "session-xyz".to_string(),
            "agent-1".to_string(),
            "Add a login button to the header".to_string(),
        );

        assert_eq!(prompt.id, "prompt-abc123");
        assert_eq!(prompt.session_id, "session-xyz");
        assert_eq!(prompt.agent_id, "agent-1");
        assert!(!prompt.content_hash.is_empty());
        assert_eq!(prompt.scope, Scope::Project);
    }
