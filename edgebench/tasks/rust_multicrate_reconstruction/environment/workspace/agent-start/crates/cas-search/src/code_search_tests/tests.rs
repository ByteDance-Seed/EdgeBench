use crate::code_search::*;
use std::sync::atomic::{AtomicUsize, Ordering};

/// Mock CodeStore that tracks batch vs single symbol fetches
struct MockCodeStore {
    symbols: HashMap<String, CodeSymbol>,
    single_fetch_count: AtomicUsize,
    batch_fetch_count: AtomicUsize,
}

impl MockCodeStore {
    fn new() -> Self { todo!() }

    fn insert_symbol(&mut self, symbol: CodeSymbol) { todo!() }

    fn single_fetches(&self) -> usize { todo!() }

    fn batch_fetches(&self) -> usize { todo!() }
}

impl CodeStore for MockCodeStore {
    fn init(&self) -> cas_store::error::Result<()> { todo!() }
    fn generate_file_id(&self) -> cas_store::error::Result<String> { todo!() }
    fn generate_file_id_for(&self, _: &str, _: &str) -> String { todo!() }
    fn add_file(&self, _: &cas_code::CodeFile) -> cas_store::error::Result<()> { todo!() }
    fn get_file(&self, _: &str) -> cas_store::error::Result<cas_code::CodeFile> { todo!() }
    fn get_file_by_path(
        &self,
        _: &str,
        _: &str,
    ) -> cas_store::error::Result<Option<cas_code::CodeFile>> { todo!() }
    fn list_files(
        &self,
        _: &str,
        _: Option<Language>,
    ) -> cas_store::error::Result<Vec<cas_code::CodeFile>> { todo!() }
    fn delete_file(&self, _: &str) -> cas_store::error::Result<()> { todo!() }
    fn generate_symbol_id(&self) -> cas_store::error::Result<String> { todo!() }
    fn generate_symbol_id_for(&self, _: &str, _: &str, _: &str) -> String { todo!() }
    fn add_symbol(&self, _: &CodeSymbol) -> cas_store::error::Result<()> { todo!() }

    fn get_symbol(&self, id: &str) -> cas_store::error::Result<CodeSymbol> { todo!() }

    fn get_symbols_by_name(&self, name: &str) -> cas_store::error::Result<Vec<CodeSymbol>> { todo!() }
    fn get_symbols_in_file(&self, _: &str) -> cas_store::error::Result<Vec<CodeSymbol>> { todo!() }
    fn search_symbols(
        &self,
        _: &str,
        _: Option<SymbolKind>,
        _: Option<Language>,
        _: usize,
    ) -> cas_store::error::Result<Vec<CodeSymbol>> { todo!() }
    fn search_symbols_paginated(
        &self,
        _: &str,
        _: Option<SymbolKind>,
        _: Option<Language>,
        limit: usize,
        offset: usize,
    ) -> cas_store::error::Result<Vec<CodeSymbol>> { todo!() }
    fn delete_symbol(&self, _: &str) -> cas_store::error::Result<()> { todo!() }
    fn delete_symbols_in_file(&self, _: &str) -> cas_store::error::Result<()> { todo!() }
    fn generate_relationship_id(&self) -> cas_store::error::Result<String> { todo!() }
    fn add_relationship(&self, _: &cas_code::CodeRelationship) -> cas_store::error::Result<()> { todo!() }
    fn get_callers(&self, _: &str) -> cas_store::error::Result<Vec<CodeSymbol>> { todo!() }
    fn get_callees(&self, _: &str) -> cas_store::error::Result<Vec<CodeSymbol>> { todo!() }
    fn get_relationships_from(
        &self,
        _: &str,
    ) -> cas_store::error::Result<Vec<cas_code::CodeRelationship>> { todo!() }
    fn get_relationships_to(
        &self,
        _: &str,
    ) -> cas_store::error::Result<Vec<cas_code::CodeRelationship>> { todo!() }
    fn delete_relationships_for_symbol(&self, _: &str) -> cas_store::error::Result<()> { todo!() }
    fn link_to_memory(&self, _: &cas_code::CodeMemoryLink) -> cas_store::error::Result<()> { todo!() }
    fn get_linked_memories(&self, _: &str) -> cas_store::error::Result<Vec<String>> { todo!() }
    fn get_linked_code(&self, _: &str) -> cas_store::error::Result<Vec<String>> { todo!() }
    fn get_memory_links(&self, _: &str) -> cas_store::error::Result<Vec<cas_code::CodeMemoryLink>> { todo!() }
    fn delete_memory_link(
        &self,
        _: &str,
        _: &str,
        _: cas_code::CodeMemoryLinkType,
    ) -> cas_store::error::Result<()> { todo!() }
    fn delete_memory_links_for_code(&self, _: &str) -> cas_store::error::Result<()> { todo!() }
    fn add_symbols_batch(&self, _: &[CodeSymbol]) -> cas_store::error::Result<()> { todo!() }
    fn add_relationships_batch(
        &self,
        _: &[cas_code::CodeRelationship],
    ) -> cas_store::error::Result<()> { todo!() }

