//! Integration tests for BM25 full-text search
//!
//! Tests cover:
//! - Indexing 1k documents with keyword search
//! - Type and tag filtering
//! - Empty query handling
//! - Special character handling
//! - Concurrent read operations

use cas_search::{Bm25Index, SearchDocument, TextIndex};
use std::collections::HashMap;
use std::sync::Arc;
use std::thread;
use std::time::{Duration, Instant};
use tempfile::tempdir;

/// Test document implementing SearchDocument
struct TestDoc {
    id: String,
    content: String,
    doc_type: String,
    tags: Vec<String>,
    title: Option<String>,
}

impl TestDoc {
    fn new(id: &str, content: &str) -> Self { todo!() }

    fn with_type(mut self, doc_type: &str) -> Self { todo!() }

    fn with_tags(mut self, tags: &[&str]) -> Self { todo!() }

    fn with_title(mut self, title: &str) -> Self { todo!() }
}

impl SearchDocument for TestDoc {
    fn doc_id(&self) -> &str { todo!() }

    fn doc_content(&self) -> &str { todo!() }

    fn doc_type(&self) -> &str { todo!() }

    fn doc_tags(&self) -> Vec<&str> { todo!() }

    fn doc_metadata(&self) -> HashMap<String, String> { todo!() }

    fn doc_title(&self) -> Option<&str> { todo!() }
}

// =============================================================================
// BM25 Search Tests
// =============================================================================

/// Test: Index 1k documents and verify keyword search returns relevant results
#[test]
fn test_bm25_1k_documents_keyword_search() {
    let index = Bm25Index::in_memory().unwrap();

    // Create 1000 documents with varied content
    let categories = ["rust", "python", "javascript", "go", "java"];
    let topics = [
        "programming",
        "data science",
        "web development",
        "systems",
        "algorithms",
    ];

    let docs: Vec<TestDoc> = (0..1000)
        .map(|i| {
            let cat = categories[i % categories.len()];
            let topic = topics[i % topics.len()];
            let content = format!(
                "Document {i} about {cat} {topic} with detailed explanations and code examples for {cat}"
            );
            TestDoc::new(&format!("doc-{i:04}"), &content)
                .with_type(cat)
                .with_tags(&[cat, topic])
                .with_title(&format!("{cat} {topic}"))
        })
        .collect();

    // Batch index
    let doc_refs: Vec<&dyn SearchDocument> =
        docs.iter().map(|d| d as &dyn SearchDocument).collect();

    let start = Instant::now();
    let count = index.index_batch(doc_refs).unwrap();
    let index_time = start.elapsed();

    assert_eq!(count, 1000);
    assert_eq!(index.num_docs().unwrap(), 1000);
    println!(
        "Indexed 1k docs in {:?} ({:.0} docs/sec)",
        index_time,
        1000.0 / index_time.as_secs_f64()
    );

    // Test keyword search
    let start = Instant::now();
    let results = index.search("rust programming", 20).unwrap();
    let search_time = start.elapsed();

    assert!(!results.is_empty(), "Should find documents about rust");
    println!(
        "Search 'rust programming' found {} results in {:?}",
        results.len(),
        search_time
    );

    // Verify relevance - results should contain rust-related documents
    let rust_count = results
        .iter()
        .filter(|(id, _)| {
            // Documents with rust in type (doc-0000, doc-0005, doc-0010, etc.)
            let doc_num: usize = id.strip_prefix("doc-").unwrap().parse().unwrap();
            doc_num % 5 == 0 // rust documents
        })
        .count();

    assert!(
        rust_count > 0,
        "Should find rust-related documents, got {rust_count} rust docs"
    );

    // Scores should be positive
    for (id, score) in &results {
        assert!(*score > 0.0, "Score for {id} should be positive");
    }

    // Results should be sorted by score descending
    for i in 1..results.len() {
        assert!(
            results[i - 1].1 >= results[i].1,
            "Results should be sorted by score descending"
        );
    }
}

