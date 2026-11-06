use crate::hybrid_search::cache::*;


#[test]
fn test_lru_cache_eviction() {
    let mut cache: LruCache<String, i32> = LruCache::new(2, Duration::from_secs(60));

    cache.insert("a".to_string(), 1);
    cache.insert("b".to_string(), 2);
    // This should evict "a" (oldest)
    cache.insert("c".to_string(), 3);

    assert_eq!(cache.get(&"a".to_string()), None);
    assert_eq!(cache.get(&"b".to_string()), Some(2));
    assert_eq!(cache.get(&"c".to_string()), Some(3));
}


#[test]
fn test_lru_cache_ttl_expiration() {
    let mut cache: LruCache<String, i32> = LruCache::new(10, Duration::from_millis(10));

    cache.insert("a".to_string(), 1);

    // Should be present immediately
    assert_eq!(cache.get(&"a".to_string()), Some(1));

    // Wait for expiration
    std::thread::sleep(Duration::from_millis(20));

    // Should be gone after TTL
    assert_eq!(cache.get(&"a".to_string()), None);
}


#[test]
fn test_search_cache_embedding() {
    let cache = SearchCache::new();

    // Cache miss
    assert!(cache.get_query_embedding("test query").is_none());

    // Cache insert
    let embedding = vec![0.1, 0.2, 0.3];
    cache.put_query_embedding("test query", embedding.clone());

    // Cache hit
    let result = cache.get_query_embedding("test query");
    assert_eq!(result, Some(embedding));
}

#[test]
fn test_search_cache_semantic_results() {
    let cache = SearchCache::new();

    let embedding = vec![0.1, 0.2, 0.3];
    let results = vec![("entry-1".to_string(), 0.9), ("entry-2".to_string(), 0.8)];

    // Cache miss
    assert!(cache.get_semantic_results(&embedding, 10).is_none());

    // Cache insert
    cache.put_semantic_results(&embedding, 10, results.clone());

    // Cache hit
    let result = cache.get_semantic_results(&embedding, 10);
    assert_eq!(result, Some(results));
}



#[test]
fn test_semantic_cache_key_deterministic() {
    let embedding = vec![0.1, 0.2, 0.3, 0.4, 0.5];

    let key1 = SearchCache::semantic_cache_key(&embedding, 10);
    let key2 = SearchCache::semantic_cache_key(&embedding, 10);
    let key3 = SearchCache::semantic_cache_key(&embedding, 20);

    // Same inputs should produce same key
    assert_eq!(key1, key2);
    // Different k should produce different key
    assert_ne!(key1, key3);
}

#[test]
fn test_hybrid_results_cache() {
    let cache = SearchCache::new();

    let results = vec![HybridSearchResult {
        id: "entry-1".to_string(),
        score: 0.9,
        bm25_score: 0.8,
        semantic_score: 0.95,
        temporal_score: 0.7,
        graph_score: 0.6,
        code_score: 0.0,
        rerank_score: None,
    }];

    let options_hash = 12345u64;

    // Cache miss
    assert!(cache.get_hybrid_results(options_hash).is_none());

    // Cache insert
    cache.put_hybrid_results(options_hash, results.clone());

    // Cache hit
    let result = cache.get_hybrid_results(options_hash);
    assert!(result.is_some());
    assert_eq!(result.unwrap().len(), 1);
}



#[test]
fn test_cache_thread_safety() {
    use std::thread;

    let cache = Arc::new(SearchCache::new());
    let mut handles = vec![];

    // Spawn multiple threads that read and write to the cache
    for i in 0..10 {
        let cache_clone = Arc::clone(&cache);
        let handle = thread::spawn(move || {
            let query = format!("query-{i}");
            let embedding = vec![i as f32; 10];

            // Write
            cache_clone.put_query_embedding(&query, embedding.clone());

            // Read
            let result = cache_clone.get_query_embedding(&query);
            assert!(result.is_some());
        });
        handles.push(handle);
    }

    // Wait for all threads to complete
    for handle in handles {
        handle.join().expect("Thread panicked");
    }

    // Verify final state
    let stats = cache.stats();
    assert!(stats.embedding_cache.size >= 1); // At least some entries should be cached
}


#[test]
fn test_cache_hit_is_fast() {
    // This test verifies that cache hits are sub-millisecond
    // (actual embedding generation takes ~100ms)
    let cache = SearchCache::new();
    let query = "test query for performance";
    let embedding = vec![0.1f32; 1024]; // Realistic embedding size

    // Store in cache
    cache.put_query_embedding(query, embedding.clone());

    // Measure cache hit time
    let iterations = 1000;
    let start = std::time::Instant::now();
    for _ in 0..iterations {
        let _ = cache.get_query_embedding(query);
    }
    let elapsed = start.elapsed();

    // Average time per hit should be < 1ms (typically < 0.01ms)
    let avg_micros = elapsed.as_micros() / iterations as u128;
    assert!(
        avg_micros < 1000,
        "Cache hit took {avg_micros}µs, expected < 1000µs"
    );

    // In practice it should be much faster
    println!("Cache hit performance: {avg_micros}µs per operation ({iterations} total)");
}

#[test]
fn test_repeated_search_uses_cache() {
    // Test that demonstrates the caching pattern works correctly
    // Real speedup verification requires actual embedding infrastructure
    let cache = SearchCache::new();

    // Simulate what HybridSearch.semantic_search does
    let query = "test query";
    let k = 10;

    // First call - cache miss
    let miss1 = cache.get_query_embedding(query);
    assert!(miss1.is_none());

    // "Generate" embedding and cache it
    let embedding = vec![0.5f32; 512];
    cache.put_query_embedding(query, embedding.clone());

    // Second call - cache hit
    let hit1 = cache.get_query_embedding(query);
    assert!(hit1.is_some());

    // Check semantic results cache too
    let semantic_miss = cache.get_semantic_results(&embedding, k);
    assert!(semantic_miss.is_none());

    let results = vec![("entry-1".to_string(), 0.9f32)];
    cache.put_semantic_results(&embedding, k, results.clone());

    let semantic_hit = cache.get_semantic_results(&embedding, k);
    assert!(semantic_hit.is_some());
    assert_eq!(semantic_hit.unwrap(), results);

    // Verify stats show hits and misses
    let stats = cache.stats();
    assert!(stats.total_hits >= 2);
    assert!(stats.total_misses >= 2);
}