    fn get_symbols_batch(&self, ids: &[&str]) -> cas_store::error::Result<Vec<CodeSymbol>> { todo!() }

    fn count_files(&self) -> cas_store::error::Result<usize> { todo!() }
    fn count_symbols(&self) -> cas_store::error::Result<usize> { todo!() }
    fn count_files_by_language(
        &self,
    ) -> cas_store::error::Result<std::collections::HashMap<Language, usize>> { todo!() }
    fn close(&self) -> cas_store::error::Result<()> { todo!() }
}

/// Mock vector store
struct MockVectorStore {
    vectors: HashMap<String, Vec<f32>>,
}

impl MockVectorStore {
    fn new() -> Self { todo!() }

    fn add(&mut self, key: &str, _vec: Vec<f32>) { todo!() }
}

impl VectorStore for MockVectorStore {
    fn store(&self, _: &str, _: &[f32]) -> Result<()> { todo!() }
    fn get(&self, _: &str) -> Result<Option<Vec<f32>>> { todo!() }
    fn delete(&self, _: &str) -> Result<()> { todo!() }
    fn search(&self, _: &[f32], k: usize) -> Result<Vec<(String, f32)>> { todo!() }
    fn exists(&self, _: &str) -> Result<bool> { todo!() }
    fn count(&self) -> Result<usize> { todo!() }
    fn list_ids(&self) -> Result<Vec<String>> { todo!() }
    fn dimension(&self) -> usize { todo!() }
}

/// Mock BM25 index
struct MockBm25Index {
    docs: HashMap<String, String>,
}

impl MockBm25Index {
    fn new() -> Self { todo!() }

    fn add(&mut self, id: &str, content: &str) { todo!() }
}

impl TextIndex for MockBm25Index {
    fn index(&self, _: &dyn crate::traits::SearchDocument) -> Result<()> { todo!() }
    fn remove(&self, _: &str) -> Result<()> { todo!() }
    fn search(&self, query: &str, limit: usize) -> Result<Vec<(String, f64)>> { todo!() }
    fn search_with_type(
        &self,
        query: &str,
        _doc_type: &str,
        limit: usize,
    ) -> Result<Vec<(String, f64)>> { todo!() }
    fn search_with_tags(
        &self,
        query: &str,
        _tags: &[&str],
        limit: usize,
    ) -> Result<Vec<(String, f64)>> { todo!() }
    fn commit(&self) -> Result<()> { todo!() }
}

/// Mock embedder
struct MockEmbedder;

impl Embedder for MockEmbedder {
    fn embed(&self, _: &str) -> Result<Vec<f32>> { todo!() }
    fn dimension(&self) -> usize { todo!() }
}



