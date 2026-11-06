use crate::cli::hook::*;
use tempfile::TempDir;
use toml::map::Map;

#[test]
fn test_configure_creates_settings() {
    let temp = TempDir::new().unwrap();
    let result = configure_claude_hooks(temp.path(), false).unwrap();

    assert!(result); // Created new file
    assert!(temp.path().join(".claude/settings.json").exists());

    // Verify content
    let content = std::fs::read_to_string(temp.path().join(".claude/settings.json")).unwrap();
    let settings: serde_json::Value = serde_json::from_str(&content).unwrap();

    assert!(settings.get("hooks").is_some());
    assert!(settings.pointer("/hooks/SessionStart").is_some());
    assert!(settings.pointer("/hooks/SessionEnd").is_some());
    assert!(settings.pointer("/hooks/Stop").is_some());
    assert!(settings.pointer("/hooks/SubagentStop").is_some());
    assert!(settings.pointer("/hooks/PostToolUse").is_some());
    assert!(settings.pointer("/hooks/UserPromptSubmit").is_some());

    // Verify CAS Bash permissions (Claude Code 2.1.0+)
    let allow = settings
        .pointer("/permissions/allow")
        .expect("permissions.allow missing");
    let allow_arr = allow.as_array().expect("permissions.allow is not array");
    assert!(
        allow_arr.iter().any(|v| v.as_str() == Some("Bash(cas :*)")),
        "Bash(cas :*) permission missing"
    );
}

#[test]
fn test_configure_merges_existing() {
    let temp = TempDir::new().unwrap();
    let claude_dir = temp.path().join(".claude");
    std::fs::create_dir_all(&claude_dir).unwrap();

    // Create existing settings with custom content
    let existing = serde_json::json!({
        "permissions": {
            "allow": ["Read", "Write"]
        },
        "hooks": {
            "CustomHook": [{"hooks": [{"type": "command", "command": "echo custom"}]}]
        }
    });
    std::fs::write(
        claude_dir.join("settings.json"),
        serde_json::to_string_pretty(&existing).unwrap(),
    )
    .unwrap();

    // Configure CAS hooks
    let result = configure_claude_hooks(temp.path(), false).unwrap();
    assert!(!result); // Updated, not created

    // Verify merged content
    let content = std::fs::read_to_string(claude_dir.join("settings.json")).unwrap();
    let settings: serde_json::Value = serde_json::from_str(&content).unwrap();

    // CAS hooks should be added
    assert!(settings.pointer("/hooks/SessionStart").is_some());
    assert!(settings.pointer("/hooks/SessionEnd").is_some());
    assert!(settings.pointer("/hooks/Stop").is_some());
    assert!(settings.pointer("/hooks/SubagentStop").is_some());
    assert!(settings.pointer("/hooks/PostToolUse").is_some());
    assert!(settings.pointer("/hooks/UserPromptSubmit").is_some());

    // Existing permissions should be preserved and CAS permissions added
    let allow = settings
        .pointer("/permissions/allow")
        .expect("permissions.allow missing");
    let allow_arr = allow.as_array().expect("permissions.allow is not array");

    // Original permissions preserved
    assert!(
        allow_arr.iter().any(|v| v.as_str() == Some("Read")),
        "Original Read permission should be preserved"
    );
    assert!(
        allow_arr.iter().any(|v| v.as_str() == Some("Write")),
        "Original Write permission should be preserved"
    );

    // CAS permissions added
    assert!(
        allow_arr.iter().any(|v| v.as_str() == Some("Bash(cas :*)")),
        "Bash(cas :*) permission should be added"
    );
}

#[test]
fn test_configure_codex_creates_config() {
    let temp = TempDir::new().unwrap();
    let result = configure_codex_mcp_server(temp.path()).unwrap();

    assert!(result);
    let config_path = temp.path().join(".codex/config.toml");
    assert!(config_path.exists());

    let content = std::fs::read_to_string(&config_path).unwrap();
    let config: toml::Value = toml::from_str(&content).unwrap();
    let entry = config
        .get("mcp_servers")
        .and_then(|v| v.get("cas"))
        .and_then(|v| v.as_table())
        .expect("mcp_servers.cas missing");

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
                "CAS_CODEX_FALLBACK_SESSION".to_string(),
                toml::Value::String("1".to_string()),
            );
            env
        }))
    );
}


// Note: configure_mcp_server tests removed because they require the claude CLI
// which isn't available in test environments. The function now uses `claude mcp add`.
