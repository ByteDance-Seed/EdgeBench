    #[test]
    fn test_telemetry_client_disabled() {
        let config = TelemetryConfig {
            enabled: false,
            anonymous_id: Some("test-id".to_string()),
            consent_given: Some(false),
        };

        let client = TelemetryClient::new(&config);
        assert!(!client.is_enabled());
        assert_eq!(client.anonymous_id(), "test-id");
    }

    #[test]
    fn test_uuid_uniqueness() {
        let id1 = uuid_v4();
        let id2 = uuid_v4();
        assert_ne!(id1, id2);
    }
