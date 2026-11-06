    #[test]
    fn test_method_comparison() {
        let temp = TempDir::new().unwrap();
        let store = MetricsStore::open(&temp.path().join("metrics.db")).unwrap();

        // Record BM25 searches
        for i in 0..10 {
            store
                .record_search(&SearchEvent {
                    id: format!("bm25-{i}"),
                    timestamp: Utc::now(),
                    query: "test".to_string(),
                    method: SearchMethod::Bm25,
                    latency_ms: 50,
                    result_count: 5,
                    result_ids: vec!["a".to_string()],
                    session_id: None,
                })
                .unwrap();
        }

        // Record Hybrid searches (slower but assume better)
        for i in 0..10 {
            store
                .record_search(&SearchEvent {
                    id: format!("hybrid-{i}"),
                    timestamp: Utc::now(),
                    query: "test".to_string(),
                    method: SearchMethod::Hybrid,
                    latency_ms: 200,
                    result_count: 5,
                    result_ids: vec!["a".to_string()],
                    session_id: None,
                })
                .unwrap();
        }

        let comparison = store
            .compare_methods(SearchMethod::Bm25, SearchMethod::Hybrid)
            .unwrap();

        // Hybrid is slower
        assert!(comparison.latency_diff_pct > 0.0);
    }
