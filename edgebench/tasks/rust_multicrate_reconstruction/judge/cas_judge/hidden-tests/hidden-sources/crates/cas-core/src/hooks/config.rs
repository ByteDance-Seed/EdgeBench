    #[test]
    fn test_default_config() {
        let config = DefaultHooksConfig::new();
        assert_eq!(config.token_budget(), 4000);
        assert!(!config.minimal_start());
        assert!(!config.mcp_enabled());
        assert!(config.inject_context());
    }

    #[test]
    fn test_with_mcp() {
        let config = DefaultHooksConfig::new().with_mcp();
        assert!(config.mcp_enabled());
    }

    #[test]
    fn test_plan_mode_default() {
        let plan = PlanModeConfig::default();
        assert!(plan.enabled);
        assert_eq!(plan.token_budget, 12000);
        assert_eq!(plan.task_limit, 20);
        assert!(plan.show_dependencies);
        assert!(!plan.include_closed);
    }
