#[test]
fn test_lease_renewal() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new("agent-renew".to_string(), "Renew Test".to_string());
    store.register(&agent).unwrap();

    store
        .try_claim("task-renew", "agent-renew", 60, None)
        .unwrap();

    let before = store.get_lease("task-renew").unwrap().unwrap();
    std::thread::sleep(std::time::Duration::from_millis(10));
    store.renew_lease("task-renew", "agent-renew", 120).unwrap();
    let after = store.get_lease("task-renew").unwrap().unwrap();

    assert!(after.expires_at > before.expires_at);
    assert_eq!(after.renewal_count, 1);
}

#[test]
fn test_lease_history_revoked() {
    let (_temp, store) = create_test_store();

    let agent = Agent::new(
        "agent-revoke-hist".to_string(),
        "Revoke History".to_string(),
    );
    store.register(&agent).unwrap();

    store
        .try_claim("task-revoke-hist", "agent-revoke-hist", 600, None)
        .unwrap();

    // Mark agent as stale (revokes lease)
    store.mark_stale("agent-revoke-hist").unwrap();

    // Verify revoked event is logged
    let history = store.get_lease_history("task-revoke-hist", None).unwrap();
    assert_eq!(history.len(), 2);
    assert_eq!(history[0].event_type, "revoked");
    assert!(history[0].details.as_ref().unwrap().contains("agent_stale"));
    assert_eq!(history[1].event_type, "claimed");
}
