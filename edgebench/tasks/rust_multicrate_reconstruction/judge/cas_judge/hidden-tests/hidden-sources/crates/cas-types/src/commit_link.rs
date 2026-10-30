    #[test]
    fn test_short_hash() {
        let link = CommitLink {
            commit_hash: "abc123def456789".to_string(),
            ..Default::default()
        };

        assert_eq!(link.short_hash(), "abc123d");
    }

    #[test]
    fn test_preview() {
        let link = CommitLink {
            message: "This is a very long commit message that should be truncated".to_string(),
            ..Default::default()
        };

        let preview = link.preview(20);
        assert!(preview.len() <= 20);
        assert!(preview.ends_with("..."));
    }

    #[test]
    fn test_includes_file() {
        let link = CommitLink {
            files_changed: vec!["src/main.rs".to_string(), "src/lib.rs".to_string()],
            ..Default::default()
        };

        assert!(link.includes_file("src/main.rs"));
        assert!(!link.includes_file("src/other.rs"));
    }
