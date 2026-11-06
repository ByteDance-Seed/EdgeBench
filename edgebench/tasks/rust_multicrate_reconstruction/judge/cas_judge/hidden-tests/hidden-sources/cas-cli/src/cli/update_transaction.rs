    #[test]
    fn test_transaction_commit() {
        let temp = TempDir::new().unwrap();
        let project_root = temp.path();
        let cas_dir = project_root.join(".cas");
        fs::create_dir_all(&cas_dir).unwrap();

        // Create a file to modify
        let test_file = project_root.join("test.txt");
        fs::write(&test_file, "original").unwrap();

        let mut tx = UpdateTransaction::new(project_root, &cas_dir);

        tx.add_file_change(FileChange::modify(
            PathBuf::from("test.txt"),
            "original".to_string(),
            "modified".to_string(),
            "test",
        ));

        tx.backup().unwrap();
        let backup_dir = tx.backup_dir().unwrap().to_path_buf();
        assert!(backup_dir.exists());

        tx.apply_file_changes().unwrap();
        tx.commit().unwrap();

        // Backup should be cleaned up
        assert!(!backup_dir.exists());
        assert_eq!(fs::read_to_string(&test_file).unwrap(), "modified");
    }

    #[test]
    fn test_automatic_rollback_on_drop() {
        let temp = TempDir::new().unwrap();
        let project_root = temp.path();
        let cas_dir = project_root.join(".cas");
        fs::create_dir_all(&cas_dir).unwrap();

        // Create a file to modify
        let test_file = project_root.join("test.txt");
        fs::write(&test_file, "original content").unwrap();

        // Scope block to test Drop behavior
        {
            let mut tx = UpdateTransaction::new(project_root, &cas_dir);

            tx.add_file_change(FileChange::modify(
                PathBuf::from("test.txt"),
                "original content".to_string(),
                "modified content".to_string(),
                "test",
            ));

            // Backup and apply changes
            tx.backup().unwrap();
            assert_eq!(tx.state(), TransactionState::BackedUp);
            tx.apply_file_changes().unwrap();

            // Verify file was modified
            assert_eq!(fs::read_to_string(&test_file).unwrap(), "modified content");

            // Drop tx here WITHOUT calling commit() or rollback()
            // The Drop impl should automatically rollback
        }

        // After Drop, file should be restored to original content
        assert_eq!(fs::read_to_string(&test_file).unwrap(), "original content");
    }
