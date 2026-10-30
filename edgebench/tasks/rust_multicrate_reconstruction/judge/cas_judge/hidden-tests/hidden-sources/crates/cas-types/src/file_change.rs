    #[test]
    fn test_link_commit() {
        let mut fc = FileChange::new(
            "fc-test".to_string(),
            "session-1".to_string(),
            "agent-1".to_string(),
            "repo".to_string(),
            "file.rs".to_string(),
            ChangeType::Created,
            "Write".to_string(),
            "hash123".to_string(),
        );

        assert!(fc.commit_hash.is_none());
        assert!(fc.committed_at.is_none());

        fc.link_commit("abc123def".to_string());

        assert_eq!(fc.commit_hash, Some("abc123def".to_string()));
        assert!(fc.committed_at.is_some());
    }
