#[test]
fn test_config_backoff_caps_at_max() {
    let config = CloudSyncerConfig::default();

    // Very high attempt should be capped at 2^6 = 64x
    let d_high = config.backoff_duration(100);
    // 1000 * 64 = 64000ms max (plus jitter)
    assert!(d_high.as_millis() < 70000);
}

#[test]
fn test_conflict_resolution_default() {
    let strategy = ConflictResolution::default();
    assert_eq!(strategy, ConflictResolution::RemoteWins);
}
