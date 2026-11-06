#[test]
fn test_entry_type_from_str() {
    assert_eq!(
        EntryType::from_str("learning").unwrap(),
        EntryType::Learning
    );
    assert_eq!(
        EntryType::from_str("PREFERENCE").unwrap(),
        EntryType::Preference
    );
    assert_eq!(EntryType::from_str("Context").unwrap(), EntryType::Context);
    assert_eq!(
        EntryType::from_str("observation").unwrap(),
        EntryType::Observation
    );
    assert!(EntryType::from_str("invalid").is_err());
}

#[test]
fn test_preview() {
    let entry = Entry::new(
        "test".to_string(),
        "This is a long content string".to_string(),
    );
    assert_eq!(entry.preview(10), "This is...");
    assert_eq!(entry.preview(100), "This is a long content string");
}

#[test]
fn test_temporal_validity() {
    use chrono::Duration;

    let mut entry = Entry::new("test".to_string(), "content".to_string());

    // No validity bounds - always valid
    assert!(entry.is_temporally_valid());
    assert!(!entry.is_expired());

    // Set validity to past period (expired)
    let past = Utc::now() - Duration::days(10);
    let yesterday = Utc::now() - Duration::days(1);
    entry.set_validity(Some(past), Some(yesterday));
    assert!(!entry.is_temporally_valid());
    assert!(entry.is_expired());

    // Set validity to future period (not yet valid)
    let tomorrow = Utc::now() + Duration::days(1);
    let future = Utc::now() + Duration::days(10);
    entry.set_validity(Some(tomorrow), Some(future));
    assert!(!entry.is_temporally_valid());
    assert!(!entry.is_expired());

    // Set validity to current period (valid)
    let past = Utc::now() - Duration::days(1);
    let future = Utc::now() + Duration::days(1);
    entry.set_validity(Some(past), Some(future));
    assert!(entry.is_temporally_valid());
    assert!(!entry.is_expired());

    // Only valid_from (in past) - valid
    entry.set_validity(Some(past), None);
    assert!(entry.is_temporally_valid());
    assert!(!entry.is_expired());

    // Only valid_until (in future) - valid
    entry.set_validity(None, Some(future));
    assert!(entry.is_temporally_valid());
    assert!(!entry.is_expired());

    // Only valid_until (in past) - expired
    entry.set_validity(None, Some(yesterday));
    assert!(!entry.is_temporally_valid());
    assert!(entry.is_expired());
}
