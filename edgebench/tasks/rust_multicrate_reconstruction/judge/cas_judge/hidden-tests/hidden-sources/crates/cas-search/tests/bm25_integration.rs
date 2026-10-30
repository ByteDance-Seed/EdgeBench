#[test]
fn test_bm25_scoring_term_frequency() {
    let index = Bm25Index::in_memory().unwrap();

    // Doc with high term frequency
    let high_tf = TestDoc::new("high", "rust rust rust rust programming");
    // Doc with low term frequency
    let low_tf = TestDoc::new("low", "rust programming guide");

    index.index(&high_tf).unwrap();
    index.index(&low_tf).unwrap();

    let results = index.search("rust", 10).unwrap();
    assert_eq!(results.len(), 2);

    // Higher term frequency should score higher
    assert_eq!(results[0].0, "high", "Higher TF doc should rank first");
    assert!(
        results[0].1 > results[1].1,
        "Higher TF should have higher score"
    );
}
