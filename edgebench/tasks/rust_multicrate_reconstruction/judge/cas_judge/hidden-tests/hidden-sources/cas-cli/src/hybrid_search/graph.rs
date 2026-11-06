    #[test]
    fn test_parse_typed_entity() {
        let result = parse_typed_entity("person:Alice");
        assert!(result.is_some());
        let (etype, name) = result.unwrap();
        assert_eq!(etype, EntityType::Person);
        assert_eq!(name, "Alice");

        let result = parse_typed_entity("project:CAS");
        assert!(result.is_some());
        let (etype, name) = result.unwrap();
        assert_eq!(etype, EntityType::Project);
        assert_eq!(name, "CAS");

        // Invalid format
        let result = parse_typed_entity("no colon here");
        assert!(result.is_none());

        // Invalid type
        let result = parse_typed_entity("invalid:test");
        assert!(result.is_none());
    }

    #[test]
    fn test_parse_typed_entity_multiple_colons() {
        let result = parse_typed_entity("project:CAS:v2");
        assert!(result.is_some());
        let (_, name) = result.unwrap();
        assert_eq!(name, "CAS:v2"); // Everything after first colon
    }

    #[test]
    fn test_spreading_activation_config_relation_weights() {
        let config = SpreadingActivationConfig::default();

        // Check all relation types have weights
        assert_eq!(
            config.relation_weights.get(&RelationType::WorksOn),
            Some(&0.9)
        );
        assert_eq!(
            config.relation_weights.get(&RelationType::Uses),
            Some(&0.85)
        );
        assert_eq!(
            config.relation_weights.get(&RelationType::MentionedIn),
            Some(&0.7)
        );
        assert_eq!(
            config.relation_weights.get(&RelationType::RelatedTo),
            Some(&0.8)
        );
        assert_eq!(
            config.relation_weights.get(&RelationType::PartOf),
            Some(&0.75)
        );
        assert_eq!(
            config.relation_weights.get(&RelationType::DependsOn),
            Some(&0.8)
        );
        assert_eq!(
            config.relation_weights.get(&RelationType::Created),
            Some(&0.7)
        );
        assert_eq!(
            config.relation_weights.get(&RelationType::Modified),
            Some(&0.65)
        );
        assert_eq!(
            config.relation_weights.get(&RelationType::Knows),
            Some(&0.6)
        );
        assert_eq!(config.relation_weights.get(&RelationType::Owns), Some(&0.7));
        assert_eq!(
            config.relation_weights.get(&RelationType::Implements),
            Some(&0.85)
        );
    }

    #[test]
    fn test_graph_retrieval_result() {
        let result = GraphRetrievalResult {
            entry_id: "entry-123".to_string(),
            activation_score: 0.85,
            contributing_entities: vec![
                ("entity-1".to_string(), 0.5),
                ("entity-2".to_string(), 0.35),
            ],
            min_hops: 1,
        };

        assert_eq!(result.entry_id, "entry-123");
        assert_eq!(result.activation_score, 0.85);
        assert_eq!(result.contributing_entities.len(), 2);
        assert_eq!(result.min_hops, 1);
    }

    #[test]
    fn test_extract_candidates_multi_word() {
        // Test multi-word entity extraction (consecutive capitalized words)
        let query = "Alice Smith works on Project CAS";
        let words: Vec<&str> = query.split_whitespace().collect();

        let mut multi_word = Vec::new();
        let mut i = 0;
        while i < words.len() {
            let word = words[i].trim_matches(|c: char| !c.is_alphanumeric());
            if word
                .chars()
                .next()
                .map(|c| c.is_uppercase())
                .unwrap_or(false)
            {
                let mut phrase = word.to_string();
                let mut j = i + 1;
                while j < words.len() {
                    let next = words[j].trim_matches(|c: char| !c.is_alphanumeric());
                    if next
                        .chars()
                        .next()
                        .map(|c| c.is_uppercase())
                        .unwrap_or(false)
                    {
                        phrase.push(' ');
                        phrase.push_str(next);
                        j += 1;
                    } else {
                        break;
                    }
                }
                if phrase.contains(' ') {
                    multi_word.push(phrase);
                }
                i = j;
            } else {
                i += 1;
            }
        }

        assert!(multi_word.contains(&"Alice Smith".to_string()));
        assert!(multi_word.contains(&"Project CAS".to_string()));
    }
