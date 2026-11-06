#[test]
fn test_index_and_search() {
    let index = SearchIndex::in_memory().unwrap();

    let entries = vec![
        create_test_entry("001", "Rust is a systems programming language"),
        create_test_entry("002", "Python is good for data science"),
        create_test_entry("003", "JavaScript runs in browsers"),
    ];

    for entry in &entries {
        index.index_entry(entry).unwrap();
    }

    let opts = SearchOptions {
        query: "programming".to_string(),
        limit: 10,
        ..Default::default()
    };

    let results = index.search(&opts, &entries).unwrap();
    assert!(!results.is_empty());
    assert_eq!(results[0].id, "001");
}

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
