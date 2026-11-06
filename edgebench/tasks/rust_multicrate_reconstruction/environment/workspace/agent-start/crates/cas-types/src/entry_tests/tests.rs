use crate::entry::*;


#[test]
fn test_new_observation() {
    let entry = Entry::new_observation(
        "2024-01-15-001".to_string(),
        "Observed file write".to_string(),
        "session-123".to_string(),
        "Write".to_string(),
    );
    assert_eq!(entry.entry_type, EntryType::Observation);
    assert_eq!(entry.session_id, Some("session-123".to_string()));
    assert_eq!(entry.source_tool, Some("Write".to_string()));
    assert!(entry.pending_extraction);
}

#[test]
fn test_feedback_score() {
    let mut entry = Entry::new("test".to_string(), "content".to_string());
    entry.helpful_count = 5;
    entry.harmful_count = 2;
    assert_eq!(entry.feedback_score(), 3);
}


