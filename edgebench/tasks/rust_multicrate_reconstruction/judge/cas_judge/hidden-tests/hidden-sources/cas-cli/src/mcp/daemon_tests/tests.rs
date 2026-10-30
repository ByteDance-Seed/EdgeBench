#[test]
fn test_get_sessions_for_sync_uses_cas_root_directory_path() {
    let temp = TempDir::new().expect("temp dir");
    let cas_root = init_cas_dir(temp.path()).expect("init cas dir");

    let sqlite_store = SqliteStore::open(&cas_root).expect("open sqlite store");

    let mut session = Session::new(
        "session-for-sync".to_string(),
        temp.path().display().to_string(),
        Some("default".to_string()),
    );
    session.started_at = chrono::Utc::now() - chrono::Duration::hours(1);
    sqlite_store
        .start_session(&session)
        .expect("insert session");

    let queue = SyncQueue::open(&cas_root).expect("open sync queue");
    queue.init().expect("init sync queue");

    let sessions = super::get_sessions_for_sync(&cas_root, &queue);
    assert_eq!(sessions.len(), 1, "expected one session from sqlite");
    assert_eq!(sessions[0].session_id, "session-for-sync");
}
