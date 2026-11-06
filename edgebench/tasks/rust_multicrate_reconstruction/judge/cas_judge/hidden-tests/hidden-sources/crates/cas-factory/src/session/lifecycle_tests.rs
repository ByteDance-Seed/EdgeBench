#[test]
fn test_session_persistence() {
    let dir = tempdir().unwrap();
    let id;

    // Create session
    {
        let mut manager = SessionManager::new(Some(dir.path().to_path_buf())).unwrap();
        id = manager
            .create_session("persist-test", "/tmp/persist")
            .unwrap();
    }

    // Reload and verify
    {
        let manager = SessionManager::new(Some(dir.path().to_path_buf())).unwrap();
        let session = manager.get_session(&id).unwrap();
        assert_eq!(session.name, "persist-test");
        assert_eq!(session.project_dir, PathBuf::from("/tmp/persist"));
    }
}
