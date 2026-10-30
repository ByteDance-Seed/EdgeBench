#[test]
fn test_code_search_1k_symbols_no_n_plus_1() {
    let code_store = Arc::new(MockCodeStore::new());
    let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());
    let vector_store = Arc::new(MockVectorStore::new(64));

    // Create 1000 symbols
    let kinds = [SymbolKind::Function, SymbolKind::Struct, SymbolKind::Trait];
    let languages = [Language::Rust, Language::Python, Language::TypeScript];

    for i in 0..1000 {
        let symbol = CodeSymbol {
            id: format!("sym-{i:04}"),
            qualified_name: format!("module::item_{i}"),
            name: format!("item_{i}"),
            kind: kinds[i % kinds.len()],
            language: languages[i % languages.len()],
            file_path: format!("src/file_{}.rs", i % 50),
            file_id: format!("file-{}", i % 50),
            line_start: (i * 10) % 500,
            line_end: (i * 10) % 500 + 5,
            source: format!("fn item_{i}() {{ /* implementation {i} */ }}"),
            documentation: Some(format!("Doc for item {i}")),
            ..Default::default()
        };
        code_store.insert_symbol(symbol.clone());
        bm25_index.index(&SymbolDoc { symbol: &symbol }).unwrap();
    }

    let search: CodeSearch<MockCodeStore, MockVectorStore, Bm25Index> =
        CodeSearch::new(code_store.clone(), vector_store, bm25_index, None);

    code_store.reset_counters();

    // Search
    let start = std::time::Instant::now();
    let opts = CodeSearchOptions {
        query: "item".to_string(),
        limit: 100,
        semantic: false,
        ..Default::default()
    };

    let results = search.pattern_search(&opts).unwrap();
    let elapsed = start.elapsed();

    println!(
        "Search 1k symbols: {} results in {:?}",
        results.len(),
        elapsed
    );

    // Performance check
    assert!(
        elapsed.as_millis() < 500,
        "Search should be fast, took {elapsed:?}"
    );

    // N+1 check
    let single_fetches = code_store.single_fetches();
    let batch_fetches = code_store.batch_fetches();

    println!("Fetches: {single_fetches} single, {batch_fetches} batch");

    assert!(batch_fetches >= 1, "Should use batch fetching");
    assert_eq!(
        single_fetches, 0,
        "Should not use individual symbol fetches"
    );
}
