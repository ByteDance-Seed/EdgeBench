    #[test]
    fn test_not_initialized_error() {
        let err = CoreError::NotInitialized;
        assert!(err.to_string().contains("not initialized"));
    }
