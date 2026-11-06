use crate::config::Config;
use tempfile::TempDir;


#[test]
fn test_config_save_load() {
    let temp = TempDir::new().unwrap();
    let mut config = Config::default();
    config.sync.min_helpful = 5;

    config.save(temp.path()).unwrap();
    let loaded = Config::load(temp.path()).unwrap();

    assert_eq!(loaded.sync.min_helpful, 5);
}

#[test]
fn test_config_get_set() {
    let mut config = Config::default();

    config.set("sync.enabled", "false").unwrap();
    assert_eq!(config.get("sync.enabled"), Some("false".to_string()));

    config.set("sync.target", "/custom/path").unwrap();
    assert_eq!(config.get("sync.target"), Some("/custom/path".to_string()));
}
