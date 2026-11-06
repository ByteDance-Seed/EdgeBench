    #[test]
    fn test_agent_new() {
        let agent = Agent::new("agent-test".to_string(), "Test Agent".to_string());
        assert_eq!(agent.id, "agent-test");
        assert_eq!(agent.name, "Test Agent");
        assert_eq!(agent.agent_type, AgentType::Primary);
        assert_eq!(agent.status, AgentStatus::Active);
        assert!(agent.is_alive());
    }

    #[test]
    fn test_agent_new_with_role() {
        let agent = Agent::new_with_role(
            "supervisor-1".to_string(),
            "Supervisor Agent".to_string(),
            AgentRole::Supervisor,
        );
        assert_eq!(agent.role, AgentRole::Supervisor);
        assert_eq!(agent.agent_type, AgentType::Primary);
    }

    #[test]
    fn test_agent_with_role_builder() {
        let agent = Agent::new("worker-1".to_string(), "Worker Agent".to_string())
            .with_role(AgentRole::Worker);
        assert_eq!(agent.role, AgentRole::Worker);
    }

    #[test]
    fn test_agent_default_role() {
        let agent = Agent::new("test".to_string(), "Test".to_string());
        assert_eq!(agent.role, AgentRole::Standard);
    }
