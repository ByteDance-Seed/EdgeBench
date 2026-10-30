    #[test]
    fn preserves_previous_changes_when_git_refresh_not_due() {
        let previous = data_with_changes(
            true,
            vec![SourceChangesInfo {
                source_name: "main".to_string(),
                source_path: std::path::PathBuf::from("."),
                agent_name: None,
                changes: vec![FileChangeInfo {
                    file_path: "src/main.rs".to_string(),
                    lines_added: 3,
                    lines_removed: 1,
                    status: GitFileStatus::Modified,
                    staged: false,
                }],
                total_added: 3,
                total_removed: 1,
            }],
        );
        let loaded_without_git = data_with_changes(false, Vec::new());

        let merged = merge_director_data_preserving_git(&previous, loaded_without_git, false);

        assert!(merged.git_loaded);
        assert_eq!(merged.changes.len(), 1);
        assert_eq!(merged.changes[0].source_name, "main");
    }

    #[test]
    fn keeps_loaded_changes_when_git_refresh_is_due() {
        let previous = data_with_changes(true, Vec::new());
        let loaded_with_git = data_with_changes(
            true,
            vec![SourceChangesInfo {
                source_name: "worker-1".to_string(),
                source_path: std::path::PathBuf::from("."),
                agent_name: Some("worker-1".to_string()),
                changes: vec![FileChangeInfo {
                    file_path: "README.md".to_string(),
                    lines_added: 10,
                    lines_removed: 0,
                    status: GitFileStatus::Added,
                    staged: false,
                }],
                total_added: 10,
                total_removed: 0,
            }],
        );

        let merged = merge_director_data_preserving_git(&previous, loaded_with_git, true);

        assert!(merged.git_loaded);
        assert_eq!(merged.changes.len(), 1);
        assert_eq!(merged.changes[0].source_name, "worker-1");
    }
