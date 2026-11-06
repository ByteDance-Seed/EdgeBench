//! Integration tests for Hybrid Search
//!
//! Tests cover:
//! - BM25 search returning results
//! - Score normalization (0-1 range)
//! - Channel timeout handling
//! - Async search execution
//!
//! Note: Semantic search is now available via cloud API (premium feature).
//! Local hybrid search uses BM25 only.

use cas_search::{
    Bm25Index, HybridSearch, HybridSearchOptions, HybridSearchResult, SearchDocument, TextIndex,
    combine_weighted, normalize_min_max, reciprocal_rank_fusion,
};
use std::collections::HashMap;
use std::sync::Arc;
use std::time::Duration;

/// Test document implementing SearchDocument
struct TestDoc {
    id: String,
    content: String,
}

impl TestDoc {
    fn new(id: &str, content: &str) -> Self { todo!() }
}

impl SearchDocument for TestDoc {
    fn doc_id(&self) -> &str { todo!() }

    fn doc_content(&self) -> &str { todo!() }

    fn doc_type(&self) -> &str { todo!() }

    fn doc_tags(&self) -> Vec<&str> { todo!() }

    fn doc_metadata(&self) -> HashMap<String, String> { todo!() }
}

// =============================================================================
// Hybrid Search Tests (BM25-only)
// =============================================================================

/// Test: BM25 search returns results
#[test]
fn test_hybrid_bm25_search() {
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());

    // Create documents
    let docs = vec![
        TestDoc::new("doc-1", "Rust systems programming language memory safety"),
        TestDoc::new("doc-2", "Python data science machine learning"),
        TestDoc::new("doc-3", "JavaScript web frontend development"),
        TestDoc::new("doc-4", "Rust async programming tokio runtime"),
    ];

    // Index in BM25
    for doc in &docs {
        bm25_index.index(doc).unwrap();
    }

    // Create hybrid search (BM25 only)
    let search = HybridSearch::new(bm25_index);

    // Semantic is not available locally
    assert!(!search.has_semantic());

    // Search
    let opts = HybridSearchOptions {
        query: "Rust programming".to_string(),
        limit: 10,
        ..Default::default()
    };

    let results = search.search(&opts).unwrap();
    assert!(!results.is_empty(), "Should find results");

    // Verify BM25 contributed
    let has_bm25_contribution = results.iter().any(|r| r.bm25_score > 0.0);
    assert!(
        has_bm25_contribution,
        "BM25 channel should contribute to results"
    );

    // Semantic score should always be 0 (cloud-only)
    for result in &results {
        assert_eq!(result.semantic_score, 0.0, "Semantic score should be 0");
    }

    // First result should be rust-related
    assert!(
        results[0].id == "doc-1" || results[0].id == "doc-4",
        "Top result should be a Rust document"
    );
}

/// Test: Scoring is normalized (0-1 range)
#[test]
fn test_hybrid_scores_normalized() {
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());

    // Create documents with varied content
    let docs: Vec<TestDoc> = (0..50)
        .map(|i| {
            TestDoc::new(
                &format!("doc-{i:02}"),
                &format!("Document {} about programming and software {}", i, i * 10),
            )
        })
        .collect();

    // Index in BM25
    for doc in &docs {
        bm25_index.index(doc).unwrap();
    }

    let search = HybridSearch::new(bm25_index);

    let opts = HybridSearchOptions {
        query: "programming software".to_string(),
        limit: 20,
        ..Default::default()
    };

    let results = search.search(&opts).unwrap();
    assert!(!results.is_empty());

    // Check score ranges
    for result in &results {
        // BM25 score should be non-negative
        assert!(
            result.bm25_score >= 0.0,
            "BM25 score {} should be >= 0",
            result.bm25_score
        );

        // Semantic score is always 0
        assert_eq!(result.semantic_score, 0.0);

        // Combined score should be positive for found documents
        assert!(
            result.score >= 0.0,
            "Combined score {} should be >= 0",
            result.score
        );
    }

    // Results should be sorted by combined score descending
    for i in 1..results.len() {
        assert!(
            results[i - 1].score >= results[i].score,
            "Results should be sorted by score descending"
        );
    }
}

/// Test: Empty query returns empty results

/// Test: HybridSearchResult structure
#[test]
fn test_hybrid_search_result_structure() {
    let result = HybridSearchResult {
        id: "test-doc".to_string(),
        score: 0.85,
        bm25_score: 0.85,
        semantic_score: 0.0,
    };

    assert_eq!(result.id, "test-doc");
    assert_eq!(result.score, 0.85);
    assert_eq!(result.bm25_score, 0.85);
    assert_eq!(result.semantic_score, 0.0);

    // Test Clone
    let cloned = result.clone();
    assert_eq!(cloned.id, result.id);
    assert_eq!(cloned.score, result.score);

    // Test Debug
    let debug_str = format!("{result:?}");
    assert!(debug_str.contains("test-doc"));
}

