    #[test]
    fn test_pid_mapping() {
        use tempfile::TempDir;

        let temp = TempDir::new().unwrap();
        let cas_root = temp.path();

        let agent_id = "cc-12345-abcd1234";
        register_agent_pid_mapping(cas_root, agent_id).unwrap();

        // Verify the file was created
        #[cfg(unix)]
        {
            let ppid = std::os::unix::process::parent_id();
            let mapping_file = cas_root.join(format!("agents_by_cc_pid/{ppid}"));
            assert!(mapping_file.exists());
            let content = std::fs::read_to_string(&mapping_file).unwrap();
            assert_eq!(content, agent_id);
        }

        // Cleanup
        cleanup_agent_pid_mapping(cas_root);

        #[cfg(unix)]
        {
            let ppid = std::os::unix::process::parent_id();
            let mapping_file = cas_root.join(format!("agents_by_cc_pid/{ppid}"));
            assert!(!mapping_file.exists());
        }
    }
