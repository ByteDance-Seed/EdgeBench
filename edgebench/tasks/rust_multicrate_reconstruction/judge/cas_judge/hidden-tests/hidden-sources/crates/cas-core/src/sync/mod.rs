    #[test]
    fn test_list_all_synced() {
        let temp = TempDir::new().unwrap();
        let project_target = temp.path().join("project/.claude/rules/cas");
        let global_target = temp.path().join("global/.claude/rules/cas-global");

        let syncer =
            Syncer::new(project_target.clone(), 1).with_global_target(global_target.clone());

        // Create some files
        fs::create_dir_all(&project_target).unwrap();
        fs::create_dir_all(&global_target).unwrap();
        fs::write(project_target.join("p-rule-001.md"), "project rule").unwrap();
        fs::write(global_target.join("g-rule-001.md"), "global rule").unwrap();

        let (project_ids, global_ids) = syncer.list_all_synced().unwrap();

        assert_eq!(project_ids, vec!["p-rule-001".to_string()]);
        assert_eq!(global_ids, vec!["g-rule-001".to_string()]);
    }
