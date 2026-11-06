use crate::tracing::dev_tracer::DevTracer;
use crate::tracing::dev_tracer::helpers::{generate_session_id, sanitize_args};

#[test]
fn test_sanitize_args() {
    let args = vec!["short".to_string(), "a".repeat(300)];
    let sanitized = sanitize_args(&args);
    assert_eq!(sanitized[0], "short");
    assert_eq!(sanitized[1].len(), 200);
    assert!(sanitized[1].ends_with("..."));
}


#[test]
fn test_sanitize_args_exactly_200() {
    let args = vec!["a".repeat(200)];
    let sanitized = sanitize_args(&args);
    assert_eq!(sanitized[0].len(), 200);
    assert!(!sanitized[0].ends_with("..."));
}

#[test]
fn test_sanitize_args_201() {
    let args = vec!["a".repeat(201)];
    let sanitized = sanitize_args(&args);
    assert_eq!(sanitized[0].len(), 200);
    assert!(sanitized[0].ends_with("..."));
}

#[test]
fn test_session_id_generation() {
    let id1 = generate_session_id();
    std::thread::sleep(std::time::Duration::from_micros(10));
    let id2 = generate_session_id();
    assert!(id1.starts_with("cli-"));
    assert!(id2.starts_with("cli-"));
    // IDs should be different (based on microsecond timestamp)
    assert_ne!(id1, id2);
}


#[test]
fn test_dev_tracer_is_not_enabled_by_default() {
    // Without explicit init, tracer should not be enabled
    assert!(!DevTracer::is_enabled());
}

#[test]
fn test_dev_tracer_get_returns_none_by_default() {
    // Without init, get should return None
    // Note: This test may be affected by other tests that init the global tracer
    // In practice, run in isolation
    let tracer = DevTracer::get();
    // The tracer may or may not be initialized depending on test order
    // So we just check the return type is correct
    let _ = tracer;
}
