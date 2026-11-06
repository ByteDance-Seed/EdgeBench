    #[test]
    fn test_preview() {
        let mut spec = Spec::new("spec-001".to_string(), "Short Title".to_string());
        assert_eq!(spec.preview(50), "Short Title");

        spec.summary = "A longer summary that describes the spec".to_string();
        assert_eq!(spec.preview(50), "A longer summary that describes the spec");

        spec.summary =
            "A very long summary that should be truncated when displayed in preview mode"
                .to_string();
        assert_eq!(spec.preview(30), "A very long summary that sh...");
    }
