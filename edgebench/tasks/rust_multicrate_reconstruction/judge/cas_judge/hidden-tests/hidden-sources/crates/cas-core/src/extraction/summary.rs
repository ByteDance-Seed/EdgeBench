    #[test]
    fn test_generate_summary() {
        let generator = SummaryGenerator::new();
        let entity = create_test_entity();
        let entries = create_test_entries();

        let summary = generator.generate_summary(&entity, &entries).unwrap();

        assert!(summary.contains("Rust"));
        assert!(summary.contains("tool"));
    }
