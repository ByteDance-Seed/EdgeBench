    #[test]
    fn test_layered_entry_store_global_only() {
        let global: Arc<dyn Store> = Arc::new(MockStore::new());
        let layered = LayeredEntryStore::global_only(global);

        assert!(!layered.has_project());
    }

    #[test]
    fn test_layered_entry_store_with_project() {
        let global: Arc<dyn Store> = Arc::new(MockStore::new());
        let project: Arc<dyn Store> = Arc::new(MockStore::new());
        let layered = LayeredEntryStore::new(global, Some(project));

        assert!(layered.has_project());
    }

    #[test]
    fn test_layered_entry_store_list_all() {
        let global: Arc<dyn Store> = Arc::new(MockStore::new());
        let project: Arc<dyn Store> = Arc::new(MockStore::new());
        let layered = LayeredEntryStore::new(Arc::clone(&global), Some(Arc::clone(&project)));

        // Add entries to each store
        let mut g1 = Entry::new("g-001".to_string(), "Global 1".to_string());
        g1.scope = Scope::Global;
        layered.add(&g1).unwrap();

        let mut p1 = Entry::new("p-001".to_string(), "Project 1".to_string());
        p1.scope = Scope::Project;
        layered.add(&p1).unwrap();

        // List all should return both
        let all = layered.list(ScopeFilter::All).unwrap();
        assert_eq!(all.len(), 2);

        // List global only
        let global_only = layered.list(ScopeFilter::Global).unwrap();
        assert_eq!(global_only.len(), 1);
        assert_eq!(global_only[0].id, "g-001");

        // List project only
        let project_only = layered.list(ScopeFilter::Project).unwrap();
        assert_eq!(project_only.len(), 1);
        assert_eq!(project_only[0].id, "p-001");
    }
