#[test]
fn test_search_with_type_filter() {
    let index = Bm25Index::in_memory().unwrap();

    let doc1 = TestDoc::new("001", "Rust programming").with_type("entry");
    let doc2 = TestDoc::new("002", "Python programming").with_type("task");
    let doc3 = TestDoc::new("003", "Go programming").with_type("entry");

    index.index(&doc1).unwrap();
    index.index(&doc2).unwrap();
    index.index(&doc3).unwrap();

    // Search all types
    let results = index.search("programming", 10).unwrap();
    assert_eq!(results.len(), 3);

    // Search only entries
    let results = index.search_with_type("programming", "entry", 10).unwrap();
    assert_eq!(results.len(), 2);

    // Search only tasks
    let results = index.search_with_type("programming", "task", 10).unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].0, "002");
}

#[test]
fn test_batch_index() {
    let index = Bm25Index::in_memory().unwrap();

    let docs: Vec<TestDoc> = (0..100)
        .map(|i| TestDoc::new(&format!("doc-{i:03}"), &format!("Document content {i}")))
        .collect();

    let doc_refs: Vec<&dyn SearchDocument> =
        docs.iter().map(|d| d as &dyn SearchDocument).collect();

    let count = index.index_batch(doc_refs).unwrap();
    assert_eq!(count, 100);
    assert_eq!(index.num_docs().unwrap(), 100);
}

#[test]
fn test_rebuild_atomic_disk() {
    let temp_dir = tempfile::tempdir().unwrap();
    let index_path = temp_dir.path().join("bm25_index");

    let index = Bm25Index::open(&index_path).unwrap();

    // Index initial docs
    let docs1: Vec<TestDoc> = (0..5)
        .map(|i| TestDoc::new(&format!("doc-{i}"), &format!("Old content {i}")))
        .collect();
    let refs1: Vec<&dyn SearchDocument> = docs1.iter().map(|d| d as &dyn SearchDocument).collect();
    index.index_batch(refs1).unwrap();

    // Rebuild with new docs
    let docs2: Vec<TestDoc> = (0..10)
        .map(|i| TestDoc::new(&format!("new-{i}"), &format!("New content {i}")))
        .collect();
    let refs2: Vec<&dyn SearchDocument> = docs2.iter().map(|d| d as &dyn SearchDocument).collect();
    let count = index.rebuild_atomic(refs2).unwrap();

    assert_eq!(count, 10);

    // Reopen index to verify persistence
    drop(index);
    let index = Bm25Index::open(&index_path).unwrap();

    assert_eq!(index.num_docs().unwrap(), 10);
    assert!(!index.exists("doc-0").unwrap());
    assert!(index.exists("new-0").unwrap());
}

#[test]
fn test_update_document() {
    let index = Bm25Index::in_memory().unwrap();

    let doc1 = TestDoc::new("001", "Original content");
    index.index(&doc1).unwrap();

    let results = index.search("Original", 10).unwrap();
    assert_eq!(results.len(), 1);

    // Update with new content
    let doc2 = TestDoc::new("001", "Updated content");
    index.index(&doc2).unwrap();

    // Old content no longer found
    let results = index.search("Original", 10).unwrap();
    assert!(results.is_empty());

    // New content found
    let results = index.search("Updated", 10).unwrap();
    assert_eq!(results.len(), 1);
}

    #[tokio::test]
    async fn test_async_remove() {
        let index = Bm25Index::in_memory().unwrap();
        let doc = TestDoc::new("001", "Content to remove");
        index.index(&doc).unwrap();

        let async_index = AsyncBm25Index::new(index);

        // Verify it exists
        let results = async_index.search_async("remove", 10).await.unwrap();
        assert_eq!(results.len(), 1);

        // Remove it
        async_index.remove_async("001").await.unwrap();

        // Verify it's gone
        let results = async_index.search_async("remove", 10).await.unwrap();
        assert!(results.is_empty());
    }
