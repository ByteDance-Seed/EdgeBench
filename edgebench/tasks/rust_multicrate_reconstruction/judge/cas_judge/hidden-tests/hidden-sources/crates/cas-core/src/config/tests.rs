#[test]
fn test_config_defaults() {
    let config = Config::default();
    assert!(config.sync.enabled);
    assert_eq!(config.sync.target, ".claude/rules/cas");
    assert_eq!(config.sync.min_helpful, 1);
}