/// Test: HybridSearchOptions defaults
#[test]
fn test_hybrid_search_options_defaults() {
    let opts = HybridSearchOptions::default();

    assert!(opts.query.is_empty());
    assert_eq!(opts.limit, 10);
    assert!(opts.doc_type.is_none());
    assert!(opts.tags.is_empty());
    assert!(!opts.enable_semantic); // Disabled by default (cloud-only)
    assert_eq!(opts.bm25_weight, 1.0);
    assert_eq!(opts.semantic_weight, 0.0);
    assert!(!opts.use_rrf);
    assert_eq!(opts.rrf_k, 60.0);
    assert_eq!(opts.channel_timeout, Duration::from_secs(5));
}

// =============================================================================
// Scorer utility tests (part of hybrid search infrastructure)
// =============================================================================

/// Test: Score normalization produces 0-1 range
#[test]
fn test_score_normalization_range() {
    let scores = vec![
        ("a".to_string(), 100.0),
        ("b".to_string(), 50.0),
        ("c".to_string(), 10.0),
        ("d".to_string(), 0.0),
    ];

    let normalized = normalize_min_max(&scores);

    for (id, score) in &normalized {
        assert!(
            *score >= 0.0 && *score <= 1.0,
            "Normalized score {score} for {id} should be in [0, 1]"
        );
    }

    // Max should be 1.0
    let max = normalized
        .iter()
        .find(|(id, _)| id == "a")
        .map(|(_, s)| *s)
        .unwrap();
    assert!((max - 1.0).abs() < 1e-6);

    // Min should be 0.0
    let min = normalized
        .iter()
        .find(|(id, _)| id == "d")
        .map(|(_, s)| *s)
        .unwrap();
    assert!((min - 0.0).abs() < 1e-6);
}

/// Test: combine_weighted merges results from multiple channels
#[test]
fn test_combine_weighted_merges_channels() {
    let bm25_scores = vec![
        ("doc-1".to_string(), 1.0),
        ("doc-2".to_string(), 0.5),
        ("doc-3".to_string(), 0.2),
    ];

    let semantic_scores = vec![
        ("doc-2".to_string(), 0.9),
        ("doc-4".to_string(), 0.8),
        ("doc-1".to_string(), 0.3),
    ];

    let combined = combine_weighted(&bm25_scores, &semantic_scores, 0.5, 0.5);

    // Should include all unique documents
    assert_eq!(combined.len(), 4);

    // Documents in both lists should have contributions from both
    let doc2 = combined.iter().find(|(id, _)| id == "doc-2").unwrap();
    assert!(doc2.1 > 0.0);

    // Results should be sorted by score descending
    for i in 1..combined.len() {
        assert!(combined[i - 1].1 >= combined[i].1);
    }
}

/// Test: RRF combines rankings without score normalization

// =============================================================================
// Async tests (require `parallel` feature)
// =============================================================================

#[cfg(feature = "parallel")]
mod async_tests {
    use std::sync::Arc;
    use std::time::Duration;

    use cas_search::{Bm25Index, HybridSearch, HybridSearchOptions, TextIndex};

    use crate::TestDoc;


    #[tokio::test]
    async fn test_async_concurrent_searches() {
        let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());

        // Create more documents
        let docs: Vec<TestDoc> = (0..100)
            .map(|i| {
                TestDoc::new(
                    &format!("doc-{:03}", i),
                    &format!("Document {} about programming topics {}", i, i * 7),
                )
            })
            .collect();

        for doc in &docs {
            bm25_index.index(doc).unwrap();
        }

        let search = HybridSearch::new(bm25_index);

        let opts = HybridSearchOptions {
            query: "programming".to_string(),
            limit: 20,
            ..Default::default()
        };

        // Run multiple concurrent searches
        let (r1, r2, r3) = tokio::join!(
            search.search_async(&opts),
            search.search_async(&opts),
            search.search_async(&opts)
        );

        assert!(r1.is_ok());
        assert!(r2.is_ok());
        assert!(r3.is_ok());

        // All should return same results
        assert_eq!(r1.unwrap().len(), r2.unwrap().len());
    }

    #[tokio::test]
    async fn test_async_channel_timeout() {
        let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());

        let doc = TestDoc::new("1", "Test content");
        bm25_index.index(&doc).unwrap();

        let search = HybridSearch::new(bm25_index);

        let opts = HybridSearchOptions {
            query: "test".to_string(),
            limit: 10,
            channel_timeout: Duration::from_millis(100), // Short timeout
            ..Default::default()
        };

        // Should complete without hanging
        let start = std::time::Instant::now();
        let results = search.search_async(&opts).await.unwrap();
        let elapsed = start.elapsed();

        assert!(!results.is_empty());
        assert!(elapsed < Duration::from_secs(1), "Should complete quickly");
    }
}
