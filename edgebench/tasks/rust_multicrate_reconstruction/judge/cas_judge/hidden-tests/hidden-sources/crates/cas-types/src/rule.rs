    #[test]
    fn test_rule_status_from_str() {
        assert_eq!(RuleStatus::from_str("draft").unwrap(), RuleStatus::Draft);
        assert_eq!(RuleStatus::from_str("PROVEN").unwrap(), RuleStatus::Proven);
        assert_eq!(RuleStatus::from_str("Stale").unwrap(), RuleStatus::Stale);
        assert_eq!(
            RuleStatus::from_str("retired").unwrap(),
            RuleStatus::Retired
        );
        assert!(RuleStatus::from_str("invalid").is_err());
    }
