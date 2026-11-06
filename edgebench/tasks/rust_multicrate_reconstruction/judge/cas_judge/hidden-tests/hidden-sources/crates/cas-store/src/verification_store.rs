    #[test]
    fn test_add_and_get_verification() {
        let (store, _dir) = create_test_store();

        let verification = Verification::approved(
            "ver-test".to_string(),
            "cas-1234".to_string(),
            "All checks passed".to_string(),
        );

        store.add(&verification).unwrap();

        let retrieved = store.get("ver-test").unwrap();
        assert_eq!(retrieved.id, "ver-test");
        assert_eq!(retrieved.task_id, "cas-1234");
        assert!(retrieved.is_approved());
        assert_eq!(retrieved.summary, "All checks passed");
    }

    #[test]
    fn test_verification_with_confidence() {
        let (store, _dir) = create_test_store();

        let mut verification = Verification::approved(
            "ver-test".to_string(),
            "cas-1234".to_string(),
            "High confidence".to_string(),
        );
        verification.set_confidence(0.95);

        store.add(&verification).unwrap();

        let retrieved = store.get("ver-test").unwrap();
        assert_eq!(retrieved.confidence, Some(0.95));
    }
