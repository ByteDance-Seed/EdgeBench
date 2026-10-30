    #[test]
    fn test_hybrid_search_options_default() {
        let opts = HybridSearchOptions::default();
        assert!(!opts.enable_semantic); // Disabled by default
        assert_eq!(opts.bm25_weight, 1.0);
        assert_eq!(opts.semantic_weight, 0.0);
        assert!(!opts.use_rrf);
    }

    #[test]
    fn test_hybrid_search_bm25_only() {
        let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());

        // Index some documents
        let docs = vec![
            TestDoc {
                id: "1".to_string(),
                content: "Rust programming language".to_string(),
            },
            TestDoc {
                id: "2".to_string(),
                content: "Python data science".to_string(),
            },
        ];

        for doc in &docs {
            bm25_index.index(doc).unwrap();
        }

        let search = HybridSearch::new(bm25_index);

        let opts = HybridSearchOptions {
            query: "rust".to_string(),
            limit: 10,
            ..Default::default()
        };

        let results = search.search(&opts).unwrap();
        assert!(!results.is_empty());
        assert_eq!(results[0].id, "1");
        assert!(results[0].bm25_score > 0.0);
        assert_eq!(results[0].semantic_score, 0.0); // Always 0 now
    }

        #[tokio::test]
        async fn test_async_hybrid_search() {
            let bm25_index = Arc::new(Bm25Index::in_memory().unwrap());

            // Index documents
            let docs = vec![
                TestDoc {
                    id: "1".to_string(),
                    content: "Rust programming language".to_string(),
                },
                TestDoc {
                    id: "2".to_string(),
                    content: "Python data science".to_string(),
                },
            ];

            for doc in &docs {
                bm25_index.index(doc).unwrap();
            }

            let search = HybridSearch::new(bm25_index);

            let opts = HybridSearchOptions {
                query: "rust".to_string(),
                limit: 10,
                ..Default::default()
            };

            let results = search.search_async(&opts).await.unwrap();
            assert!(!results.is_empty());
            assert_eq!(results[0].id, "1");
        }
