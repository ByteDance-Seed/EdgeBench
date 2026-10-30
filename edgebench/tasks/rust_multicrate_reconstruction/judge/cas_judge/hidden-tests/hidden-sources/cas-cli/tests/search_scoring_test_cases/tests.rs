#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_exact_keyword_match_scores_high() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    // Add memories with distinct keywords
    add_memory(
        &dir,
        "Rust borrow checker ensures memory safety without garbage collection",
        Some("Rust Borrow Checker"),
        Some("rust,programming"),
    );
    add_memory(
        &dir,
        "Python is great for data science and machine learning",
        Some("Python Data Science"),
        Some("python,ml"),
    );
    add_memory(
        &dir,
        "JavaScript async/await simplifies asynchronous programming",
        Some("JS Async"),
        Some("javascript,async"),
    );

    // Wait for index
    std::thread::sleep(std::time::Duration::from_millis(100));

    // Search for exact keyword
    let results = search_bm25(&dir, "rust borrow checker");

    // The exact match should be #1 with high score
    assert!(
        !results.is_empty(),
        "Should find results for 'rust borrow checker'"
    );

    let (_first_id, first_score) = &results[0];
    assert!(
        first_score >= &0.5,
        "Exact keyword match should score >= 0.5, got {first_score}"
    );
}

#[test]
#[ignore = "add/search CLI commands removed - tests need MCP fixtures"]
fn test_temporal_awareness() {
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    // Add memories (newer ones will have more recent timestamps)
    add_memory(
        &dir,
        "Old project setup from last year",
        Some("Old Setup"),
        Some("setup"),
    );
    std::thread::sleep(std::time::Duration::from_millis(50));
    add_memory(
        &dir,
        "Recent project configuration changes",
        Some("Recent Config"),
        Some("config"),
    );

    std::thread::sleep(std::time::Duration::from_millis(100));

    // This is more of a smoke test - temporal scoring depends on actual time differences
    let results = search_bm25(&dir, "project setup configuration");
    assert!(!results.is_empty(), "Should find project-related content");
}

#[test]
fn test_multi_channel_boost() {
    skip_without_embeddings!();
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    // Entry that matches both lexically AND semantically
    add_memory(
        &dir,
        "Rust async await programming with tokio for concurrent tasks",
        Some("Rust Async"),
        Some("rust,async"),
    );

    // Entry that only matches lexically
    add_memory(
        &dir,
        "The async keyword was introduced in Rust 1.39",
        Some("Async History"),
        Some("rust"),
    );

    // Entry that might only match semantically (concurrent, parallel)
    add_memory(
        &dir,
        "Parallel execution using threads and message passing",
        Some("Parallelism"),
        Some("concurrency"),
    );

    assert!(generate_embeddings(&dir), "Failed to generate embeddings");

    let results = search_hybrid(&dir, "async programming rust");

    // Should find at least the entries with "async" and "rust"
    assert!(!results.is_empty(), "Should find async/rust content");

    // Multi-channel match should score high (calibrated to meaningful range)
    let (_, first_score) = &results[0];
    assert!(
        *first_score >= 0.5,
        "Multi-channel match should score >= 0.5, got {first_score}"
    );
}

#[test]
fn test_semantic_score_calibration() {
    skip_without_embeddings!();
    let dir = TempDir::new().unwrap();
    init_cas(&dir);

    add_memory(
        &dir,
        "Implemented JWT authentication with refresh tokens",
        Some("Auth JWT"),
        Some("auth,security"),
    );
    add_memory(
        &dir,
        "Added OAuth2 provider integration for social login",
        Some("OAuth2"),
        Some("auth,oauth"),
    );
    add_memory(
        &dir,
        "User session management with Redis caching",
        Some("Sessions"),
        Some("auth,redis"),
    );
    add_memory(
        &dir,
        "Deployed new favicon and updated site logo",
        Some("Logo Update"),
        Some("ui"),
    );

    assert!(generate_embeddings(&dir), "Failed to generate embeddings");

    let results = search_hybrid(&dir, "authentication and login");

    // All scores should be in 0-1 range
    for (id, score) in &results {
        assert!(
            *score >= 0.0 && *score <= 1.0,
            "Score for {id} should be in [0, 1]: {score}"
        );
    }

    // Auth-related entries should score significantly higher than unrelated
    let auth_scores: Vec<f64> = results
        .iter()
        .filter(|(id, _)| id.contains("Auth") || id.contains("OAuth") || id.contains("Session"))
        .map(|(_, s)| *s)
        .collect();

    let unrelated_scores: Vec<f64> = results
        .iter()
        .filter(|(id, _)| id.contains("Logo"))
        .map(|(_, s)| *s)
        .collect();

    if !auth_scores.is_empty() && !unrelated_scores.is_empty() {
        let avg_auth = auth_scores.iter().sum::<f64>() / auth_scores.len() as f64;
        let avg_unrelated = unrelated_scores.iter().sum::<f64>() / unrelated_scores.len() as f64;

        assert!(
            avg_auth > avg_unrelated,
            "Auth content ({avg_auth}) should score higher than unrelated ({avg_unrelated})"
        );
    }
}
