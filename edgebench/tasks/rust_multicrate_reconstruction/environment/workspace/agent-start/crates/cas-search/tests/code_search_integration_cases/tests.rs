use crate::*;

#[test]
fn test_code_search_symbol_by_name() {
    let code_store = Arc::new(MockCodeStore::new());
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let vector_store = Arc::new(MockVectorStore::new(64));

    // Create symbols
    let symbols = vec![
        create_symbol("s1", "parse_config", SymbolKind::Function, Language::Rust),
        create_symbol("s2", "serialize_json", SymbolKind::Function, Language::Rust),
        create_symbol("s3", "parse_json", SymbolKind::Function, Language::Python),
    ];

    for symbol in &symbols {
        code_store.insert_symbol(symbol.clone());
        bm25_index.index(&SymbolDoc { symbol }).unwrap();
    }

    let search: CodeSearch<MockCodeStore, MockVectorStore, Bm25Index> =
        CodeSearch::new(code_store.clone(), vector_store, bm25_index, None);

    // Search by exact name
    let results = search.search_by_name("module::parse_config").unwrap();
    assert_eq!(results.len(), 1);
    assert_eq!(results[0].name, "module::parse_config");
    assert_eq!(results[0].kind, SymbolKind::Function);

    // Search by partial name pattern
    let opts = CodeSearchOptions {
        query: "parse".to_string(),
        limit: 10,
        semantic: false,
        ..Default::default()
    };

    let results = search.pattern_search(&opts).unwrap();
    assert!(
        results.len() >= 2,
        "Should find parse_config and parse_json"
    );

    // Verify results contain expected symbols
    let names: Vec<&str> = results.iter().map(|r| r.name.as_str()).collect();
    assert!(
        names.iter().any(|n| n.contains("parse")),
        "Should find parse-related symbols"
    );
}

/// Test: Semantic search returns similar code
#[test]
fn test_code_search_semantic_similarity() {
    let code_store = Arc::new(MockCodeStore::new());
    let dim = 64;
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let vector_store = Arc::new(MockVectorStore::new(dim));
    let embedder = Arc::new(MockEmbedder::new(dim));

    // Create symbols with varying content
    let symbols = vec![
        CodeSymbol {
            id: "s1".to_string(),
            qualified_name: "module::read_file".to_string(),
            name: "read_file".to_string(),
            kind: SymbolKind::Function,
            language: Language::Rust,
            file_path: "src/io.rs".to_string(),
            file_id: "file-1".to_string(),
            line_start: 1,
            line_end: 15,
            source: "fn read_file(path: &str) -> Result<String> { fs::read_to_string(path) }"
                .to_string(),
            documentation: Some("Read file contents to string".to_string()),
            ..Default::default()
        },
        CodeSymbol {
            id: "s2".to_string(),
            qualified_name: "module::write_file".to_string(),
            name: "write_file".to_string(),
            kind: SymbolKind::Function,
            language: Language::Rust,
            file_path: "src/io.rs".to_string(),
            file_id: "file-1".to_string(),
            line_start: 20,
            line_end: 30,
            source: "fn write_file(path: &str, data: &str) -> Result<()> { fs::write(path, data) }"
                .to_string(),
            documentation: Some("Write string to file".to_string()),
            ..Default::default()
        },
        CodeSymbol {
            id: "s3".to_string(),
            qualified_name: "module::calculate_sum".to_string(),
            name: "calculate_sum".to_string(),
            kind: SymbolKind::Function,
            language: Language::Rust,
            file_path: "src/math.rs".to_string(),
            file_id: "file-2".to_string(),
            line_start: 1,
            line_end: 5,
            source: "fn calculate_sum(nums: &[i32]) -> i32 { nums.iter().sum() }".to_string(),
            documentation: Some("Sum numbers in slice".to_string()),
            ..Default::default()
        },
    ];

    for symbol in &symbols {
        code_store.insert_symbol(symbol.clone());
        bm25_index.index(&SymbolDoc { symbol }).unwrap();

        // Store embedding with code:{id}:full key format
        let emb = embedder.embed_deterministic(&symbol.source);
        let key = format!("code:{}:full", symbol.id);
        vector_store.store(&key, &emb).unwrap();
    }

    let search: CodeSearch<MockCodeStore, MockVectorStore, Bm25Index> = CodeSearch::new(
        code_store.clone(),
        vector_store,
        bm25_index,
        Some(embedder as Arc<dyn CodeEmbedder>),
    );

    assert!(search.has_semantic());

    // Search for file-related operations
    let opts = CodeSearchOptions {
        query: "read file contents".to_string(),
        limit: 10,
        semantic: true,
        include_source: true,
        ..Default::default()
    };

    let results = search.search(&opts).unwrap();
    assert!(!results.is_empty(), "Should find results");

    // File operations should rank higher than math operations
    let file_op_found = results.iter().any(|r| r.name.contains("file"));
    assert!(
        file_op_found,
        "Should find file-related operations for file query"
    );
}

