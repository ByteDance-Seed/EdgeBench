    #[tokio::test]
    async fn test_pty_config_default() {
        let config = PtyConfig::default();
        assert_eq!(config.command, "bash");
        assert_eq!(config.rows, 24);
        assert_eq!(config.cols, 80);
    }

    #[tokio::test]
    async fn test_pty_config_claude() {
        let config = PtyConfig::claude(
            "test-agent",
            "worker",
            PathBuf::from("/tmp"),
            None,
            None,
            None,
            None,
            None,
        );
        assert_eq!(config.command, "claude");
        assert!(
            config
                .args
                .contains(&"--dangerously-skip-permissions".to_string())
        );
        assert!(
            config
                .env
                .iter()
                .any(|(k, v)| k == "CAS_AGENT_NAME" && v == "test-agent")
        );
        assert!(
            config
                .env
                .iter()
                .any(|(k, v)| k == "CAS_AGENT_ROLE" && v == "worker")
        );
        // No CAS_ROOT when not provided
        assert!(!config.env.iter().any(|(k, _)| k == "CAS_ROOT"));
    }

    #[tokio::test]
    async fn test_pty_config_claude_with_supervisor() {
        let config = PtyConfig::claude(
            "test-worker",
            "worker",
            PathBuf::from("/tmp"),
            None,
            Some("test-supervisor"),
            None,
            None,
            None,
        );
        assert!(
            config
                .env
                .iter()
                .any(|(k, v)| k == "CAS_SUPERVISOR_NAME" && v == "test-supervisor")
        );
    }

    #[tokio::test]
    async fn test_pty_config_codex_with_model() {
        let config = PtyConfig::codex(
            "test-agent",
            "supervisor",
            PathBuf::from("/tmp"),
            None,
            None,
            None,
            Some("gpt-5.3-codex"),
            None,
        );
        assert!(config.args.contains(&"--model".to_string()));
        assert!(config.args.contains(&"gpt-5.3-codex".to_string()));
    }

    #[tokio::test]
    async fn test_pty_config_claude_with_teams() {
        let teams = TeamsSpawnConfig {
            team_name: "test-team".to_string(),
            agent_id: "worker-1@test-team".to_string(),
            agent_name: "worker-1".to_string(),
            agent_color: "blue".to_string(),
            agent_type: "general-purpose".to_string(),
            parent_session_id: Some("lead-session-123".to_string()),
        };
        let config = PtyConfig::claude(
            "worker-1",
            "worker",
            PathBuf::from("/tmp"),
            None,
            None,
            None,
            None,
            Some(&teams),
        );
        assert!(config.args.contains(&"--team-name".to_string()));
        assert!(config.args.contains(&"test-team".to_string()));
        assert!(config.args.contains(&"--agent-id".to_string()));
        assert!(config.args.contains(&"worker-1@test-team".to_string()));
        assert!(config.args.contains(&"--agent-name".to_string()));
        assert!(config.args.contains(&"--agent-color".to_string()));
        assert!(config.args.contains(&"--teammate-mode".to_string()));
        assert!(config.args.contains(&"tmux".to_string()));
        assert!(config.args.contains(&"--parent-session-id".to_string()));
        assert!(config.args.contains(&"lead-session-123".to_string()));
        // Workers should NOT have --session-id
        assert!(!config.args.contains(&"--session-id".to_string()));
        assert!(
            config
                .env
                .iter()
                .any(|(k, v)| k == "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS" && v == "1")
        );
    }
