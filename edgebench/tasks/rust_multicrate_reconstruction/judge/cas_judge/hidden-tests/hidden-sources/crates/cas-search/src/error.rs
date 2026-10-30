    #[test]
    fn test_error_display() {
        let err = SearchError::index("failed to open");
        assert_eq!(err.to_string(), "index error: failed to open");

        let err = SearchError::DimensionMismatch {
            expected: 1024,
            actual: 768,
        };
        assert_eq!(
            err.to_string(),
            "dimension mismatch: expected 1024, got 768"
        );
    }
