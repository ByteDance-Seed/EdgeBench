    #[test]
    fn test_worker_guidance_loads() {
        let guide = worker_guidance();
        assert!(guide.contains("Worker"));
        assert!(!guide.contains("managed_by:"));
        // Verify preloaded skills are included
        assert!(
            guide.contains("CAS Task Tracking"),
            "should include task-tracking skill"
        );
        assert!(
            guide.contains("CAS Memory Management"),
            "should include memory skill"
        );
        assert!(guide.contains("CAS Search"), "should include search skill");
        // Worker should NOT have supervisor checklist
        assert!(
            !guide.contains("Supervisor Checklist"),
            "should not include supervisor checklist"
        );
    }

    #[test]
    fn test_is_managed_by_cas() {
        let managed = "---\nname: test\nmanaged_by: cas\n---\nContent";
        assert!(is_managed_by_cas(managed));

        let not_managed = "---\nname: test\n---\nContent";
        assert!(!is_managed_by_cas(not_managed));

        let no_frontmatter = "# Just content";
        assert!(!is_managed_by_cas(no_frontmatter));
    }
