#[test]
fn test_config_save_load() {
    let temp = TempDir::new().unwrap();
    let mut config = Config::default();
    config.sync.min_helpful = 5;

    config.save(temp.path()).unwrap();
    let loaded = Config::load(temp.path()).unwrap();

    assert_eq!(loaded.sync.min_helpful, 5);
}