/// Test: Language and kind filters work
#[test]
fn test_code_search_filters() {
    let code_store = Arc::new(MockCodeStore::new());
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let vector_store = Arc::new(MockVectorStore::new(64));

    // Create symbols with different languages and kinds
    let symbols = vec![
        create_symbol("r1", "rust_function", SymbolKind::Function, Language::Rust),
        create_symbol("r2", "RustStruct", SymbolKind::Struct, Language::Rust),
        create_symbol(
            "p1",
            "python_function",
            SymbolKind::Function,
            Language::Python,
        ),
        create_symbol("p2", "PythonClass", SymbolKind::Struct, Language::Python),
        create_symbol(
            "t1",
            "typescript_func",
            SymbolKind::Function,
            Language::TypeScript,
        ),
    ];

    for symbol in &symbols {
        code_store.insert_symbol(symbol.clone());
        bm25_index.index(&SymbolDoc { symbol }).unwrap();
    }

    let search: CodeSearch<MockCodeStore, MockVectorStore, Bm25Index> =
        CodeSearch::new(code_store.clone(), vector_store, bm25_index, None);

    // Filter by language: Rust only
    let opts = CodeSearchOptions {
        query: "function struct".to_string(),
        limit: 10,
        language: Some(Language::Rust),
        semantic: false,
        ..Default::default()
    };

    let results = search.pattern_search(&opts).unwrap();
    for result in &results {
        assert_eq!(
            result.language,
            Language::Rust,
            "Should only find Rust symbols"
        );
    }

    // Filter by kind: Functions only
    let opts = CodeSearchOptions {
        query: "function".to_string(),
        limit: 10,
        kind: Some(SymbolKind::Function),
        semantic: false,
        ..Default::default()
    };

    let results = search.pattern_search(&opts).unwrap();
    for result in &results {
        assert_eq!(
            result.kind,
            SymbolKind::Function,
            "Should only find functions"
        );
    }

    // Combined filter: Rust functions
    let opts = CodeSearchOptions {
        query: "rust".to_string(),
        limit: 10,
        kind: Some(SymbolKind::Function),
        language: Some(Language::Rust),
        semantic: false,
        ..Default::default()
    };

    let results = search.pattern_search(&opts).unwrap();
    for result in &results {
        assert_eq!(result.language, Language::Rust);
        assert_eq!(result.kind, SymbolKind::Function);
    }
}

/// Test: No N+1 queries - batch fetching verification
#[test]
fn test_code_search_no_n_plus_1() {
    let code_store = Arc::new(MockCodeStore::new());
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let vector_store = Arc::new(MockVectorStore::new(64));

    // Create 100 symbols
    for i in 0..100 {
        let symbol = create_symbol(
            &format!("sym-{i:03}"),
            &format!("function_{i}"),
            SymbolKind::Function,
            Language::Rust,
        );
        code_store.insert_symbol(symbol.clone());
        bm25_index.index(&SymbolDoc { symbol: &symbol }).unwrap();
    }

    let search: CodeSearch<MockCodeStore, MockVectorStore, Bm25Index> =
        CodeSearch::new(code_store.clone(), vector_store, bm25_index, None);

    // Reset counters before search
    code_store.reset_counters();

    // Search that should match many symbols
    let opts = CodeSearchOptions {
        query: "function".to_string(),
        limit: 50,
        semantic: false,
        ..Default::default()
    };

    let results = search.pattern_search(&opts).unwrap();
    assert!(!results.is_empty(), "Should find functions");

    // Verify batch fetching was used instead of N single fetches
    let single_fetches = code_store.single_fetches();
    let batch_fetches = code_store.batch_fetches();

    println!(
        "Single fetches: {}, Batch fetches: {}, Results: {}",
        single_fetches,
        batch_fetches,
        results.len()
    );

    // Should use batch fetching (1 batch call) not N single calls
    assert!(
        batch_fetches >= 1,
        "Should use batch fetching, got {batch_fetches} batch calls"
    );
    assert_eq!(
        single_fetches, 0,
        "Should not use single fetches, got {single_fetches} single calls"
    );
}

