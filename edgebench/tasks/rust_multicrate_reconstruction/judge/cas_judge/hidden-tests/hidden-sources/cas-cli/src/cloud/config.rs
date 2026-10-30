    #[test]
    fn test_set_and_clear_team() {
        let mut config = CloudConfig::default();
        assert!(!config.has_team());
        assert!(config.team_id.is_none());
        assert!(config.team_slug.is_none());

        config.set_team("team-123", "my-team");
        assert!(config.has_team());
        assert_eq!(config.team_id, Some("team-123".to_string()));
        assert_eq!(config.team_slug, Some("my-team".to_string()));

        config.clear_team();
        assert!(!config.has_team());
        assert!(config.team_id.is_none());
        assert!(config.team_slug.is_none());
    }

    #[test]
    fn test_team_sync_timestamps_persist() {
        let temp = TempDir::new().unwrap();
        let path = temp.path().join("cloud.json");

        let mut config = CloudConfig {
            token: Some("test_token".to_string()),
            ..Default::default()
        };
        config.set_team("team-123", "my-team");
        let ts = Utc::now();
        config.set_team_sync_timestamp("team-123", ts);

        config.save_to(&path).unwrap();

        let loaded = CloudConfig::load_from(&path).unwrap();
        assert_eq!(loaded.team_id, Some("team-123".to_string()));
        assert_eq!(loaded.team_slug, Some("my-team".to_string()));
        // Timestamps are stored with second precision in JSON
        let loaded_ts = loaded.get_team_sync_timestamp("team-123").unwrap();
        assert!((loaded_ts - ts).num_seconds().abs() < 1);
    }
