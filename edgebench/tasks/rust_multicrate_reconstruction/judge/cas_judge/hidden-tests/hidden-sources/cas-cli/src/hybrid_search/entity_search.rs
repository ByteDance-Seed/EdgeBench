    #[test]
    fn test_parse_about_query() {
        let query = EntityQuery::parse("about:CAS").unwrap();
        assert_eq!(query.entity_name, "CAS");
        assert_eq!(query.intent, QueryIntent::About);
        assert!(query.entity_type.is_none());
    }

    #[test]
    fn test_parse_typed_entity() {
        let query = EntityQuery::parse("about:project:CAS").unwrap();
        assert_eq!(query.entity_name, "CAS");
        assert_eq!(query.entity_type, Some(EntityType::Project));
    }

    #[test]
    fn test_parse_entity_type_name() {
        let query = EntityQuery::parse("entity:tool:Rust").unwrap();
        assert_eq!(query.entity_name, "Rust");
        assert_eq!(query.entity_type, Some(EntityType::Tool));
    }

    #[test]
    fn test_combine_results() {
        let entity_result = EntitySearchResult {
            entity: None,
            entry_ids: vec!["e1".to_string(), "e2".to_string()],
            related_entities: vec![],
            confidence: 0.9,
        };

        let text_ids = vec!["e2".to_string(), "e3".to_string(), "e4".to_string()];

        let combined = combine_results(&entity_result, &text_ids, 0.5);

        // e2 should be first (appears in both)
        assert_eq!(combined[0].0, "e2");
        assert!(combined[0].1 > combined[1].1);
    }