/// Test: Code search with 1000 symbols - performance and N+1 check

/// Test: CodeSearchResult creation from symbol
#[test]
fn test_code_search_result_from_symbol() {
    let symbol = CodeSymbol {
        id: "test-id".to_string(),
        qualified_name: "module::test_func".to_string(),
        name: "test_func".to_string(),
        kind: SymbolKind::Function,
        language: Language::Rust,
        file_path: "src/lib.rs".to_string(),
        file_id: "file-1".to_string(),
        line_start: 10,
        line_end: 20,
        source: "fn test_func() {\n    println!(\"hello\");\n}".to_string(),
        documentation: Some("Test documentation".to_string()),
        ..Default::default()
    };

    // Without source
    let result = CodeSearchResult::from_symbol(symbol.clone(), 0.85, false);
    assert_eq!(result.id, "test-id");
    assert_eq!(result.name, "module::test_func");
    assert_eq!(result.kind, SymbolKind::Function);
    assert_eq!(result.language, Language::Rust);
    assert_eq!(result.score, 0.85);
    assert!(result.source.is_none());
    assert!(result.snippet.is_some());

    // With source
    let result = CodeSearchResult::from_symbol(symbol, 0.90, true);
    assert!(result.source.is_some());
    assert!(result.source.as_ref().unwrap().contains("test_func"));
}

/// Test: Snippet creation
#[test]
fn test_code_search_snippet_creation() {
    // Short source
    let snippet = CodeSearchResult::create_snippet("fn foo() {}");
    assert_eq!(snippet, "fn foo() {}");

    // Multi-line source (more than 3 lines)
    let source = "fn foo() {\n    bar();\n    baz();\n    qux();\n}";
    let snippet = CodeSearchResult::create_snippet(source);
    assert!(snippet.ends_with("..."));
    assert!(snippet.contains("bar()"));

    // Very long single line
    let long = "a".repeat(300);
    let snippet = CodeSearchResult::create_snippet(&long);
    assert_eq!(snippet.len(), 200);
    assert!(snippet.ends_with("..."));
}

/// Test: Search stats
#[test]
fn test_code_search_stats() {
    let code_store = Arc::new(MockCodeStore::new());
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let vector_store = Arc::new(MockVectorStore::new(64));

    // Add some symbols
    for i in 0..10 {
        let symbol = create_symbol(
            &format!("s{i}"),
            &format!("func_{i}"),
            SymbolKind::Function,
            Language::Rust,
        );
        code_store.insert_symbol(symbol);
    }

    let search: CodeSearch<MockCodeStore, MockVectorStore, Bm25Index> =
        CodeSearch::new(code_store, vector_store, bm25_index, None);

    let stats = search.stats().unwrap();
    assert_eq!(stats.symbol_count, 10);
    assert!(search.has_indexed_content());
}

/// Test: Empty query returns empty results
#[test]
fn test_code_search_empty_query() {
    let code_store = Arc::new(MockCodeStore::new());
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let vector_store = Arc::new(MockVectorStore::new(64));

    let search: CodeSearch<MockCodeStore, MockVectorStore, Bm25Index> =
        CodeSearch::new(code_store, vector_store, bm25_index, None);

    let opts = CodeSearchOptions {
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

/// Test: Fallback to pattern search when semantic unavailable
#[test]
fn test_code_search_semantic_fallback() {
    let code_store = Arc::new(MockCodeStore::new());
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let vector_store = Arc::new(MockVectorStore::new(64));

    // Add a symbol
    let symbol = create_symbol("s1", "test_function", SymbolKind::Function, Language::Rust);
    code_store.insert_symbol(symbol.clone());
    bm25_index.index(&SymbolDoc { symbol: &symbol }).unwrap();

    // Create search without embedder
    let search: CodeSearch<MockCodeStore, MockVectorStore, Bm25Index> =
        CodeSearch::new(code_store, vector_store, bm25_index, None);

    assert!(!search.has_semantic());

    // Request semantic search - should fall back to pattern
    let opts = CodeSearchOptions {
        query: "test".to_string(),
        limit: 10,
        semantic: true, // Request semantic
        ..Default::default()
    };

    let results = search.search(&opts).unwrap();
    assert!(!results.is_empty(), "Should fall back to pattern search");
}
