    #[test]
    fn test_otel_context_creation() {
        let ctx = OtelContext::new("session-123".to_string())
            .with_agent_id(Some("agent-abc".to_string()))
            .with_task_id(Some("cas-1234".to_string()))
            .with_project_id(Some("github.com/org/repo".to_string()));

        assert_eq!(ctx.session_id, Some("session-123".to_string()));
        assert_eq!(ctx.agent_id, Some("agent-abc".to_string()));
        assert_eq!(ctx.task_id, Some("cas-1234".to_string()));
    }
