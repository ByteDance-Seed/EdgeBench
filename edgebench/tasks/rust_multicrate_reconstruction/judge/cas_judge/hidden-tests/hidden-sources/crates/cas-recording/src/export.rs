    #[test]
    fn test_manifest_serialization() {
        let manifest = ArchiveManifest {
            version: ARCHIVE_VERSION,
            created_at: Utc::now(),
            session_id: "test-session".to_string(),
            session_name: Some("happy-elephant".to_string()),
            project_dir: Some("/path/to/project".to_string()),
            agents: vec![AgentManifest {
                name: "supervisor".to_string(),
                role: "supervisor".to_string(),
                recording_path: "recordings/supervisor.rec".to_string(),
                duration_ms: 60000,
                event_count: 100,
                file_size: 50000,
                cols: 120,
                rows: 40,
            }],
            total_duration_ms: 60000,
            epic_id: Some("cas-1234".to_string()),
            epic_title: Some("Test Epic".to_string()),
            cas_version: "0.5.0".to_string(),
        };

        let json = serde_json::to_string_pretty(&manifest).unwrap();
        let parsed: ArchiveManifest = serde_json::from_str(&json).unwrap();

        assert_eq!(manifest.session_id, parsed.session_id);
        assert_eq!(manifest.agents.len(), parsed.agents.len());
    }
