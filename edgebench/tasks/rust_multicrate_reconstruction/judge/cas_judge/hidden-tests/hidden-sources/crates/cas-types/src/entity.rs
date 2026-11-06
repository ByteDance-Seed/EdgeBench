    #[test]
    fn test_entity_type_from_str() {
        assert_eq!(EntityType::from_str("person").unwrap(), EntityType::Person);
        assert_eq!(
            EntityType::from_str("PROJECT").unwrap(),
            EntityType::Project
        );
        assert_eq!(EntityType::from_str("tool").unwrap(), EntityType::Tool);
        assert_eq!(EntityType::from_str("repo").unwrap(), EntityType::Project);
        assert!(EntityType::from_str("invalid").is_err());
    }

    #[test]
    fn test_relation_type_from_str() {
        assert_eq!(
            RelationType::from_str("works_on").unwrap(),
            RelationType::WorksOn
        );
        assert_eq!(RelationType::from_str("uses").unwrap(), RelationType::Uses);
        assert_eq!(
            RelationType::from_str("part_of").unwrap(),
            RelationType::PartOf
        );
        assert!(RelationType::from_str("invalid").is_err());
    }

    #[test]
    fn test_relationship_creation() {
        let rel = Relationship::new(
            "rel-001".to_string(),
            "ent-001".to_string(),
            "ent-002".to_string(),
            RelationType::WorksOn,
        );
        assert_eq!(rel.relation_type, RelationType::WorksOn);
        assert_eq!(rel.observation_count, 1);
        assert!(rel.is_valid());
    }

    #[test]
    fn test_relationship_observation() {
        let mut rel = Relationship::new(
            "rel-001".to_string(),
            "ent-001".to_string(),
            "ent-002".to_string(),
            RelationType::Uses,
        );

        // Set initial weight lower to test strengthening
        rel.weight = 0.5;
        let initial_weight = rel.weight;

        rel.record_observation(Some("entry-001"));
        rel.record_observation(Some("entry-002"));
        rel.record_observation(Some("entry-001")); // Duplicate

        assert_eq!(rel.observation_count, 4); // 1 initial + 3 calls
        assert!(rel.weight > initial_weight); // Should have increased
        assert!(rel.weight <= 1.0); // But capped at 1.0
        assert_eq!(rel.source_entries.len(), 2); // Deduped
    }
