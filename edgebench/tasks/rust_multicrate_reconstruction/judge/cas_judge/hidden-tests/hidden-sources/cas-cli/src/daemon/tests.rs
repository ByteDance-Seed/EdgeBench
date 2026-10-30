#[test]
fn test_daemon_status_default() {
    let status = DaemonStatus::default();
    assert!(!status.running);
    assert!(status.last_run.is_none());
}

#[test]
fn test_observation_without_feedback_moves_to_cold() {
    let mut observation = make_entry("obs-001", EntryType::Observation, MemoryTier::Working);
    observation.helpful_count = 0;
    observation.harmful_count = 0;

    let store = make_store(vec![observation]);
    let count = apply_memory_decay(&store).unwrap();

    assert_eq!(count, 1);

    let updated = store.get("obs-001").unwrap();
    assert_eq!(updated.memory_tier, MemoryTier::Cold);
}

#[test]
fn test_very_low_stability_demotes_cold_to_archive() {
    let mut very_low_stab = make_entry("stab-001", EntryType::Learning, MemoryTier::Cold);
    very_low_stab.stability = 0.1;

    let store = make_store(vec![very_low_stab]);
    let count = apply_memory_decay(&store).unwrap();

    assert!(count >= 1);

    let updated = store.get("stab-001").unwrap();
    assert_eq!(updated.memory_tier, MemoryTier::Archive);
}

#[test]
fn test_normal_entry_no_immediate_tier_change() {
    let normal = make_entry("norm-001", EntryType::Learning, MemoryTier::Working);

    let store = make_store(vec![normal]);
    let _count = apply_memory_decay(&store).unwrap();

    let updated = store.get("norm-001").unwrap();
    assert_eq!(updated.memory_tier, MemoryTier::Working);
}

#[test]
fn test_already_archived_not_double_processed() {
    let mut archived = make_entry("arch-001", EntryType::Learning, MemoryTier::Archive);
    archived.harmful_count = 5;

    let store = make_store(vec![archived]);
    let count = apply_memory_decay(&store).unwrap();

    assert_eq!(count, 0);

    let updated = store.get("arch-001").unwrap();
    assert_eq!(updated.memory_tier, MemoryTier::Archive);
}

#[test]
fn test_boundary_stability_value() {
    let mut boundary = make_entry("bound-001", EntryType::Learning, MemoryTier::Working);
    boundary.stability = 0.3;

    let store = make_store(vec![boundary]);
    let _count = apply_memory_decay(&store).unwrap();

    let updated = store.get("bound-001").unwrap();
    assert_eq!(updated.memory_tier, MemoryTier::Working);
}
