    #[test]
    fn test_factory_view_mode_toggle() {
        let mut mode = FactoryViewMode::Panes;
        mode = match mode {
            FactoryViewMode::Panes => FactoryViewMode::MissionControl,
            FactoryViewMode::MissionControl => FactoryViewMode::Panes,
        };
        assert_eq!(mode, FactoryViewMode::MissionControl);

        mode = match mode {
            FactoryViewMode::Panes => FactoryViewMode::MissionControl,
            FactoryViewMode::MissionControl => FactoryViewMode::Panes,
        };
        assert_eq!(mode, FactoryViewMode::Panes);
    }
