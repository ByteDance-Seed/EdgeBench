    #[test]
    fn test_worktree_for_epic() {
        let wt = Worktree::for_epic(
            "wt-12345678".to_string(),
            "cas-epic-1234".to_string(),
            "cas/cas-epic-1234".to_string(),
            "main".to_string(),
            PathBuf::from("/tmp/worktree"),
            Some("agent-123".to_string()),
        );

        assert_eq!(wt.epic_id, Some("cas-epic-1234".to_string()));
        assert_eq!(wt.created_by_agent, Some("agent-123".to_string()));
    }
