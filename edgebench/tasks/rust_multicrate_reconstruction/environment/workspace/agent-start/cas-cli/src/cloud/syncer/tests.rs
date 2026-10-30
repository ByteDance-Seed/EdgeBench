use std::time::Duration;

use crate::cloud::syncer::*;

#[test]
fn test_sync_result_totals() {
    let result = SyncResult {
        pushed_entries: 5,
        pushed_tasks: 3,
        pushed_rules: 2,
        pushed_skills: 1,
        pushed_sessions: 4,
        pulled_entries: 10,
        pulled_tasks: 5,
        pulled_rules: 0,
        pulled_skills: 2,
        ..Default::default()
    };

    assert_eq!(result.total_pushed(), 15); // 5+3+2+1+4
    assert_eq!(result.total_pulled(), 17);
    assert!(!result.has_errors());
}

#[test]
fn test_sync_result_with_sessions() {
    let result = SyncResult {
        pushed_sessions: 10,
        ..Default::default()
    };

    assert_eq!(result.total_pushed(), 10);
    assert_eq!(result.pushed_sessions, 10);
}

#[test]
fn test_sync_result_has_errors() {
    let mut result = SyncResult::default();
    assert!(!result.has_errors());

    result.errors.push("Test error".to_string());
    assert!(result.has_errors());
}

#[test]
fn test_config_defaults() {
    let config = CloudSyncerConfig::default();
    assert_eq!(config.timeout, Duration::from_secs(30));
    assert_eq!(config.max_retries, 5);
    assert_eq!(config.batch_size, 50);
}

#[test]
fn test_config_backoff_duration() {
    let config = CloudSyncerConfig::default();

    // First attempt: ~1000ms (plus jitter)
    let d0 = config.backoff_duration(0);
    assert!(d0.as_millis() >= 1000);
    assert!(d0.as_millis() < 1200); // Allow for jitter

    // Second attempt: ~2000ms
    let d1 = config.backoff_duration(1);
    assert!(d1.as_millis() >= 2000);

    // Third attempt: ~4000ms
    let d2 = config.backoff_duration(2);
    assert!(d2.as_millis() >= 4000);
}



#[test]
fn test_config_default_team_conflict_resolution() {
    let config = CloudSyncerConfig::default();
    assert_eq!(
        config.team_conflict_resolution,
        ConflictResolution::RemoteWins
    );
}

#[test]
fn test_conflict_action_variants() {
    // Test all ConflictAction variants exist
    let _use_remote = ConflictAction::UseRemote;
    let _use_local = ConflictAction::UseLocal;
    let _skip = ConflictAction::Skip;
}

#[test]
fn test_sync_conflict_creation() {
    use chrono::Utc;
    let conflict = SyncConflict {
        entity_type: "entry".to_string(),
        entity_id: "test-123".to_string(),
        local_updated: Utc::now(),
        remote_updated: Utc::now(),
        resolution: ConflictResolution::RemoteWins,
        action: ConflictAction::UseRemote,
    };

    assert_eq!(conflict.entity_type, "entry");
    assert_eq!(conflict.entity_id, "test-123");
    assert_eq!(conflict.resolution, ConflictResolution::RemoteWins);
    assert_eq!(conflict.action, ConflictAction::UseRemote);

    // Should not panic
    conflict.log();
}
