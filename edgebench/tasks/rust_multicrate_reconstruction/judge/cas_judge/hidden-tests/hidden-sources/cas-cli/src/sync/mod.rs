    #[test]
    fn test_sync_rule() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("claude/rules/cas");
        let syncer = Syncer::new(target.clone(), 1);

        let mut rule = Rule::new("rule-001".to_string(), "Test rule content".to_string());
        rule.helpful_count = 1;

        // Sync the rule
        assert!(syncer.sync_rule(&rule).unwrap());

        // Check file was created
        let filepath = target.join("rule-001.md");
        assert!(filepath.exists());

        let content = fs::read_to_string(&filepath).unwrap();
        assert!(content.contains("id: rule-001"));
        assert!(content.contains("Test rule content"));
    }

    #[test]
    fn test_sync_rule_with_scope() {
        let temp = TempDir::new().unwrap();
        let project_target = temp.path().join("project/.claude/rules/cas");
        let global_target = temp.path().join("global/.claude/rules/cas-global");

        let syncer =
            Syncer::new(project_target.clone(), 1).with_global_target(global_target.clone());

        // Test global rule goes to global target
        let mut global_rule = Rule::new("g-rule-001".to_string(), "Global rule".to_string());
        global_rule.helpful_count = 1;
        global_rule.scope = Scope::Global;
        assert!(syncer.sync_rule_with_scope(&global_rule).unwrap());
        assert!(global_target.join("g-rule-001.md").exists());

        // Test project rule goes to project target
        let mut project_rule = Rule::new("p-rule-001".to_string(), "Project rule".to_string());
        project_rule.helpful_count = 1;
        project_rule.scope = Scope::Project;
        assert!(syncer.sync_rule_with_scope(&project_rule).unwrap());
        assert!(project_target.join("p-rule-001.md").exists());

        // Check content includes scope indicator
        let content = fs::read_to_string(global_target.join("g-rule-001.md")).unwrap();
        assert!(content.contains("scope: global"));

        let content = fs::read_to_string(project_target.join("p-rule-001.md")).unwrap();
        assert!(content.contains("scope: project"));
    }
