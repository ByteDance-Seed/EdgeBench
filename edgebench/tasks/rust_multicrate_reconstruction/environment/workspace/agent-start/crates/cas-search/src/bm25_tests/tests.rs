use crate::bm25::*;
use std::collections::HashMap;

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

#[test]
fn test_index_and_search() {
    let index = Bm25Index::in_memory().unwrap();

    let doc1 = TestDoc::new("001", "Rust is a systems programming language");
    let doc2 = TestDoc::new("002", "Python is great for data science");
    let doc3 = TestDoc::new("003", "JavaScript runs in browsers");

    index.index(&doc1).unwrap();
    index.index(&doc2).unwrap();
    index.index(&doc3).unwrap();

    let results = index.search("programming", 10).unwrap();
    assert!(!results.is_empty());
    assert_eq!(results[0].0, "001");
}


#[test]
fn test_search_with_tags() {
    let index = Bm25Index::in_memory().unwrap();

    let doc1 = TestDoc::new("001", "Rust programming").with_tags(&["rust", "systems"]);
    let doc2 = TestDoc::new("002", "Python programming").with_tags(&["python", "data"]);
    let doc3 = TestDoc::new("003", "Rust async").with_tags(&["rust", "async"]);

    index.index(&doc1).unwrap();
    index.index(&doc2).unwrap();
    index.index(&doc3).unwrap();

    // Search with rust tag
    let results = index
        .search_with_tags("programming", &["rust"], 10)
        .unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].0, "001");
}

#[test]
fn test_delete() {
    let index = Bm25Index::in_memory().unwrap();

    let doc = TestDoc::new("001", "Rust programming");
    index.index(&doc).unwrap();

    assert!(index.exists("001").unwrap());

    index.remove("001").unwrap();

    assert!(!index.exists("001").unwrap());
}


#[test]
fn test_batch_delete() {
    let index = Bm25Index::in_memory().unwrap();

    let docs: Vec<TestDoc> = (0..10)
        .map(|i| TestDoc::new(&format!("doc-{i:03}"), &format!("Content {i}")))
        .collect();

    let doc_refs: Vec<&dyn SearchDocument> =
        docs.iter().map(|d| d as &dyn SearchDocument).collect();
    index.index_batch(doc_refs).unwrap();

    assert_eq!(index.num_docs().unwrap(), 10);

    // Delete half
    let ids_to_delete: Vec<&str> = (0..5).map(|i| docs[i].id.as_str()).collect();
    let deleted = index.delete_batch(ids_to_delete).unwrap();

    assert_eq!(deleted, 5);
    assert_eq!(index.num_docs().unwrap(), 5);
}

#[test]
fn test_rebuild_atomic_in_memory() {
    let index = Bm25Index::in_memory().unwrap();

    // Index initial docs
    let docs1: Vec<TestDoc> = (0..5)
        .map(|i| TestDoc::new(&format!("doc-{i}"), &format!("Old content {i}")))
        .collect();
    let refs1: Vec<&dyn SearchDocument> = docs1.iter().map(|d| d as &dyn SearchDocument).collect();
    index.index_batch(refs1).unwrap();

    assert_eq!(index.num_docs().unwrap(), 5);

    // Rebuild with new docs
    let docs2: Vec<TestDoc> = (0..10)
        .map(|i| TestDoc::new(&format!("new-{i}"), &format!("New content {i}")))
        .collect();
    let refs2: Vec<&dyn SearchDocument> = docs2.iter().map(|d| d as &dyn SearchDocument).collect();
    let count = index.rebuild_atomic(refs2).unwrap();

    assert_eq!(count, 10);
    assert_eq!(index.num_docs().unwrap(), 10);

    // Old docs should be gone
    assert!(!index.exists("doc-0").unwrap());
    // New docs should exist
    assert!(index.exists("new-0").unwrap());
}


#[test]
fn test_title_search() {
    let index = Bm25Index::in_memory().unwrap();

    let doc1 = TestDoc::new("001", "Body content only").with_title("Important Title");
    let doc2 = TestDoc::new("002", "Another body").with_title("Different");

    index.index(&doc1).unwrap();
    index.index(&doc2).unwrap();

    // Search by title
    let results = index.search("Important", 10).unwrap();
    assert!(!results.is_empty());
    assert_eq!(results[0].0, "001");
}

#[test]
fn test_empty_query() {
    let index = Bm25Index::in_memory().unwrap();

    let doc = TestDoc::new("001", "Content");
    index.index(&doc).unwrap();

    let results = index.search("", 10).unwrap();
    assert!(results.is_empty());

    let results = index.search("   ", 10).unwrap();
    assert!(results.is_empty());
}


#[test]
fn test_bm25_scoring() {
    let index = Bm25Index::in_memory().unwrap();

    // Doc with high term frequency should score higher
    let doc1 = TestDoc::new("001", "rust rust rust programming");
    let doc2 = TestDoc::new("002", "rust programming language guide");

    index.index(&doc1).unwrap();
    index.index(&doc2).unwrap();

    let results = index.search("rust", 10).unwrap();
    assert_eq!(results.len(), 2);

    // Higher TF should score higher
    assert_eq!(results[0].0, "001");
    assert!(results[0].1 > results[1].1);
}

