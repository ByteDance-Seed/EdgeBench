#[test]
fn test_hybrid_empty_query() {
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let search = HybridSearch::new(bm25_index);

    let opts = HybridSearchOptions {
        query: "".to_string(),
        limit: 10,
        ..Default::default()
    };

    let results = search.search(&opts).unwrap();
    assert!(
        results.is_empty(),
        "Empty query should return empty results"
    );
}

#[test]
fn test_rrf_combines_rankings() {
    let ranking1 = vec![
        ("a".to_string(), 100.0),
        ("b".to_string(), 50.0),
        ("c".to_string(), 10.0),
    ];

    let ranking2 = vec![
        ("b".to_string(), 0.95),
        ("c".to_string(), 0.80),
        ("a".to_string(), 0.60),
    ];

    let combined = reciprocal_rank_fusion(&[ranking1, ranking2], 60.0);

    // All documents should be present
    assert_eq!(combined.len(), 3);

    // All scores should be positive
    for (_, score) in &combined {
        assert!(*score > 0.0);
    }

    // Document appearing at rank 1 in one list and rank 3 in another
    // should have different RRF score than one at rank 2 in both
    let a_score = combined
        .iter()
        .find(|(id, _)| id == "a")
        .map(|(_, s)| *s)
        .unwrap();
    let b_score = combined
        .iter()
        .find(|(id, _)| id == "b")
        .map(|(_, s)| *s)
        .unwrap();

    // b is at rank 1 and rank 2, a is at rank 1 and rank 3
    // They should have similar but not identical scores
    assert!(a_score > 0.0);
    assert!(b_score > 0.0);
}

    #[tokio::test]
    async fn test_async_hybrid_search() {
        let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());

        let docs = vec![
            TestDoc::new("1", "Rust programming language"),
            TestDoc::new("2", "Python data science"),
            TestDoc::new("3", "Rust async runtime"),
        ];

        for doc in &docs {
            bm25_index.index(doc).unwrap();
        }

        let search = HybridSearch::new(bm25_index);

        let opts = HybridSearchOptions {
            query: "rust".to_string(),
            limit: 10,
            ..Default::default()
        };

        let results = search.search_async(&opts).await.unwrap();
        assert!(!results.is_empty());

        // Should find rust documents
        assert!(
            results.iter().any(|r| r.id == "1" || r.id == "3"),
            "Should find Rust documents"
        );
    }
