use tempfile::TempDir;

use crate::cloud::sync_queue::{EntityType, SyncOperation, SyncQueue};

fn create_test_queue() -> (TempDir, SyncQueue) { todo!() }


#[test]
fn test_coalesce_updates() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue(
            EntityType::Entry,
            "entry-1",
            SyncOperation::Upsert,
            Some(r#"{"content":"v1"}"#),
        )
        .unwrap();

    queue
        .enqueue(
            EntityType::Entry,
            "entry-1",
            SyncOperation::Upsert,
            Some(r#"{"content":"v2"}"#),
        )
        .unwrap();

    let pending = queue.pending(10, 5).unwrap();
    assert_eq!(pending.len(), 1);
    assert!(pending[0].payload.as_ref().unwrap().contains("v2"));
}



#[test]
fn test_metadata() {
    let (_temp, queue) = create_test_queue();

    assert!(queue.get_metadata("last_push").unwrap().is_none());

    queue
        .set_metadata("last_push", "2024-01-01T00:00:00Z")
        .unwrap();
    assert_eq!(
        queue.get_metadata("last_push").unwrap(),
        Some("2024-01-01T00:00:00Z".to_string())
    );

    queue
        .set_metadata("last_push", "2024-01-02T00:00:00Z")
        .unwrap();
    assert_eq!(
        queue.get_metadata("last_push").unwrap(),
        Some("2024-01-02T00:00:00Z".to_string())
    );

    queue.delete_metadata("last_push").unwrap();
    assert!(queue.get_metadata("last_push").unwrap().is_none());
}

#[test]
fn test_pending_by_type() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue(EntityType::Entry, "e1", SyncOperation::Upsert, None)
        .unwrap();
    queue
        .enqueue(EntityType::Entry, "e2", SyncOperation::Upsert, None)
        .unwrap();
    queue
        .enqueue(EntityType::Task, "t1", SyncOperation::Upsert, None)
        .unwrap();
    queue
        .enqueue(EntityType::Rule, "r1", SyncOperation::Delete, None)
        .unwrap();

    let by_type = queue.pending_by_type(10, 5).unwrap();
    assert_eq!(by_type.entries.len(), 2);
    assert_eq!(by_type.tasks.len(), 1);
    assert_eq!(by_type.rules.len(), 1);
    assert_eq!(by_type.skills.len(), 0);
    assert_eq!(by_type.total(), 4);
}

#[test]
fn test_delete_operation() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue(
            EntityType::Entry,
            "entry-1",
            SyncOperation::Upsert,
            Some(r#"{"id":"entry-1"}"#),
        )
        .unwrap();

    queue
        .enqueue(EntityType::Entry, "entry-1", SyncOperation::Delete, None)
        .unwrap();

    let pending = queue.pending(10, 5).unwrap();
    assert_eq!(pending.len(), 1);
    assert_eq!(pending[0].operation, SyncOperation::Delete);
    assert!(pending[0].payload.is_none());
}

#[test]
fn test_team_id_enqueue_and_pending() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue(EntityType::Entry, "entry-1", SyncOperation::Upsert, None)
        .unwrap();

    queue
        .enqueue_for_team(
            EntityType::Entry,
            "entry-2",
            SyncOperation::Upsert,
            Some(r#"{"id":"entry-2"}"#),
            "team-123",
        )
        .unwrap();

    let personal = queue.pending(10, 5).unwrap();
    assert_eq!(personal.len(), 1);
    assert_eq!(personal[0].entity_id, "entry-1");
    assert!(personal[0].team_id.is_none());

    let team = queue.pending_for_team("team-123", 10, 5).unwrap();
    assert_eq!(team.len(), 1);
    assert_eq!(team[0].entity_id, "entry-2");
    assert_eq!(team[0].team_id, Some("team-123".to_string()));
}

#[test]
fn test_team_id_isolation() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue(EntityType::Entry, "entry-1", SyncOperation::Upsert, None)
        .unwrap();
    queue
        .enqueue_for_team(
            EntityType::Entry,
            "entry-1",
            SyncOperation::Upsert,
            None,
            "team-a",
        )
        .unwrap();
    queue
        .enqueue_for_team(
            EntityType::Entry,
            "entry-1",
            SyncOperation::Upsert,
            None,
            "team-b",
        )
        .unwrap();

    let all = queue.list_all(10).unwrap();
    assert_eq!(all.len(), 3);

    assert_eq!(queue.pending(10, 5).unwrap().len(), 1);
    assert_eq!(queue.pending_for_team("team-a", 10, 5).unwrap().len(), 1);
    assert_eq!(queue.pending_for_team("team-b", 10, 5).unwrap().len(), 1);
}

#[test]
fn test_drain_by_team() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue_for_team(
            EntityType::Entry,
            "e1",
            SyncOperation::Upsert,
            None,
            "team-a",
        )
        .unwrap();
    queue
        .enqueue_for_team(
            EntityType::Task,
            "t1",
            SyncOperation::Upsert,
            None,
            "team-a",
        )
        .unwrap();

    queue
        .enqueue_for_team(
            EntityType::Entry,
            "e2",
            SyncOperation::Upsert,
            None,
            "team-b",
        )
        .unwrap();

    let drained = queue.drain_by_team("team-a", 5).unwrap();
    assert_eq!(drained.len(), 2);

    assert_eq!(queue.pending_for_team("team-a", 10, 5).unwrap().len(), 0);

    assert_eq!(queue.pending_for_team("team-b", 10, 5).unwrap().len(), 1);
}


#[test]
fn test_pending_by_type_for_team() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue_for_team(
            EntityType::Entry,
            "e1",
            SyncOperation::Upsert,
            None,
            "team-123",
        )
        .unwrap();
    queue
        .enqueue_for_team(
            EntityType::Task,
            "t1",
            SyncOperation::Upsert,
            None,
            "team-123",
        )
        .unwrap();
    queue
        .enqueue_for_team(
            EntityType::Task,
            "t2",
            SyncOperation::Upsert,
            None,
            "team-123",
        )
        .unwrap();

    let by_type = queue.pending_by_type_for_team("team-123", 10, 5).unwrap();
    assert_eq!(by_type.entries.len(), 1);
    assert_eq!(by_type.tasks.len(), 2);
    assert_eq!(by_type.rules.len(), 0);
    assert_eq!(by_type.skills.len(), 0);
}

#[test]
fn test_team_coalesce_updates() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue_for_team(
            EntityType::Entry,
            "entry-1",
            SyncOperation::Upsert,
            Some(r#"{"content":"v1"}"#),
            "team-123",
        )
        .unwrap();

    queue
        .enqueue_for_team(
            EntityType::Entry,
            "entry-1",
            SyncOperation::Upsert,
            Some(r#"{"content":"v2"}"#),
            "team-123",
        )
        .unwrap();

    let pending = queue.pending_for_team("team-123", 10, 5).unwrap();
    assert_eq!(pending.len(), 1);
    assert!(pending[0].payload.as_ref().unwrap().contains("v2"));
}
