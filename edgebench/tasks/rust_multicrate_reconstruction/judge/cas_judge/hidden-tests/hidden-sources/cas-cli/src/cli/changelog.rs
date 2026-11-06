    #[test]
    fn normalize_tag_keeps_v_prefix() {
        assert_eq!(normalize_tag("v0.5.6"), "v0.5.6");
    }
