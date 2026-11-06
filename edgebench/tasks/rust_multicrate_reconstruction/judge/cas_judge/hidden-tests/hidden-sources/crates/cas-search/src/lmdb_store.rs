    #[test]
    fn test_store_and_get() {
        let dir = tempdir().unwrap();
        let store = LmdbVectorStore::open(dir.path(), 128).unwrap();

        let embedding = random_embedding(128, 42);
        store.store("doc-001", &embedding).unwrap();

        let retrieved = store.get("doc-001").unwrap().unwrap();
        assert_eq!(retrieved.len(), 128);

        // Verify values match
        for (a, b) in embedding.iter().zip(retrieved.iter()) {
            assert!((a - b).abs() < 1e-6);
        }
    }

    #[test]
    fn test_get_nonexistent() {
        let dir = tempdir().unwrap();
        let store = LmdbVectorStore::open(dir.path(), 128).unwrap();

        let result = store.get("nonexistent").unwrap();
        assert!(result.is_none());
    }

    #[test]
    fn test_count() {
        let dir = tempdir().unwrap();
        let store = LmdbVectorStore::open(dir.path(), 128).unwrap();

        assert_eq!(store.count().unwrap(), 0);

        store.store("a", &random_embedding(128, 1)).unwrap();
        store.store("b", &random_embedding(128, 2)).unwrap();
        store.store("c", &random_embedding(128, 3)).unwrap();

        assert_eq!(store.count().unwrap(), 3);
    }

    #[test]
    fn test_dimension_stored_in_metadata() {
        let dir = tempdir().unwrap();
        let path = dir.path().to_path_buf();

        // Create with dimension 512
        {
            let store = LmdbVectorStore::open(&path, 512).unwrap();
            assert_eq!(store.dimension(), 512);
        }

        // Reopen with same dimension - should work
        {
            let store = LmdbVectorStore::open(&path, 512).unwrap();
            assert_eq!(store.dimension(), 512);
        }

        // Try to open with different dimension - should fail
        {
            let result = LmdbVectorStore::open(&path, 1024);
            assert!(result.is_err());
        }
    }
