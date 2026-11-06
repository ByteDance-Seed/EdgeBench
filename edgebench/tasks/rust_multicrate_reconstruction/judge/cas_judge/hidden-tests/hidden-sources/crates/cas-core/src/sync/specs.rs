    #[test]
    fn test_is_approved() {
        let syncer = SpecSyncer::new(PathBuf::from("/tmp/test"));

        let approved = create_test_spec("spec-001", "Approved Spec", true);
        let draft = create_test_spec("spec-002", "Draft Spec", false);

        assert!(syncer.is_approved(&approved));
        assert!(!syncer.is_approved(&draft));
    }

    #[test]
    fn test_sync_spec() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("specs");
        let syncer = SpecSyncer::new(target.clone());

        let spec = create_test_spec("spec-001", "Test Spec", true);

        // Sync the spec
        assert!(syncer.sync_spec(&spec).unwrap());

        // Check file was created
        let filepath = target.join("spec-001.md");
        assert!(filepath.exists());

        let content = fs::read_to_string(&filepath).unwrap();
        assert!(content.contains("id: spec-001"));
        assert!(content.contains("title: Test Spec"));
        assert!(content.contains("status: approved"));
    }

    #[test]
    fn test_generate_spec_md_frontmatter() {
        let syncer = SpecSyncer::new(PathBuf::from("/tmp/test"));

        let mut spec = create_test_spec("spec-001", "Test Spec", true);
        spec.task_id = Some("task-123".to_string());
        spec.version = 2;

        let content = syncer.generate_spec_md(&spec);

        assert!(content.starts_with("---\n"));
        assert!(content.contains("id: spec-001\n"));
        assert!(content.contains("title: Test Spec\n"));
        assert!(content.contains("spec_type: epic\n"));
        assert!(content.contains("status: approved\n"));
        assert!(content.contains("version: 2\n"));
        assert!(content.contains("task_id: task-123\n"));
        assert!(content.contains("approved_at:"));
        assert!(content.contains("approved_by: test-user\n"));
    }

    #[test]
    fn test_draft_spec_not_synced() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("specs");
        let syncer = SpecSyncer::new(target.clone());

        let draft = create_test_spec("spec-001", "Draft Spec", false);

        // Should not sync
        assert!(!syncer.sync_spec(&draft).unwrap());
        assert!(!target.join("spec-001.md").exists());
    }
