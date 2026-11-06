#[test]
fn test_configure_codex_updates_existing_entry() {
    let temp = TempDir::new().unwrap();
    let codex_dir = temp.path().join(".codex");
    std::fs::create_dir_all(&codex_dir).unwrap();

    let content = r#"
[mcp_servers.context7]
command = "cas"
args = ["old"]
env = { CAS_LOG = "debug" }
"#;
    std::fs::write(codex_dir.join("config.toml"), content).unwrap();

    let result = configure_codex_mcp_server(temp.path()).unwrap();
    assert!(result);

    let updated = std::fs::read_to_string(codex_dir.join("config.toml")).unwrap();
    let config: toml::Value = toml::from_str(&updated).unwrap();
    let entry = config
        .get("mcp_servers")
        .and_then(|v| v.get("context7"))
        .and_then(|v| v.as_table())
        .expect("mcp_servers.context7 missing");

    assert_eq!(
        entry.get("command"),
        Some(&toml::Value::String("cas".to_string()))
    );
    assert_eq!(
        entry.get("args"),
        Some(&toml::Value::Array(vec![toml::Value::String(
            "serve".to_string()
        )]))
    );
    assert_eq!(
        entry.get("env"),
        Some(&toml::Value::Table({
            let mut env = Map::new();
            env.insert(
                "CAS_LOG".to_string(),
                toml::Value::String("debug".to_string()),
            );
            env.insert(
                "CAS_CODEX_FALLBACK_SESSION".to_string(),
                toml::Value::String("1".to_string()),
            );
            env
        }))
    );
}
