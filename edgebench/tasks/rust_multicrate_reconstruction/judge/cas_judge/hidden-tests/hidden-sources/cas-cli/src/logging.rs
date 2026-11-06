    #[test]
    fn test_create_log_file() {
        let dir = tempdir().unwrap();
        let file = create_log_file(dir.path()).unwrap();
        drop(file);

        // Verify file was created
        let entries: Vec<_> = fs::read_dir(dir.path()).unwrap().collect();
        assert_eq!(entries.len(), 1);

        let entry = entries[0].as_ref().unwrap();
        let name = entry.file_name().to_string_lossy().to_string();
        assert!(name.starts_with("cas-"));
        assert!(name.ends_with(".log"));
    }

    #[test]
    fn test_cleanup_old_logs() {
        let dir = tempdir().unwrap();

        // Create some old log files
        let old_date = chrono::Local::now() - chrono::Duration::days(10);
        let old_name = format!("cas-{}.log", old_date.format("%Y-%m-%d"));
        fs::write(dir.path().join(&old_name), "old log").unwrap();

        // Create a recent log file
        let recent_date = chrono::Local::now();
        let recent_name = format!("cas-{}.log", recent_date.format("%Y-%m-%d"));
        fs::write(dir.path().join(&recent_name), "recent log").unwrap();

        // Clean up with 7-day retention
        let removed = cleanup_old_logs(dir.path(), 7).unwrap();
        assert_eq!(removed, 1);

        // Verify only recent file remains
        let entries: Vec<_> = fs::read_dir(dir.path()).unwrap().collect();
        assert_eq!(entries.len(), 1);
    }
