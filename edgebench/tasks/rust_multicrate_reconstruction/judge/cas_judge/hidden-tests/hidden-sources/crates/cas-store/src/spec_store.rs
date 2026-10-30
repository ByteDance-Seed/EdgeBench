    #[test]
    fn test_spec_id_format() {
        let (_temp, store) = create_test_store();

        let id = store.generate_id().unwrap();
        assert!(id.starts_with("spec-"));
        assert!(id.len() >= 9); // "spec-" + at least 4 chars
    }
