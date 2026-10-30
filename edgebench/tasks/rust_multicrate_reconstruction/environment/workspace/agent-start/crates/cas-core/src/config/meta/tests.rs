use crate::config::meta::ConfigRegistry;


#[test]
fn test_registry_count() {
    let reg = ConfigRegistry::new();
    assert!(reg.count() >= 51, "Expected 51+ config options, got {}", reg.count());
}

#[test]
fn test_validate_bool() {
    let reg = ConfigRegistry::new();

    assert!(reg.validate("sync.enabled", "true").is_ok());
    assert!(reg.validate("sync.enabled", "false").is_ok());
    assert!(reg.validate("sync.enabled", "yes").is_ok());
    assert!(reg.validate("sync.enabled", "invalid").is_err());
}

#[test]
fn test_validate_int_range() {
    let reg = ConfigRegistry::new();

    assert!(reg.validate("cloud.interval_secs", "300").is_ok());
    assert!(reg.validate("cloud.interval_secs", "30").is_ok());
    assert!(reg.validate("cloud.interval_secs", "3600").is_ok());
    assert!(reg.validate("cloud.interval_secs", "10").is_err());
    assert!(reg.validate("cloud.interval_secs", "10000").is_err());
}

#[test]
fn test_search() {
    let reg = ConfigRegistry::new();

    let results = reg.search("token");
    assert!(results.len() >= 2);
}


