#[test]
fn test_registry_count() {
    let reg = ConfigRegistry::new();
    // Should have 50 options across all sections (33 + 17 notification options)
    assert!(
        reg.count() >= 50,
        "Expected 50+ config options, got {}",
        reg.count()
    );
}
