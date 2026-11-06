    #[test]
    fn test_agent_match_is_exact_not_substring() {
        let worker_10 = AgentSummary {
            id: "agent-10".to_string(),
            name: "worker-10".to_string(),
            status: AgentStatus::Active,
            current_task: None,
            latest_activity: None,
            last_heartbeat: None,
        };

        assert!(
            !is_exact_agent_name_match(&worker_10, "worker-1"),
            "worker-1 must not match worker-10"
        );
        assert!(is_exact_agent_name_match(&worker_10, "worker-10"));
    }
