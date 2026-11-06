    #[test]
    fn test_add_and_get() {
        let (store, _dir) = setup_store();

        let prompt = Prompt::new(
            "prompt-abc123".to_string(),
            "session-xyz".to_string(),
            "agent-1".to_string(),
            "Add a login button".to_string(),
        );

        store.add(&prompt).unwrap();

        let retrieved = store.get("prompt-abc123").unwrap();
        assert!(retrieved.is_some());
        let retrieved = retrieved.unwrap();
        assert_eq!(retrieved.id, "prompt-abc123");
        assert_eq!(retrieved.session_id, "session-xyz");
        assert_eq!(retrieved.content, "Add a login button");
    }

    #[test]
    fn test_list_by_session() {
        let (store, _dir) = setup_store();

        // Add prompts for different sessions
        store
            .add(&Prompt::new(
                "prompt-1".to_string(),
                "session-A".to_string(),
                "agent-1".to_string(),
                "First prompt".to_string(),
            ))
            .unwrap();

        store
            .add(&Prompt::new(
                "prompt-2".to_string(),
                "session-A".to_string(),
                "agent-1".to_string(),
                "Second prompt".to_string(),
            ))
            .unwrap();

        store
            .add(&Prompt::new(
                "prompt-3".to_string(),
                "session-B".to_string(),
                "agent-1".to_string(),
                "Other session prompt".to_string(),
            ))
            .unwrap();

        let session_a_prompts = store.list_by_session("session-A", 10).unwrap();
        assert_eq!(session_a_prompts.len(), 2);

        let session_b_prompts = store.list_by_session("session-B", 10).unwrap();
        assert_eq!(session_b_prompts.len(), 1);
    }

    #[test]
    fn test_duplicate_hash_same_session_updates() {
        let (store, _dir) = setup_store();

        let prompt1 = Prompt::new(
            "prompt-1".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "Same content".to_string(),
        );

        let prompt2 = Prompt::new(
            "prompt-2".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "Same content".to_string(),
        );

        store.add(&prompt1).unwrap();
        // INSERT OR REPLACE means second insert with same hash+session replaces
        store.add(&prompt2).unwrap();

        // Should have latest prompt
        let prompts = store.list_by_session("session-1", 10).unwrap();
        assert_eq!(prompts.len(), 1);
        assert_eq!(prompts[0].id, "prompt-2");
    }

    #[test]
    fn test_update_blame_fields() {
        let (store, _dir) = setup_store();

        // Add a prompt
        let prompt = Prompt::new(
            "prompt-1".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "Test prompt".to_string(),
        );
        store.add(&prompt).unwrap();

        // Initially no messages
        let retrieved = store.get("prompt-1").unwrap().unwrap();
        assert!(retrieved.messages.is_empty());
        assert!(retrieved.model.is_none());
        assert!(retrieved.tool_version.is_none());

        // Update with messages
        let messages = vec![
            Message {
                role: cas_types::MessageRole::User,
                content: "Hello".to_string(),
                tool_name: None,
                tool_input: None,
                timestamp: chrono::Utc::now(),
            },
            Message {
                role: cas_types::MessageRole::Assistant,
                content: "Hi there!".to_string(),
                tool_name: None,
                tool_input: None,
                timestamp: chrono::Utc::now(),
            },
        ];

        store
            .update_blame_fields(
                "prompt-1",
                &messages,
                Some("claude-opus-4-5"),
                Some("1.0.0"),
            )
            .unwrap();

        // Verify update
        let updated = store.get("prompt-1").unwrap().unwrap();
        assert_eq!(updated.messages.len(), 2);
        assert_eq!(updated.messages[0].content, "Hello");
        assert_eq!(updated.messages[1].content, "Hi there!");
        assert_eq!(updated.model, Some("claude-opus-4-5".to_string()));
        assert_eq!(updated.tool_version, Some("1.0.0".to_string()));
    }
