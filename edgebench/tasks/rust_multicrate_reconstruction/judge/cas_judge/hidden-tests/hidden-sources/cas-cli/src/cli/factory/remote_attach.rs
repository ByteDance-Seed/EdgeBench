    #[test]
    fn test_parse_remote_target_without_device() {
        let (device, factory_id) = parse_remote_target("f-abc123");
        assert_eq!(device, None);
        assert_eq!(factory_id, "f-abc123");
    }
