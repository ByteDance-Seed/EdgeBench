    #[test]
    fn test_daemon_config_defaults() {
        let config = EmbeddedDaemonConfig::default();
        assert_eq!(config.maintenance_interval_secs, 30 * 60);
        assert!(config.apply_decay);
    }
