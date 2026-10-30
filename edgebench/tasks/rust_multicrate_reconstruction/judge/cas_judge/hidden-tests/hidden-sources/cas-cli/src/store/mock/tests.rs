#[test]
fn test_mock_store_not_found() {
    let store = MockStore::new();
    let result = store.get("nonexistent");
    assert!(matches!(result, Err(StoreError::NotFound(_))));
}
