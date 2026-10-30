    #[test]
    fn test_dedup_result_methods() {
        let result = DedupResult {
            action: DedupAction::Add,
            similar: None,
        };
        assert!(result.should_add());
        assert!(!result.should_skip());
        assert!(!result.should_merge());

        let result = DedupResult {
            action: DedupAction::Skip,
            similar: None,
        };
        assert!(!result.should_add());
        assert!(result.should_skip());
        assert!(!result.should_merge());

        let result = DedupResult {
            action: DedupAction::Merge,
            similar: None,
        };
        assert!(!result.should_add());
        assert!(!result.should_skip());
        assert!(result.should_merge());
    }
