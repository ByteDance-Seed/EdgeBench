#[test]
fn test_enqueue_and_pending() {
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
        .enqueue(
            EntityType::Task,
            "task-1",
            SyncOperation::Upsert,
            Some(r#"{"id":"task-1"}"#),
        )
        .unwrap();

    let pending = queue.pending(10, 5).unwrap();
    assert_eq!(pending.len(), 2);
    assert_eq!(pending[0].entity_id, "entry-1");
    assert_eq!(pending[1].entity_id, "task-1");
}

#[test]
fn test_mark_synced() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue(EntityType::Entry, "entry-1", SyncOperation::Upsert, None)
        .unwrap();

    let pending = queue.pending(10, 5).unwrap();
    assert_eq!(pending.len(), 1);

    queue.mark_synced(pending[0].id).unwrap();

    let pending = queue.pending(10, 5).unwrap();
    assert_eq!(pending.len(), 0);
}

#[test]
fn test_mark_failed_and_retry_limit() {
    let (_temp, queue) = create_test_queue();

    queue
        .enqueue(EntityType::Entry, "entry-1", SyncOperation::Upsert, None)
        .unwrap();

    let pending = queue.pending(10, 3).unwrap();
    let id = pending[0].id;

    for i in 0..3 {
        queue.mark_failed(id, &format!("Error {i}")).unwrap();
    }

    let pending = queue.pending(10, 3).unwrap();
    assert_eq!(pending.len(), 0);

    assert_eq!(queue.queue_depth().unwrap(), 1);
}

#[test]
fn test_pending_count_for_team() {
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
            EntityType::Entry,
            "e2",
            SyncOperation::Upsert,
            None,
            "team-123",
        )
        .unwrap();
    queue
        .enqueue_for_team(
            EntityType::Entry,
            "e3",
            SyncOperation::Upsert,
            None,
            "other-team",
        )
        .unwrap();

    assert_eq!(queue.pending_count_for_team("team-123", 5).unwrap(), 2);
    assert_eq!(queue.pending_count_for_team("other-team", 5).unwrap(), 1);
    assert_eq!(queue.pending_count_for_team("nonexistent", 5).unwrap(), 0);
}
