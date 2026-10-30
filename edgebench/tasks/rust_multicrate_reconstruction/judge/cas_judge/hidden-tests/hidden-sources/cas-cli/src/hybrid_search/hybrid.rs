    #[test]
    fn test_hybrid_result_to_search_result() {
        let hybrid = HybridSearchResult {
            id: "test".to_string(),
            score: 0.8,
            bm25_score: 0.7,
            semantic_score: 0.9,
            temporal_score: 0.6,
            graph_score: 0.5,
            code_score: 0.4,
            rerank_score: Some(0.85),
        };

        let search_result: SearchResult = hybrid.into();
        assert_eq!(search_result.id, "test");
        assert_eq!(search_result.score, 0.8);
    }
