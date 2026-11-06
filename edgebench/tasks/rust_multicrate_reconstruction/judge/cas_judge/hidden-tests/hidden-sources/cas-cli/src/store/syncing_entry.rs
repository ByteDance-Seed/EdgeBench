    #[test]
    fn test_add_queues_sync() {
        let (temp, store) = create_test_store();
        let queue = SyncQueue::open(temp.path()).unwrap();

        let entry = Entry::new("entry-001".to_string(), "Test content".to_string());
        store.add(&entry).unwrap();

        let pending = queue.pending(10, 5).unwrap();
        assert_eq!(pending.len(), 1);
        assert_eq!(pending[0].entity_type, EntityType::Entry);
        assert_eq!(pending[0].entity_id, entry.id);
        assert_eq!(pending[0].operation, SyncOperation::Upsert);
    }