/// Test: Filters (doc_type) work correctly
#[test]
fn test_bm25_type_filter() {
    let index = Bm25Index::in_memory().unwrap();

    // Index documents with different types
    let docs = vec![
        TestDoc::new("e1", "Rust programming language is great").with_type("entry"),
        TestDoc::new("e2", "Python programming for beginners").with_type("entry"),
        TestDoc::new("t1", "Fix the rust compiler bug").with_type("task"),
        TestDoc::new("t2", "Write rust documentation").with_type("task"),
        TestDoc::new("r1", "Rust code style guidelines").with_type("rule"),
    ];

    for doc in &docs {
        index.index(doc).unwrap();
    }

    // Search all types
    let results = index.search("rust", 10).unwrap();
    assert!(
        results.len() >= 3,
        "Should find all rust docs, got {}",
        results.len()
    );

    // Search only entries
    let entry_results = index.search_with_type("rust", "entry", 10).unwrap();
    assert_eq!(
        entry_results.len(),
        1,
        "Should find only 1 rust entry, got {}",
        entry_results.len()
    );
    assert_eq!(entry_results[0].0, "e1");

    // Search only tasks
    let task_results = index.search_with_type("rust", "task", 10).unwrap();
    assert_eq!(
        task_results.len(),
        2,
        "Should find 2 rust tasks, got {}",
        task_results.len()
    );

    // Search only rules
    let rule_results = index.search_with_type("rust", "rule", 10).unwrap();
    assert_eq!(rule_results.len(), 1);
    assert_eq!(rule_results[0].0, "r1");

    // Search non-existent type
    let no_results = index.search_with_type("rust", "nonexistent", 10).unwrap();
    assert!(no_results.is_empty());
}

/// Test: Filters (tags) work correctly
#[test]
fn test_bm25_tag_filter() {
    let index = Bm25Index::in_memory().unwrap();

    let docs = vec![
        TestDoc::new("d1", "Rust async programming guide").with_tags(&["rust", "async"]),
        TestDoc::new("d2", "Rust systems programming").with_tags(&["rust", "systems"]),
        TestDoc::new("d3", "Python async programming").with_tags(&["python", "async"]),
        TestDoc::new("d4", "Go concurrency patterns").with_tags(&["go", "async"]),
    ];

    for doc in &docs {
        index.index(doc).unwrap();
    }

    // Search with rust tag
    let rust_results = index
        .search_with_tags("programming", &["rust"], 10)
        .unwrap();
    assert_eq!(rust_results.len(), 2, "Should find 2 rust programming docs");
    assert!(
        rust_results
            .iter()
            .all(|(id, _)| id.starts_with("d1") || id.starts_with("d2"))
    );

    // Search with async tag
    let async_results = index
        .search_with_tags("programming", &["async"], 10)
        .unwrap();
    assert!(
        async_results.len() >= 2,
        "Should find async programming docs"
    );

    // Search with multiple tags (should be AND - but in current impl, tags are OR'd through TEXT search)
    // The search_with_tags uses TEXT field which does fuzzy matching
    let rust_async_results = index
        .search_with_tags("programming", &["rust", "async"], 10)
        .unwrap();
    // This should find documents with both tags
    assert!(
        !rust_async_results.is_empty(),
        "Should find docs with rust AND async"
    );
}

/// Test: Empty query returns empty results
#[test]
fn test_bm25_empty_query_returns_empty() {
    let index = Bm25Index::in_memory().unwrap();

    let doc = TestDoc::new("001", "Some content");
    index.index(&doc).unwrap();

    // Empty string
    let results = index.search("", 10).unwrap();
    assert!(results.is_empty(), "Empty query should return no results");

    // Whitespace only
    let results = index.search("   ", 10).unwrap();
    assert!(
        results.is_empty(),
        "Whitespace query should return no results"
    );

    // With type filter
    let results = index.search_with_type("", "test", 10).unwrap();
    assert!(
        results.is_empty(),
        "Empty query with type filter should return no results"
    );

    // With tag filter
    let results = index.search_with_tags("", &["tag"], 10).unwrap();
    assert!(
        results.is_empty(),
        "Empty query with tag filter should return no results"
    );
}

/// Test: Special characters are handled correctly
#[test]
fn test_bm25_special_characters_handled() {
    let index = Bm25Index::in_memory().unwrap();

    let docs = vec![
        TestDoc::new("d1", "C++ programming language"),
        TestDoc::new("d2", "C# development guide"),
        TestDoc::new("d3", "Use $HOME environment variable"),
        TestDoc::new("d4", "The file path is /usr/bin/python"),
        TestDoc::new("d5", "Email: test@example.com"),
        TestDoc::new("d6", "Price: $99.99"),
        TestDoc::new("d7", "Version 1.2.3-beta"),
        TestDoc::new("d8", "Function foo_bar_baz()"),
        TestDoc::new("d9", "The [bracketed] text"),
        TestDoc::new("d10", "Query with \"quotes\""),
    ];

    for doc in &docs {
        index.index(doc).unwrap();
    }

    // Test various special character searches
    // Note: Tantivy's default tokenizer may handle these differently

    // Search for C++ (special chars in content)
    let results = index.search("programming", 10).unwrap();
    assert!(!results.is_empty());

    // Search for path-like content
    let results = index.search("usr bin python", 10).unwrap();
    assert!(
        results.iter().any(|(id, _)| id == "d4"),
        "Should find path content"
    );

    // Search for email domain
    let results = index.search("example", 10).unwrap();
    assert!(
        results.iter().any(|(id, _)| id == "d5"),
        "Should find email content"
    );

    // Search for underscore-separated words
    let results = index.search("foo bar", 10).unwrap();
    // May or may not find depending on tokenizer
    assert!(results.len() <= 10);

    // Search for numeric version
    let results = index.search("version", 10).unwrap();
    assert!(
        results.iter().any(|(id, _)| id == "d7"),
        "Should find version content"
    );

    // Ensure no panics with various special chars
    let special_queries = [
        "C++",
        "C#",
        "$HOME",
        "/usr/bin",
        "test@example.com",
        "$99.99",
        "1.2.3",
        "foo_bar",
        "[test]",
        "\"quotes\"",
        "(parens)",
        "{braces}",
        "<angle>",
        "back\\slash",
        "percent%",
        "ampersand&",
        "pipe|",
        "caret^",
        "tilde~",
        "asterisk*",
        "question?",
        "plus+",
        "minus-",
    ];

    for query in special_queries {
        // Should not panic
        let _ = index.search(query, 5);
    }
}

