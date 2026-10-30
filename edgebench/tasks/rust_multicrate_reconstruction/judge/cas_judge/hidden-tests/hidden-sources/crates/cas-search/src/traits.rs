    #[test]
    fn test_search_result() {
        let result = SearchResult::new("doc-001", 0.85, ScoreSource::Hybrid);
        assert_eq!(result.id, "doc-001");
        assert!((result.score - 0.85).abs() < 0.001);
        assert_eq!(result.source, ScoreSource::Hybrid);
    }

    #[test]
    fn test_score_source_equality() {
        assert_eq!(ScoreSource::Bm25, ScoreSource::Bm25);
        assert_ne!(ScoreSource::Bm25, ScoreSource::Semantic);
    }
