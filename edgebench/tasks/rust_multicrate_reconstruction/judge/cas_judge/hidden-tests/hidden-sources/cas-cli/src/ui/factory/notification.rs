    #[test]
    fn test_notifier_disabled_by_default() {
        let notifier = Notifier::new(NotifyConfig::default());
        assert!(!notifier.is_enabled());
    }
