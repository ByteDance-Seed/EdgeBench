    #[test]
    fn test_try_claim_worktree_same_agent_renews() {
        let (_temp, agent_store, worktree_store) = create_test_stores();

        let agent = Agent::new("agent-1".to_string(), "Agent 1".to_string());
        agent_store.register(&agent).unwrap();

        let worktree = create_test_workspace(&worktree_store, "epic-789");

        // First claim
        let result1 = agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 600)
            .unwrap();
        assert!(result1.is_success());
        let lease1 = result1.lease().unwrap();

        std::thread::sleep(std::time::Duration::from_millis(10));

        // Same agent claims again - should succeed (renew)
        let result2 = agent_store
            .try_claim_worktree(&worktree.id, "agent-1", 600)
            .unwrap();
        assert!(result2.is_success());
        let lease2 = result2.lease().unwrap();

        // Should have extended expiry
        assert!(lease2.expires_at > lease1.expires_at);
    }
