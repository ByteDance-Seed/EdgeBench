#[test]
fn test_lru_cache_basic() {
    let mut cache: LruCache<String, i32> = LruCache::new(3, Duration::from_secs(60));

    cache.insert("a".to_string(), 1);
    cache.insert("b".to_string(), 2);
    cache.insert("c".to_string(), 3);

    assert_eq!(cache.get(&"a".to_string()), Some(1));
    assert_eq!(cache.get(&"b".to_string()), Some(2));
    assert_eq!(cache.get(&"c".to_string()), Some(3));
}

#[test]
fn test_lru_cache_access_updates_order() {
    let mut cache: LruCache<String, i32> = LruCache::new(2, Duration::from_secs(60));

    cache.insert("a".to_string(), 1);
    cache.insert("b".to_string(), 2);

    // Access "a" to make it recently used
    cache.get(&"a".to_string());

    // Insert "c" - should evict "b" (now oldest)
    cache.insert("c".to_string(), 3);

    assert_eq!(cache.get(&"a".to_string()), Some(1));
    assert_eq!(cache.get(&"b".to_string()), None);
    assert_eq!(cache.get(&"c".to_string()), Some(3));
}

#[test]
fn test_lru_cache_invalidate_by_dependency() {
    let mut cache: LruCache<String, Vec<String>> = LruCache::new(10, Duration::from_secs(60));

    // Insert entries with dependencies
    cache.insert_with_deps(
        "query1".to_string(),
        vec!["result1".to_string()],
        vec!["entry-a".to_string(), "entry-b".to_string()],
    );
    cache.insert_with_deps(
        "query2".to_string(),
        vec!["result2".to_string()],
        vec!["entry-c".to_string()],
    );
    cache.insert_with_deps(
        "query3".to_string(),
        vec!["result3".to_string()],
        vec!["entry-a".to_string()],
    );

    // Invalidate entry-a - should remove query1 and query3
    cache.invalidate_by_dependency("entry-a");

    assert_eq!(cache.get(&"query1".to_string()), None);
    assert!(cache.get(&"query2".to_string()).is_some());
    assert_eq!(cache.get(&"query3".to_string()), None);
}

#[test]
fn test_search_cache_invalidation() {
    let cache = SearchCache::new();

    let embedding = vec![0.1, 0.2, 0.3];
    let results = vec![("entry-1".to_string(), 0.9), ("entry-2".to_string(), 0.8)];

    cache.put_semantic_results(&embedding, 10, results);

    // Verify cache hit
    assert!(cache.get_semantic_results(&embedding, 10).is_some());

    // Invalidate entry-1
    cache.invalidate_entry("entry-1");

    // Cache should now be empty
    assert!(cache.get_semantic_results(&embedding, 10).is_none());
}

#[test]
fn test_search_cache_stats() {
    let cache = SearchCache::new();

    // Generate some hits and misses
    cache.get_query_embedding("miss1");
    cache.get_query_embedding("miss2");
    cache.put_query_embedding("hit", vec![1.0]);
    cache.get_query_embedding("hit");

    let stats = cache.stats();
    assert_eq!(stats.total_hits, 1);
    assert_eq!(stats.total_misses, 2);
    assert!(stats.hit_rate > 0.3 && stats.hit_rate < 0.4);
}

#[test]
fn test_cache_hit_returns_identical_results() {
    let cache = SearchCache::new();

    // Store embedding
    let query = "test query for caching";
    let embedding = vec![0.1, 0.2, 0.3, 0.4, 0.5];
    cache.put_query_embedding(query, embedding.clone());

    // First retrieval
    let result1 = cache.get_query_embedding(query).unwrap();

    // Second retrieval
    let result2 = cache.get_query_embedding(query).unwrap();

    // Results should be identical
    assert_eq!(result1.len(), result2.len());
    for (a, b) in result1.iter().zip(result2.iter()) {
        assert!((a - b).abs() < f32::EPSILON);
    }
}

#[test]
fn test_invalidation_clears_affected_entries() {
    let cache = SearchCache::new();

    // Create results with different entry dependencies
    let results1 = vec![
        HybridSearchResult {
            id: "entry-a".to_string(),
            score: 0.9,
            bm25_score: 0.8,
            semantic_score: 0.9,
            temporal_score: 0.7,
            graph_score: 0.0,
            code_score: 0.0,
            rerank_score: None,
        },
        HybridSearchResult {
            id: "entry-b".to_string(),
            score: 0.8,
            bm25_score: 0.7,
            semantic_score: 0.8,
            temporal_score: 0.6,
            graph_score: 0.0,
            code_score: 0.0,
            rerank_score: None,
        },
    ];

    let results2 = vec![HybridSearchResult {
        id: "entry-c".to_string(),
        score: 0.7,
        bm25_score: 0.6,
        semantic_score: 0.7,
        temporal_score: 0.5,
        graph_score: 0.0,
        code_score: 0.0,
        rerank_score: None,
    }];

    // Cache both result sets
    cache.put_hybrid_results(111, results1);
    cache.put_hybrid_results(222, results2);

    // Verify both are cached
    assert!(cache.get_hybrid_results(111).is_some());
    assert!(cache.get_hybrid_results(222).is_some());

    // Invalidate entry-a - should remove results1 but not results2
    cache.invalidate_entry("entry-a");

    assert!(cache.get_hybrid_results(111).is_none()); // Cleared
    assert!(cache.get_hybrid_results(222).is_some()); // Still cached

    // Invalidate entry-c
    cache.invalidate_entry("entry-c");

    assert!(cache.get_hybrid_results(222).is_none()); // Now cleared
}

#[test]
fn test_cache_miss_returns_none() {
    let cache = SearchCache::new();

    // All caches should miss for non-existent keys
    assert!(cache.get_query_embedding("nonexistent").is_none());
    assert!(cache.get_semantic_results(&[0.1, 0.2], 10).is_none());
    assert!(cache.get_hybrid_results(99999).is_none());
}
