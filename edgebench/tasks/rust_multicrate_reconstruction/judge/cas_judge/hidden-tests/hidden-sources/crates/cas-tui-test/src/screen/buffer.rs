    #[test]
    fn test_contains_text() {
        let mut buf = ScreenBuffer::new(80, 24);
        buf.put_str("Hello World");
        assert!(buf.contains_text("World"));
        assert!(!buf.contains_text("Foo"));
    }