#[test]
fn test_search_10k_documents() {
    let index = Bm25Index::in_memory().unwrap();

    // Create 10k documents
    let docs: Vec<TestDoc> = (0..10_000)
        .map(|i| {
            let content = if i % 100 == 0 {
                format!("Document {i} with special keyword searchterm")
            } else {
                format!("Document {i} with regular content")
            };
            TestDoc::new(&format!("doc-{i:05}"), &content)
        })
        .collect();

    let doc_refs: Vec<&dyn SearchDocument> =
        docs.iter().map(|d| d as &dyn SearchDocument).collect();

    let start = std::time::Instant::now();
    let count = index.index_batch(doc_refs).unwrap();
    let index_time = start.elapsed();

    assert_eq!(count, 10_000);
    println!("Indexed 10k docs in {index_time:?}");

    // Search should find ~100 documents (every 100th has the keyword)
    let start = std::time::Instant::now();
    let results = index.search("searchterm", 200).unwrap();
    let search_time = start.elapsed();

    assert_eq!(results.len(), 100);
    println!("Searched 10k docs in {search_time:?}");

    // Search should be fast (< 100ms)
    assert!(
        search_time.as_millis() < 100,
        "Search took too long: {search_time:?}"
    );
}

#[test]
fn test_concurrent_reads() {
    use std::sync::Arc;
    use std::thread;

    let index = Arc::new(Bm25Index::in_memory().unwrap());

    // Index some documents
    let docs: Vec<TestDoc> = (0..100)
        .map(|i| TestDoc::new(&format!("doc-{i}"), &format!("Content about rust {i}")))
        .collect();
    let doc_refs: Vec<&dyn SearchDocument> =
        docs.iter().map(|d| d as &dyn SearchDocument).collect();
    index.index_batch(doc_refs).unwrap();

    // Spawn multiple reader threads
    let handles: Vec<_> = (0..4)
        .map(|_| {
            let idx = Arc::clone(&index);
            thread::spawn(move || {
                for _ in 0..100 {
                    let results = idx.search("rust", 10).unwrap();
                    assert!(!results.is_empty());
                }
            })
        })
        .collect();

    for handle in handles {
        handle.join().unwrap();
    }
}

// =========================================================================
// Async tests (require `parallel` feature)
// =========================================================================

#[cfg(feature = "parallel")]
mod async_tests {
    use crate::bm25::tests::TestDoc;
    use crate::bm25::{AsyncBm25Index, Bm25Index};
    use crate::traits::{AsyncTextIndex, SearchDocument, TextIndex};

    #[tokio::test]
    async fn test_async_index_and_search() {
        let index = Bm25Index::in_memory().unwrap();
        let async_index = AsyncBm25Index::new(index);

        let doc1 = TestDoc::new("001", "Rust is a systems programming language");
        let doc2 = TestDoc::new("002", "Python is great for data science");
        let doc3 = TestDoc::new("003", "JavaScript runs in browsers");

        async_index.index_async(&doc1).await.unwrap();
        async_index.index_async(&doc2).await.unwrap();
        async_index.index_async(&doc3).await.unwrap();

        let results = async_index.search_async("programming", 10).await.unwrap();
        assert!(!results.is_empty());
        assert_eq!(results[0].0, "001");
    }

    #[tokio::test]
    async fn test_async_concurrent_searches() {
        let index = Bm25Index::in_memory().unwrap();

        // Index documents synchronously first
        let docs: Vec<TestDoc> = (0..100)
            .map(|i| TestDoc::new(&format!("doc-{}", i), &format!("Document about rust {}", i)))
            .collect();
        let doc_refs: Vec<&dyn SearchDocument> =
            docs.iter().map(|d| d as &dyn SearchDocument).collect();
        index.index_batch(doc_refs).unwrap();

        let async_index = AsyncBm25Index::new(index);

        // Run concurrent searches
        let idx1 = async_index.clone();
        let idx2 = async_index.clone();
        let idx3 = async_index.clone();

        let (r1, r2, r3) = tokio::join!(
            idx1.search_async("rust", 10),
            idx2.search_async("document", 10),
            idx3.search_async("about", 10)
        );

        assert!(!r1.unwrap().is_empty());
        assert!(!r2.unwrap().is_empty());
        assert!(!r3.unwrap().is_empty());
    }

    #[tokio::test]
    async fn test_async_search_with_type_filter() {
        let index = Bm25Index::in_memory().unwrap();

        let doc1 = TestDoc::new("001", "Rust programming").with_type("entry");
        let doc2 = TestDoc::new("002", "Python programming").with_type("task");

        index.index(&doc1).unwrap();
        index.index(&doc2).unwrap();

        let async_index = AsyncBm25Index::new(index);

        let results = async_index
            .search_with_type_async("programming", "entry", 10)
            .await
            .unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].0, "001");
    }

}
