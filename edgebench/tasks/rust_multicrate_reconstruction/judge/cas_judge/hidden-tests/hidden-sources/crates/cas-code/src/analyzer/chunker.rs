    #[test]
    fn test_chunk_without_docs() {
        // Use dual mode to test DocSignature behavior
        let config = ChunkConfig {
            chunk_types: vec![ChunkType::DocSignature, ChunkType::FullSource],
            ..Default::default()
        };
        let chunker = CodeChunker::with_config(config);
        let symbol = make_symbol(
            "process",
            SymbolKind::Function,
            None,
            Some("fn process(data: &[u8])"),
        );

        let chunks = chunker.chunk_symbol(&symbol);

        let doc_sig = chunks
            .iter()
            .find(|c| c.chunk_type == ChunkType::DocSignature)
            .unwrap();
        // Should just have signature when no docs
        assert_eq!(doc_sig.content, "fn process(data: &[u8])");
    }

    #[test]
    fn test_importance_scores() {
        let chunker = CodeChunker::new();

        let trait_sym = make_symbol("MyTrait", SymbolKind::Trait, Some("A trait"), None);
        let fn_sym = make_symbol("my_fn", SymbolKind::Function, None, None);

        let trait_chunks = chunker.chunk_symbol(&trait_sym);
        let fn_chunks = chunker.chunk_symbol(&fn_sym);

        // Trait with docs should have higher importance than fn without docs
        assert!(trait_chunks[0].importance > fn_chunks[0].importance);
    }