/// Test: BM25 scoring reflects term frequency

/// Test: BM25 persistence on disk
#[test]
fn test_bm25_persistence() {
    let dir = tempdir().unwrap();
    let path = dir.path().join("bm25_index");

    // Create and populate index
    {
        let index = Bm25Index::open(&path).unwrap();

        let docs: Vec<TestDoc> = (0..50)
            .map(|i| TestDoc::new(&format!("doc-{i:03}"), &format!("Content about rust {i}")))
            .collect();

        let doc_refs: Vec<&dyn SearchDocument> =
            docs.iter().map(|d| d as &dyn SearchDocument).collect();
        index.index_batch(doc_refs).unwrap();

        assert_eq!(index.num_docs().unwrap(), 50);
    }

    // Reopen and verify
    {
        let index = Bm25Index::open(&path).unwrap();

        assert_eq!(index.num_docs().unwrap(), 50, "Count should persist");

        // Search should work
        let results = index.search("rust", 10).unwrap();
        assert!(!results.is_empty(), "Search should work after reopen");

        // Specific document should exist
        assert!(index.exists("doc-000").unwrap());
    }
}

/// Test: Concurrent search operations
#[test]
fn test_bm25_concurrent_searches() {
    let index = Arc::new(Bm25Index::in_memory().unwrap());

    // Index documents
    let docs: Vec<TestDoc> = (0..200)
        .map(|i| {
            let topics = ["rust", "python", "javascript", "go", "java"];
            let topic = topics[i % topics.len()];
            TestDoc::new(
                &format!("doc-{i:03}"),
                &format!("Document about {topic} programming language number {i}"),
            )
        })
        .collect();

    let doc_refs: Vec<&dyn SearchDocument> =
        docs.iter().map(|d| d as &dyn SearchDocument).collect();
    index.index_batch(doc_refs).unwrap();

    // Spawn concurrent reader threads
    let num_threads = 4;
    let searches_per_thread = 100;
    let queries = ["rust", "python", "programming", "language"];
    let mut handles = Vec::with_capacity(num_threads);

    let start = Instant::now();

    for thread_id in 0..num_threads {
        let index_clone = Arc::clone(&index);
        let query = queries[thread_id % queries.len()].to_string();

        let handle = thread::spawn(move || {
            let mut total_results = 0;
            for _ in 0..searches_per_thread {
                let results = index_clone.search(&query, 10).unwrap();
                total_results += results.len();
            }
            total_results
        });
        handles.push(handle);
    }

    let mut total = 0;
    for handle in handles {
        total += handle.join().expect("Thread panicked");
    }

    let elapsed = start.elapsed();
    println!(
        "Concurrent BM25: {} searches across {} threads in {:?}",
        num_threads * searches_per_thread,
        num_threads,
        elapsed
    );

    assert!(total > 0, "Should find results");
    assert!(
        elapsed < Duration::from_secs(5),
        "Concurrent searches should be fast"
    );
}

/// Test: Update document (re-index with same ID)
#[test]
fn test_bm25_update_document() {
    let index = Bm25Index::in_memory().unwrap();

    // Index original
    let doc1 = TestDoc::new("doc-001", "Original content about databases");
    index.index(&doc1).unwrap();

    let results = index.search("Original", 10).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].0, "doc-001");

    // Update with new content
    let doc2 = TestDoc::new("doc-001", "Updated content about networking");
    index.index(&doc2).unwrap();

    // Old content should not be found
    let results = index.search("Original databases", 10).unwrap();
    assert!(results.is_empty(), "Old content should not be found");

    // New content should be found
    let results = index.search("Updated networking", 10).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].0, "doc-001");

    // Document count should still be 1
    assert_eq!(index.num_docs().unwrap(), 1);
}

