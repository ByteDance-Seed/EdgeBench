#[test]
fn test_sanitize_args_empty() {
    let args: Vec<String> = vec![];
    let sanitized = sanitize_args(&args);
    assert!(sanitized.is_empty());
}

#[test]
fn test_session_id_format() {
    let id = generate_session_id();
    assert!(id.starts_with("cli-"));
    // Should be hex after the prefix
    let hex_part = &id[4..];
    assert!(hex_part.chars().all(|c| c.is_ascii_hexdigit()));
}
