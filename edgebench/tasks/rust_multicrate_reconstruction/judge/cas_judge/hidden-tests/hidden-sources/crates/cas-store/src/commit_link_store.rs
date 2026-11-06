    #[test]
    fn test_add_and_get() {
        let (store, _dir) = setup_store();

        let link = create_test_link("abc123def456", "session-1", "main");
        store.add(&link).unwrap();

        let retrieved = store.get("abc123def456").unwrap();
        assert!(retrieved.is_some());
        let retrieved = retrieved.unwrap();
        assert_eq!(retrieved.commit_hash, "abc123def456");
        assert_eq!(retrieved.branch, "main");
        assert_eq!(retrieved.files_changed.len(), 2);
        assert_eq!(retrieved.prompt_ids.len(), 1);
    }

    #[test]
    fn test_list_by_session() {
        let (store, _dir) = setup_store();

        store
            .add(&create_test_link("commit-1", "session-A", "main"))
            .unwrap();
        store
            .add(&create_test_link("commit-2", "session-A", "main"))
            .unwrap();
        store
            .add(&create_test_link("commit-3", "session-B", "main"))
            .unwrap();

        let session_a = store.list_by_session("session-A", 10).unwrap();
        assert_eq!(session_a.len(), 2);

        let session_b = store.list_by_session("session-B", 10).unwrap();
        assert_eq!(session_b.len(), 1);
    }

    #[test]
    fn test_list_by_branch() {
        let (store, _dir) = setup_store();

        store
            .add(&create_test_link("commit-1", "session-1", "main"))
            .unwrap();
        store
            .add(&create_test_link("commit-2", "session-1", "feature"))
            .unwrap();
        store
            .add(&create_test_link("commit-3", "session-1", "main"))
            .unwrap();

        let main_commits = store.list_by_branch("main", 10).unwrap();
        assert_eq!(main_commits.len(), 2);

        let feature_commits = store.list_by_branch("feature", 10).unwrap();
        assert_eq!(feature_commits.len(), 1);
    }
