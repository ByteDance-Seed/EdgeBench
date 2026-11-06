use std::path::PathBuf;

use tempfile::tempdir;

use crate::session::state::generate_session_id;
use crate::session::{SessionError, SessionManager, SessionState};

fn test_manager() -> (SessionManager, tempfile::TempDir) { todo!() }

#[test]
fn test_create_session() {
    let (mut manager, _dir) = test_manager();
    let id = manager
        .create_session("test-session", "/tmp/project")
        .unwrap();

    assert!(!id.is_empty());
    assert!(manager.active_session_id().is_some());
    assert_eq!(manager.active_session_id(), Some(id.as_str()));

    let session = manager.get_session(&id).unwrap();
    assert_eq!(session.name, "test-session");
    assert_eq!(session.project_dir, PathBuf::from("/tmp/project"));
    assert!(session.is_active());
}

#[test]
fn test_pause_session() {
    let (mut manager, _dir) = test_manager();
    let id = manager.create_session("test", "/tmp").unwrap();

    manager.pause_session(&id).unwrap();

    let session = manager.get_session(&id).unwrap();
    assert!(session.is_paused());
    assert!(session.paused_at.is_some());
    assert!(manager.active_session_id().is_none());
}

#[test]
fn test_resume_session() {
    let (mut manager, _dir) = test_manager();
    let id = manager.create_session("test", "/tmp").unwrap();
    manager.pause_session(&id).unwrap();

    manager.resume_session(&id).unwrap();

    let session = manager.get_session(&id).unwrap();
    assert!(session.is_active());
    assert!(session.paused_at.is_none());
    assert_eq!(manager.active_session_id(), Some(id.as_str()));
}

#[test]
fn test_archive_session() {
    let (mut manager, _dir) = test_manager();
    let id = manager.create_session("test", "/tmp").unwrap();

    manager.archive_session(&id).unwrap();

    let session = manager.get_session(&id).unwrap();
    assert!(session.is_archived());
    assert!(session.archived_at.is_some());
    assert!(manager.active_session_id().is_none());
}

#[test]
fn test_archive_cannot_resume() {
    let (mut manager, _dir) = test_manager();
    let id = manager.create_session("test", "/tmp").unwrap();
    manager.archive_session(&id).unwrap();

    let result = manager.resume_session(&id);
    assert!(matches!(result, Err(SessionError::InvalidTransition(_, _))));
}

#[test]
fn test_list_sessions() {
    let (mut manager, _dir) = test_manager();
    manager.create_session("session1", "/tmp/1").unwrap();
    let id2 = manager.create_session("session2", "/tmp/2").unwrap();
    // Note: session1 was auto-paused when session2 was created
    manager.pause_session(&id2).unwrap();

    // All sessions
    let all = manager.list_sessions(None);
    assert_eq!(all.len(), 2);

    // Both sessions are now paused (session1 auto-paused, session2 explicitly paused)
    let paused = manager.list_sessions(Some(SessionState::Paused));
    assert_eq!(paused.len(), 2);

    // No active sessions
    let active = manager.list_sessions(Some(SessionState::Active));
    assert_eq!(active.len(), 0);
}

#[test]
fn test_creating_new_session_pauses_active() {
    let (mut manager, _dir) = test_manager();
    let id1 = manager.create_session("session1", "/tmp/1").unwrap();
    let id2 = manager.create_session("session2", "/tmp/2").unwrap();

    // session1 should be paused
    let session1 = manager.get_session(&id1).unwrap();
    assert!(session1.is_paused());

    // session2 should be active
    let session2 = manager.get_session(&id2).unwrap();
    assert!(session2.is_active());

    assert_eq!(manager.active_session_id(), Some(id2.as_str()));
}


#[test]
fn test_delete_session() {
    let (mut manager, _dir) = test_manager();
    let id = manager.create_session("test", "/tmp").unwrap();

    manager.delete_session(&id).unwrap();

    assert!(manager.get_session(&id).is_none());
    assert!(manager.active_session_id().is_none());
}

#[test]
fn test_session_metadata() {
    let (mut manager, _dir) = test_manager();
    let id = manager.create_session("test", "/tmp").unwrap();

    {
        let session = manager.get_session_mut(&id).unwrap();
        session.set_supervisor("my-supervisor");
        session.add_worker("worker-1");
        session.add_worker("worker-2");
        session.set_epic("epic-123");
        session.set_metadata("custom", "value");
    }

    let session = manager.get_session(&id).unwrap();
    assert_eq!(session.supervisor_name, Some("my-supervisor".to_string()));
    assert_eq!(session.worker_names, vec!["worker-1", "worker-2"]);
    assert_eq!(session.epic_id, Some("epic-123".to_string()));
    assert_eq!(session.metadata.get("custom"), Some(&"value".to_string()));
}

#[test]
fn test_session_not_found() {
    let (mut manager, _dir) = test_manager();

    let result = manager.pause_session("nonexistent");
    assert!(matches!(result, Err(SessionError::NotFound(_))));
}

#[test]
fn test_session_id_format() {
    let id = generate_session_id();
    assert!(id.starts_with("fs-"));
    assert!(id.len() > 10);
}
