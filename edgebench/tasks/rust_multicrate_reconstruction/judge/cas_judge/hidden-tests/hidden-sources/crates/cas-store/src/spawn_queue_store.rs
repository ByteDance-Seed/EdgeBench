    #[test]
    fn test_spawn_action_serialization() {
        assert_eq!(SpawnAction::Spawn.as_str(), "spawn");
        assert_eq!(SpawnAction::Shutdown.as_str(), "shutdown");
        assert_eq!(SpawnAction::Respawn.as_str(), "respawn");
        assert_eq!(SpawnAction::from_str("spawn"), Some(SpawnAction::Spawn));
        assert_eq!(
            SpawnAction::from_str("SHUTDOWN"),
            Some(SpawnAction::Shutdown)
        );
        assert_eq!(SpawnAction::from_str("respawn"), Some(SpawnAction::Respawn));
        assert_eq!(SpawnAction::from_str("invalid"), None);
    }

    #[test]
    fn test_enqueue_spawn_with_isolate() {
        let (_temp, store) = create_test_store();

        // Queue a spawn request with isolate=true
        store.enqueue_spawn(2, &[], true).unwrap();

        let requests = store.poll(10).unwrap();
        assert_eq!(requests.len(), 1);
        assert_eq!(requests[0].action, SpawnAction::Spawn);
        assert!(requests[0].isolate);

        // Queue a spawn request with isolate=false
        store.enqueue_spawn(1, &[], false).unwrap();

        let requests = store.poll(10).unwrap();
        assert_eq!(requests.len(), 1);
        assert!(!requests[0].isolate);
    }
