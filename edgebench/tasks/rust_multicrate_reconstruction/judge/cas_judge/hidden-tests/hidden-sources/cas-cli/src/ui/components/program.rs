    #[test]
    fn test_clear_lines_zero_is_noop() {
        let mut buf = Vec::new();
        clear_lines(&mut buf, 0).unwrap();
        assert!(buf.is_empty());
    }
