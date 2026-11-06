    #[test]
    fn test_worktree_crud() {
        let (_temp, store) = create_test_store();

        // Create worktree for an epic
        let worktree = Worktree::for_epic(
            Worktree::generate_id(),
            "cas-epic-1234".to_string(),
            "cas/cas-epic-1234".to_string(),
            "main".to_string(),
            std::path::PathBuf::from("/tmp/worktree"),
            Some("agent-123".to_string()),
        );

        store.add(&worktree).unwrap();

        // Read
        let fetched = store.get(&worktree.id).unwrap();
        assert_eq!(fetched.epic_id, Some("cas-epic-1234".to_string()));
        assert_eq!(fetched.branch, worktree.branch);

        // Update
        let mut updated = fetched;
        updated.status = WorktreeStatus::Merged;
        updated.merged_at = Some(Utc::now());
        store.update(&updated).unwrap();

        let refetched = store.get(&worktree.id).unwrap();
        assert_eq!(refetched.status, WorktreeStatus::Merged);

        // Delete
        store.delete(&worktree.id).unwrap();
        assert!(store.get(&worktree.id).is_err());
    }

    #[test]
    fn test_list_active() {
        let (_temp, store) = create_test_store();

        let wt1 = Worktree::for_epic(
            Worktree::generate_id(),
            "cas-epic-1".to_string(),
            "cas/cas-epic-1".to_string(),
            "main".to_string(),
            std::path::PathBuf::from("/tmp/wt1"),
            None,
        );
        let mut wt2 = Worktree::for_epic(
            Worktree::generate_id(),
            "cas-epic-2".to_string(),
            "cas/cas-epic-2".to_string(),
            "main".to_string(),
            std::path::PathBuf::from("/tmp/wt2"),
            None,
        );
        wt2.status = WorktreeStatus::Merged;

        store.add(&wt1).unwrap();
        store.add(&wt2).unwrap();

        let active = store.list_active().unwrap();
        assert_eq!(active.len(), 1);
        assert_eq!(active[0].id, wt1.id);
    }
