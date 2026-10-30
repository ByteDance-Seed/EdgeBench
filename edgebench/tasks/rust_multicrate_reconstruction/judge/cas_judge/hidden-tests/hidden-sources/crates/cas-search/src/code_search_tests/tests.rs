#[test]
fn test_code_search_options_default() {
    let opts = CodeSearchOptions::default();
    assert!(opts.query.is_empty());
    assert_eq!(opts.limit, 0);
    assert!(!opts.include_source);
    assert!(!opts.semantic);
}

#[test]
fn test_create_snippet() {
    // Short source
    let snippet = CodeSearchResult::create_snippet("fn foo() {}");
    assert_eq!(snippet, "fn foo() {}");

    // Multi-line source
    let source = "fn foo() {\n    bar();\n    baz();\n    qux();\n}";
    let snippet = CodeSearchResult::create_snippet(source);
    assert!(snippet.ends_with("..."));
    assert!(snippet.contains("bar()"));
    assert!(!snippet.contains("qux()"));

    // Long line
    let long = "a".repeat(300);
    let snippet = CodeSearchResult::create_snippet(&long);
    assert_eq!(snippet.len(), 200);
    assert!(snippet.ends_with("..."));
}

#[test]
fn test_semantic_search_batch_fetching() {
    let mut code_store = MockCodeStore::new();
    let mut vector_store = MockVectorStore::new();
    let bm25_index = MockBm25Index::new();

    // Add 100 symbols with embeddings
    for i in 0..100 {
        let symbol = CodeSymbol {
            id: format!("sym-{i:04}"),
            qualified_name: format!("module::semantic_func_{i}"),
            name: format!("semantic_func_{i}"),
            kind: SymbolKind::Function,
            language: Language::Rust,
            file_path: "src/lib.rs".to_string(),
            file_id: "file-1".to_string(),
            line_start: i * 10,
            line_end: i * 10 + 5,
            source: format!("fn semantic_func_{i}() {{}}"),
            ..Default::default()
        };
        // Vector key format: code:{symbol_id}:full
        vector_store.add(&format!("code:{}:full", symbol.id), vec![0.0; 128]);
        code_store.insert_symbol(symbol);
    }

    let code_store = Arc::new(code_store);
    let search = CodeSearch::new(
        code_store.clone(),
        Arc::new(vector_store),
        Arc::new(bm25_index),
        Some(Arc::new(MockEmbedder)),
    );

    let opts = CodeSearchOptions {
        query: "semantic function".to_string(),
        limit: 50,
        semantic: true,
        ..Default::default()
    };

    let results = search.search(&opts).unwrap();
    assert!(!results.is_empty(), "Should find semantic matches");
    assert_eq!(
        code_store.single_fetches(),
        0,
        "Expected batch fetches only"
    );
    assert!(
        code_store.batch_fetches() > 0,
        "Expected at least one batch fetch"
    );

    println!("Semantic search returned {} results", results.len());
}
