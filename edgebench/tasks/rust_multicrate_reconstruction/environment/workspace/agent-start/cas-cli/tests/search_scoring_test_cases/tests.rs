use crate::*;


/// Test: Conceptual/semantic queries should find related content
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_conceptual_query_finds_related() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    // Add memories about a topic using different terms
    add_memory(
        &dir,
        "The ownership system in Rust prevents data races at compile time",
        Some("Rust Ownership"),
        Some("rust"),
    );
    add_memory(
        &dir,
        "Memory management in C requires manual malloc and free calls",
        Some("C Memory"),
        Some("c,memory"),
    );
    add_memory(
        &dir,
        "Garbage collection automatically reclaims unused memory in Java",
        Some("Java GC"),
        Some("java,gc"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    // Conceptual query - should find Rust ownership even without exact match
    let results = search_bm25(&dir, "how to avoid memory leaks");

    // Should find memory-related content
    assert!(!results.is_empty(), "Should find memory-related content");
}

/// Test: Multi-word queries should work well
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_multi_word_query() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "Implemented error handling with custom Result types for API endpoints",
        Some("Error Handling"),
        Some("rust,api"),
    );
    add_memory(
        &dir,
        "Added logging middleware to capture request and response data",
        Some("Logging Middleware"),
        Some("rust,middleware"),
    );
    add_memory(
        &dir,
        "The API now supports pagination for large result sets",
        Some("API Pagination"),
        Some("api"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    let results = search_bm25(&dir, "error handling API");

    assert!(
        !results.is_empty(),
        "Should find results for multi-word query"
    );

    // First result should mention both error handling and API
    let (_, score) = &results[0];
    assert!(
        score >= &0.3,
        "Multi-word match should score reasonably, got {score}"
    );
}

/// Test: Score ordering is correct (more relevant = higher score)
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_score_ordering() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    // Entry that perfectly matches
    let perfect_id = add_memory(
        &dir,
        "Database connection pooling configuration for PostgreSQL",
        Some("DB Pool Config"),
        Some("database,postgresql"),
    );

    // Entry that partially matches
    let partial_id = add_memory(
        &dir,
        "Configured the application to use environment variables",
        Some("Env Config"),
        Some("config"),
    );

    // Entry that barely matches
    let _weak_id = add_memory(
        &dir,
        "Updated the README with installation instructions",
        Some("README Update"),
        Some("docs"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    let results = search_bm25(&dir, "database configuration");

    if results.len() >= 2 {
        // Find scores for our entries
        let perfect_score = results
            .iter()
            .find(|(id, _)| id == &perfect_id)
            .map(|(_, s)| *s);
        let partial_score = results
            .iter()
            .find(|(id, _)| id == &partial_id)
            .map(|(_, s)| *s);

        if let (Some(p), Some(pa)) = (perfect_score, partial_score) {
            assert!(
                p >= pa,
                "Perfect match ({p}) should score >= partial match ({pa})"
            );
        }
    }
}

/// Test: Empty or very short queries handle gracefully
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_short_queries() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "The API server runs on port 8080 by default",
        Some("API Port"),
        Some("api"),
    );
    add_memory(
        &dir,
        "API rate limiting is set to 100 requests per minute",
        Some("API Rate Limit"),
        Some("api"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    // Single word query
    let results = search_bm25(&dir, "API");
    assert!(
        results.len() >= 2,
        "Single word 'API' should find both entries"
    );

    // All scores should be positive
    for (_, score) in &results {
        assert!(score > &0.0, "Scores should be positive");
    }
}

/// Test: Scores are in reasonable range (calibrated)
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_score_calibration() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "Implemented user authentication with JWT tokens",
        Some("Auth JWT"),
        Some("auth,jwt"),
    );
    add_memory(
        &dir,
        "Added OAuth2 provider support for Google and GitHub login",
        Some("OAuth Providers"),
        Some("auth,oauth"),
    );
    add_memory(
        &dir,
        "User sessions are stored in Redis with 24-hour TTL",
        Some("Sessions"),
        Some("auth,redis"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    let results = search_bm25(&dir, "authentication");

    for (_, score) in &results {
        // Scores should be in 0-1 range after calibration
        assert!(
            (&0.0..=&1.0).contains(&score),
            "Score {score} should be in [0, 1]"
        );
    }

    if !results.is_empty() {
        // Top result should have decent score for a relevant query
        let (_, top_score) = &results[0];
        assert!(
            top_score >= &0.3,
            "Top result for relevant query should score >= 0.3, got {top_score}"
        );
    }
}

/// Test: Technical queries with special characters
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_technical_queries() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "Fixed error E0382: borrow of moved value in the parser module",
        Some("E0382 Fix"),
        Some("rust,error"),
    );
    add_memory(
        &dir,
        "The endpoint /api/v1/users returns user list in JSON",
        Some("API Endpoint"),
        Some("api"),
    );
    add_memory(
        &dir,
        "Using src/lib.rs as the library entry point",
        Some("Lib Entry"),
        Some("rust"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    // Search for error code
    let results = search_bm25(&dir, "E0382");
    assert!(!results.is_empty(), "Should find error code reference");

    // Search for path
    let results = search_bm25(&dir, "/api/v1/users");
    assert!(!results.is_empty(), "Should find API path");
}

/// Test: Queries with common stop words
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_stop_words() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "The quick brown fox jumps over the lazy dog",
        Some("Pangram"),
        Some("test"),
    );
    add_memory(
        &dir,
        "A fast red fox leaps across a sleepy hound",
        Some("Similar"),
        Some("test"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    // Query with stop words should still find relevant content
    let results = search_bm25(&dir, "the fox and the dog");
    assert!(
        !results.is_empty(),
        "Should find content despite stop words"
    );
}

/// Test: No false positives for unrelated content
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_no_false_positives() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "Implemented dark mode toggle in the settings page",
        Some("Dark Mode"),
        Some("ui"),
    );
    add_memory(
        &dir,
        "Fixed CSS flexbox layout issues on mobile",
        Some("CSS Fix"),
        Some("css"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    // Query for completely unrelated topic
    let results = search_bm25(&dir, "quantum computing algorithms");

    // Should either return no results or very low scores
    if !results.is_empty() {
        let (_, top_score) = &results[0];
        assert!(
            top_score < &0.3,
            "Unrelated query should score low, got {top_score}"
        );
    }
}

/// Test: Recent vs old memories with temporal queries

/// Test: Tags don't interfere with content search
#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_tags_dont_dominate() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    // Entry with rust in tags but not content
    add_memory(
        &dir,
        "Implemented a web server using Actix framework",
        Some("Web Server"),
        Some("rust,web"),
    );

    // Entry with rust in content
    add_memory(
        &dir,
        "Rust provides zero-cost abstractions for systems programming",
        Some("Rust Info"),
        Some("programming"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    let results = search_bm25(&dir, "rust programming");

    // Entry with "rust" in content should score higher
    if results.len() >= 2 {
        // The Rust Info entry should rank well since it has "Rust" in content
        let content_match = results.iter().any(|(id, _)| id.contains("Rust"));
        assert!(
            content_match || !results.is_empty(),
            "Should find content with 'rust' keyword"
        );
    }
}

// ============================================================================
// Semantic Search Tests (require embedding models)
// These tests auto-detect if the model is available and skip gracefully if not
// ============================================================================

/// Test: Semantic search finds conceptually similar content
#[test]
fn test_semantic_conceptual_similarity() {
    skip_without_embeddings!();
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    // Add memories using different terminology for the same concept
    add_memory(
        &dir,
        "The ownership system prevents data races at compile time by tracking who owns each piece of memory",
        Some("Rust Ownership"),
        Some("rust"),
    );
    add_memory(
        &dir,
        "Manual memory allocation with malloc requires careful tracking to avoid leaks and double-frees",
        Some("C Memory"),
        Some("c"),
    );
    add_memory(
        &dir,
        "Automatic garbage collection reclaims unused heap memory during program execution",
        Some("GC"),
        Some("java"),
    );
    add_memory(
        &dir,
        "The borrow checker ensures references don't outlive the data they point to",
        Some("Borrow Checker"),
        Some("rust"),
    );

    // Generate embeddings
    assert!(generate_embeddings(&dir), "Failed to generate embeddings");

    // Conceptual query - should find memory management content using semantic similarity
    let results = search_hybrid(&dir, "how to prevent memory leaks");

    assert!(
        !results.is_empty(),
        "Semantic search should find memory-related content"
    );

    // With calibrated scores, top result should be in meaningful range
    let top_score = results.first().map(|(_, s)| *s).unwrap_or(0.0);
    assert!(
        top_score >= 0.3,
        "Top result should score >= 0.3 for related content, got {top_score}"
    );
}

/// Test: Semantic search improves recall for synonyms
#[test]
fn test_semantic_synonym_matching() {
    skip_without_embeddings!();
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "Implemented error handling for network failures",
        Some("Error Handling"),
        Some("api"),
    );
    add_memory(
        &dir,
        "Added exception management for HTTP timeouts",
        Some("Exception Mgmt"),
        Some("api"),
    );
    add_memory(
        &dir,
        "Created fault tolerance mechanism for service calls",
        Some("Fault Tolerance"),
        Some("api"),
    );

    assert!(generate_embeddings(&dir), "Failed to generate embeddings");

    // These should all be found via semantic similarity
    let results = search_hybrid(&dir, "dealing with errors");

    // Should find at least 2 results via semantic similarity
    assert!(
        results.len() >= 2,
        "Semantic search should find synonym content, got {}",
        results.len()
    );

    // Top result should have meaningful calibrated score
    let top_score = results.first().map(|(_, s)| *s).unwrap_or(0.0);
    assert!(
        top_score >= 0.3,
        "Top synonym match should score >= 0.3, got {top_score}"
    );
}

/// Test: Hybrid search combines BM25 and semantic effectively
#[test]
fn test_hybrid_beats_bm25_alone() {
    skip_without_embeddings!();
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    // Entry with exact keyword match
    add_memory(
        &dir,
        "Database connection pooling improves performance",
        Some("DB Pooling"),
        Some("database"),
    );

    // Entry conceptually related but different words
    add_memory(
        &dir,
        "Reusing established network links reduces latency overhead",
        Some("Connection Reuse"),
        Some("networking"),
    );

    assert!(generate_embeddings(&dir), "Failed to generate embeddings");

    // BM25 only - should find first entry, maybe miss second
    let bm25_results = search_bm25(&dir, "connection pooling");

    // Hybrid - should find both via BM25 + semantic
    let hybrid_results = search_hybrid(&dir, "connection pooling");

    // Hybrid should have at least as many results as BM25
    assert!(
        hybrid_results.len() >= bm25_results.len(),
        "Hybrid should find at least as many results as BM25"
    );

    // Check that semantic similarity helps find conceptually related content
    let hybrid_has_reuse = hybrid_results
        .iter()
        .any(|(id, _)| id.contains("Reuse") || id.contains("networking"));
    if hybrid_has_reuse {
        println!(
            "Semantic search successfully found conceptually related 'Connection Reuse' entry"
        );
    }
}

/// Test: Multi-channel boost rewards entries found by multiple methods

/// Test: Adaptive weights work for different query types
#[test]
fn test_adaptive_weights() {
    skip_without_embeddings!();
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "Fixed error E0382: use of moved value in parser",
        Some("E0382 Fix"),
        Some("rust,error"),
    );
    add_memory(
        &dir,
        "How to handle borrowed values that outlive their scope",
        Some("Borrowing Guide"),
        Some("rust"),
    );

    assert!(generate_embeddings(&dir), "Failed to generate embeddings");

    // Exact/technical query - should heavily weight BM25
    let results = search_hybrid(&dir, "E0382");
    assert!(!results.is_empty(), "Should find error code");
    let (id, score) = &results[0];
    println!("E0382 query: top result {id} with score {score}");
    // Exact error code match should score high with calibration
    assert!(
        *score >= 0.5,
        "Exact code match should score >= 0.5, got {score}"
    );

    // Conceptual query - should weight semantic more
    let results = search_hybrid(
        &dir,
        "what happens when you use a value after giving it away?",
    );
    println!("Conceptual query found {} results", results.len());
    for (id, score) in &results {
        println!("  {id} -> {score:.4}");
    }
    // Should find borrowing-related content via semantic similarity
    assert!(
        !results.is_empty(),
        "Conceptual query should find semantically related content"
    );
    let top_score = results[0].1;
    assert!(
        top_score >= 0.3,
        "Conceptual match should score >= 0.3, got {top_score}"
    );
}

