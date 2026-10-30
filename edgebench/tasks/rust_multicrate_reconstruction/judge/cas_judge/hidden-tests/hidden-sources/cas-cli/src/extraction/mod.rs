    #[test]
    fn test_ai_extractor_config_default() {
        let config = AIExtractorConfig::default();
        assert!(config.extract_learnings);
        assert!(config.extract_preferences);
        assert!(config.suggest_rules);
        assert_eq!(config.max_thinking_tokens, 2000);
    }

    #[test]
    fn test_parse_response_with_quality() {
        let extractor = AIExtractor::new(AIExtractorConfig::default());
        let response = r#"{
            "learnings": [
                {"content": "Use table-driven tests for API handlers in src/handlers/", "quality_score": 8, "confidence": 0.9, "tags": ["testing"]}
            ],
            "preferences": [],
            "rules": [
                {"content": "Always run cargo fmt before commit", "quality_score": 7, "confidence": 0.8, "tags": ["rust"]}
            ]
        }"#;

        let result = extractor.parse_response(response, "test-id").unwrap();
        assert_eq!(result.learnings.len(), 1);
        assert_eq!(
            result.learnings[0].content,
            "Use table-driven tests for API handlers in src/handlers/"
        );
        assert_eq!(result.learnings[0].quality_score, Some(8));
        assert_eq!(result.rules.len(), 1);
    }

    #[test]
    fn test_quality_filtering() {
        let extractor = AIExtractor::new(AIExtractorConfig::default());
        let response = r#"{
            "learnings": [
                {"content": "mix compile compiles the project", "quality_score": 3, "confidence": 0.9, "tags": ["elixir"]},
                {"content": "VouchWall API uses Phoenix with custom auth middleware", "quality_score": 8, "confidence": 0.85, "tags": ["phoenix", "auth"]}
            ],
            "preferences": [
                {"content": "Uses tabs", "quality_score": 2, "confidence": 0.5}
            ],
            "rules": []
        }"#;

        let result = extractor.parse_response(response, "test-id").unwrap();
        assert_eq!(result.learnings.len(), 1);
        assert_eq!(result.learnings[0].quality_score, Some(8));
        assert!(result.learnings[0].content.contains("VouchWall"));
        assert_eq!(result.preferences.len(), 0);
    }

    #[test]
    fn test_default_extractor() {
        let extractor = default_extractor();
        let observation = Entry {
            id: "test".to_string(),
            entry_type: EntryType::Observation,
            content: "Test".to_string(),
            ..Default::default()
        };

        let result = extractor.extract(&observation).unwrap();
        assert!(result.deferred);
    }
