    #[test]
    fn test_feedback_boost() {
        let index = SearchIndex::in_memory().unwrap();

        // Entry with low BM25 score but high feedback
        let mut entry1 = create_test_entry("001", "Rust programming");
        entry1.helpful_count = 10;

        // Entry with higher BM25 score (more matching terms) but no feedback
        let entry2 = create_test_entry("002", "Rust programming language tutorial guide");

        let entries = vec![entry1, entry2];

        for entry in &entries {
            index.index_entry(entry).unwrap();
        }

        // Without boost: entry2 should rank higher due to more content
        let opts = SearchOptions {
            query: "programming".to_string(),
            limit: 10,
            boost_feedback: false,
            ..Default::default()
        };
        let results_without = index.search(&opts, &entries).unwrap();

        // With boost: entry1's feedback should help it compete or rank higher
        let opts = SearchOptions {
            query: "programming".to_string(),
            limit: 10,
            boost_feedback: true,
            ..Default::default()
        };
        let results_with = index.search(&opts, &entries).unwrap();

        // Find positions
        let pos_without = results_without.iter().position(|r| r.id == "001").unwrap();
        let pos_with = results_with.iter().position(|r| r.id == "001").unwrap();

        // With feedback boost, entry1 should rank better (lower position = better)
        // or at least maintain position
        assert!(
            pos_with <= pos_without,
            "Feedback boost should improve ranking: pos_with={pos_with}, pos_without={pos_without}"
        );
    }

    #[test]
    fn test_unified_search_with_id_patterns() {
        let index = SearchIndex::in_memory().unwrap();

        // Create test tasks
        let task1 = Task {
            id: "cas-1234".to_string(),
            title: "Test task one".to_string(),
            description: "First task description".to_string(),
            ..Default::default()
        };
        let task2 = Task {
            id: "cas-5678".to_string(),
            title: "Test task two".to_string(),
            description: "Second task description".to_string(),
            ..Default::default()
        };

        index.index_task(&task1).unwrap();
        index.index_task(&task2).unwrap();

        // Search by single ID
        let opts = SearchOptions {
            query: "cas-1234".to_string(),
            limit: 10,
            ..Default::default()
        };
        let results = index.search_unified(&opts).unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].id, "cas-1234");
        assert_eq!(results[0].score, 1.0); // Exact ID match

        // Search by multiple IDs
        let opts = SearchOptions {
            query: "cas-1234 cas-5678".to_string(),
            limit: 10,
            ..Default::default()
        };
        let results = index.search_unified(&opts).unwrap();
        assert_eq!(results.len(), 2);

        // Search by ID with doc_type filter
        let opts = SearchOptions {
            query: "cas-1234".to_string(),
            limit: 10,
            doc_types: vec![DocType::Task],
            ..Default::default()
        };
        let results = index.search_unified(&opts).unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].doc_type, DocType::Task);
    }