#[test]
fn test_code_search_stats_default() {
    let stats = CodeSearchStats::default();
    assert_eq!(stats.file_count, 0);
    assert_eq!(stats.symbol_count, 0);
}

/// Test that search uses batch fetching, not N+1 individual queries
#[test]
fn test_no_n_plus_1_with_1000_symbols() {
    // Create mock stores
    let mut code_store = MockCodeStore::new();
    let mut bm25_index = MockBm25Index::new();
    let vector_store = MockVectorStore::new();

    // Add 1000 symbols
    for i in 0..1000 {
        let symbol = CodeSymbol {
            id: format!("sym-{i:04}"),
            qualified_name: format!("module::function_{i}"),
            name: format!("function_{i}"),
            kind: SymbolKind::Function,
            language: Language::Rust,
            file_path: format!("src/mod_{}.rs", i % 10),
            file_id: format!("file-{}", i % 10),
            line_start: i * 10,
            line_end: i * 10 + 5,
            source: format!("fn function_{i}() {{ /* body */ }}"),
            documentation: Some(format!("Documentation for function {i}")),
            ..Default::default()
        };
        bm25_index.add(
            &symbol.id,
            &format!("{} {}", symbol.qualified_name, symbol.source),
        );
        code_store.insert_symbol(symbol);
    }

    // Create search instance
    let code_store = Arc::new(code_store);
    let search = CodeSearch::new(
        code_store.clone(),
        Arc::new(vector_store),
        Arc::new(bm25_index),
        None,
    );

    // Search for symbols
    let opts = CodeSearchOptions {
        query: "function".to_string(),
        limit: 100,
        include_source: false,
        ..Default::default()
    };

    let results = search.pattern_search(&opts).unwrap();

    // Verify we got results
    assert!(!results.is_empty(), "Should find matching symbols");
    assert!(results.len() <= 100, "Should respect limit");

    // Verify batch fetching was used (1+ batch calls, no single calls)
    assert_eq!(
        code_store.single_fetches(),
        0,
        "Expected batch fetches only"
    );
    assert!(
        code_store.batch_fetches() > 0,
        "Expected at least one batch fetch"
    );
    println!("Search completed with {} results", results.len());
}

/// Test that semantic search also uses batch fetching

/// Verify no EmbeddingModel::load() calls inside CodeSearch
#[test]
fn test_shared_embedder_no_loading() {
    // This test verifies the architecture - CodeSearch accepts Arc<dyn Embedder>
    // and doesn't load models internally

    let code_store = MockCodeStore::new();
    let vector_store = MockVectorStore::new();
    let bm25_index = MockBm25Index::new();

    // Without embedder - semantic search falls back to pattern
    let search_no_embed: CodeSearch<MockCodeStore, MockVectorStore, MockBm25Index> =
        CodeSearch::new(
            Arc::new(code_store),
            Arc::new(vector_store),
            Arc::new(bm25_index),
            None,
        );
    assert!(!search_no_embed.has_semantic());

    // With shared embedder - no internal loading
    let code_store = MockCodeStore::new();
    let vector_store = MockVectorStore::new();
    let bm25_index = MockBm25Index::new();
    let shared_embedder: Arc<dyn Embedder> = Arc::new(MockEmbedder);

    let search_with_embed = CodeSearch::new(
        Arc::new(code_store),
        Arc::new(vector_store),
        Arc::new(bm25_index),
        Some(shared_embedder.clone()),
    );
    assert!(search_with_embed.has_semantic());

    // The same embedder can be shared across multiple CodeSearch instances
    // without reloading the model
    let code_store2 = MockCodeStore::new();
    let vector_store2 = MockVectorStore::new();
    let bm25_index2 = MockBm25Index::new();

    let search2 = CodeSearch::new(
        Arc::new(code_store2),
        Arc::new(vector_store2),
        Arc::new(bm25_index2),
        Some(shared_embedder), // Reuse the same Arc
    );
    assert!(search2.has_semantic());
}
