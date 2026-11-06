    #[test]
    fn truncate_str_keeps_short_values() {
        assert_eq!(truncate_str("short", 10), "short");
    }