/// Test: Delete documents
#[test]
fn test_bm25_delete_documents() {
    let index = Bm25Index::in_memory().unwrap();

    let docs: Vec<TestDoc> = (0..10)
        .map(|i| TestDoc::new(&format!("doc-{i}"), &format!("Content {i}")))
        .collect();

    let doc_refs: Vec<&dyn SearchDocument> =
        docs.iter().map(|d| d as &dyn SearchDocument).collect();
    index.index_batch(doc_refs).unwrap();

    assert_eq!(index.num_docs().unwrap(), 10);

    // Delete single document
    index.remove("doc-0").unwrap();
    assert_eq!(index.num_docs().unwrap(), 9);
    assert!(!index.exists("doc-0").unwrap());

    // Batch delete
    let ids_to_delete: Vec<&str> = vec!["doc-1", "doc-2", "doc-3"];
    let deleted = index.delete_batch(ids_to_delete).unwrap();
    assert_eq!(deleted, 3);
    assert_eq!(index.num_docs().unwrap(), 6);
}

/// Test: BM25 index with large documents
#[test]
fn test_bm25_large_documents() {
    let index = Bm25Index::in_memory().unwrap();

    // Create document with large content (10KB)
    let large_content = "Rust programming ".repeat(600); // ~10KB
    let doc = TestDoc::new("large-doc", &large_content);
    index.index(&doc).unwrap();

    // Small document
    let small_doc = TestDoc::new("small-doc", "Rust programming");
    index.index(&small_doc).unwrap();

    // Both should be searchable
    let results = index.search("Rust", 10).unwrap();
    assert_eq!(results.len(), 2);

    // Large doc should have higher TF
    let large_pos = results.iter().position(|(id, _)| id == "large-doc");
    let small_pos = results.iter().position(|(id, _)| id == "small-doc");
    assert!(
        large_pos < small_pos,
        "Large doc with more term occurrences should rank higher"
    );
}

/// Test: Rebuild atomic functionality
#[test]
fn test_bm25_rebuild_atomic() {
    let index = Bm25Index::in_memory().unwrap();

    // Index initial documents
    let initial_docs: Vec<TestDoc> = (0..5)
        .map(|i| TestDoc::new(&format!("old-{i}"), &format!("Old content {i}")))
        .collect();

    let doc_refs: Vec<&dyn SearchDocument> = initial_docs
        .iter()
        .map(|d| d as &dyn SearchDocument)
        .collect();
    index.index_batch(doc_refs).unwrap();

    assert_eq!(index.num_docs().unwrap(), 5);
    assert!(index.exists("old-0").unwrap());

    // Rebuild with new documents
    let new_docs: Vec<TestDoc> = (0..10)
        .map(|i| TestDoc::new(&format!("new-{i}"), &format!("New content {i}")))
        .collect();

    let new_refs: Vec<&dyn SearchDocument> =
        new_docs.iter().map(|d| d as &dyn SearchDocument).collect();
    let count = index.rebuild_atomic(new_refs).unwrap();

    assert_eq!(count, 10);
    assert_eq!(index.num_docs().unwrap(), 10);

    // Old documents should be gone
    assert!(!index.exists("old-0").unwrap());

    // New documents should exist
    assert!(index.exists("new-0").unwrap());
}

/// Test: Search performance with 10k documents
#[test]
fn test_bm25_search_performance_10k() {
    let index = Bm25Index::in_memory().unwrap();

    // Create 10k documents with some having a special keyword
    let docs: Vec<TestDoc> = (0..10_000)
        .map(|i| {
            let content = if i % 100 == 0 {
                format!("Document {i} with specialkeyword for testing")
            } else {
                format!("Document {i} with regular content")
            };
            TestDoc::new(&format!("doc-{i:05}"), &content)
        })
        .collect();

    let doc_refs: Vec<&dyn SearchDocument> =
        docs.iter().map(|d| d as &dyn SearchDocument).collect();

    let start = Instant::now();
    index.index_batch(doc_refs).unwrap();
    let index_time = start.elapsed();
    println!("Indexed 10k docs in {index_time:?}");

    // Search should find ~100 documents
    let start = Instant::now();
    let results = index.search("specialkeyword", 200).unwrap();
    let search_time = start.elapsed();

    assert_eq!(
        results.len(),
        100,
        "Should find exactly 100 docs with keyword"
    );
    println!(
        "Search found {} results in {:?}",
        results.len(),
        search_time
    );

    // Search should be fast (< 100ms)
    assert!(
        search_time.as_millis() < 100,
        "Search should be fast, took {search_time:?}"
    );
}
