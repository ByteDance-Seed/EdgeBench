#[test]
fn test_registry_has_all_sections() {
    let reg = ConfigRegistry::new();
    let sections = reg.sections();

    assert!(sections.contains(&"sync"));
    assert!(sections.contains(&"cloud"));
    assert!(sections.contains(&"hooks"));
    assert!(sections.contains(&"hooks.plan_mode"));
    assert!(sections.contains(&"tasks"));
    assert!(sections.contains(&"mcp"));
    assert!(sections.contains(&"dev"));
    assert!(sections.contains(&"embedding"));
    assert!(sections.contains(&"notifications"));
    assert!(sections.contains(&"notifications.tasks"));
    assert!(sections.contains(&"notifications.entries"));
    assert!(sections.contains(&"notifications.rules"));
    assert!(sections.contains(&"notifications.skills"));
}

#[test]
fn test_section_keys() {
    let reg = ConfigRegistry::new();

    let sync_keys = reg.section_keys("sync");
    assert!(sync_keys.contains(&"sync.enabled"));
    assert!(sync_keys.contains(&"sync.target"));
    assert!(sync_keys.contains(&"sync.min_helpful"));
}

#[test]
fn test_is_modified() {
    let reg = ConfigRegistry::new();
    let meta = reg.get("sync.enabled").unwrap();

    assert!(!meta.is_modified("true"));
    assert!(meta.is_modified("false"));
}
