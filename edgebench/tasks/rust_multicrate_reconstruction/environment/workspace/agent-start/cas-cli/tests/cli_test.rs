//! CLI integration tests

use assert_cmd::Command;
use predicates::prelude::*;
use tempfile::TempDir;

fn cas_cmd() -> Command { todo!() }

#[test]
fn test_help() {
    cas_cmd()
        .arg("--help")
        .assert()
        .success()
        .stdout(predicate::str::contains("Multi-agent coding factory"));
}

#[test]
fn test_version() {
    cas_cmd()
        .arg("--version")
        .assert()
        .success()
        .stdout(predicate::str::contains("cas"));
}

#[test]
fn test_init_yes_flag() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success()
        .stdout(predicate::str::contains("CAS initialized"));

    assert!(temp.path().join(".cas").exists());
    assert!(temp.path().join(".cas/cas.db").exists());
    // Config is now saved as TOML (preferred format)
    assert!(temp.path().join(".cas/config.toml").exists());
}

#[test]
fn test_init_json() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--json"])
        .assert()
        .success()
        .stdout(predicate::str::contains("initialized"));
}


#[test]
fn test_init_force_reinit() {
    let temp = TempDir::new().unwrap();

    // First init
    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Force reinit should succeed
    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes", "--force"])
        .assert()
        .success()
        .stdout(predicate::str::contains("CAS initialized"));
}

#[test]
fn test_init_json_already_initialized() {
    let temp = TempDir::new().unwrap();

    // First init
    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--json"])
        .assert()
        .success();

    // Second init in JSON mode
    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--json"])
        .assert()
        .success()
        .stdout(predicate::str::contains("already_initialized"));
}


#[test]
fn test_status_verbose() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    cas_cmd()
        .current_dir(&temp)
        .args(["status", "-v"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Configuration"));
}

#[test]
fn test_config() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // List config
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("sync.enabled"));

    // Get specific value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "get", "sync.enabled"])
        .assert()
        .success()
        .stdout(predicate::str::contains("true"));

    // Set value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "set", "sync.min_helpful", "5"])
        .assert()
        .success();

    // Verify
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "get", "sync.min_helpful"])
        .assert()
        .success()
        .stdout(predicate::str::contains("5"));
}


#[test]
fn test_not_initialized_error() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .arg("status")
        .assert()
        .failure()
        .stderr(predicate::str::contains("not initialized"));
}


#[test]
fn test_status_offline_no_auth_required() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Ensure local status command remains available without login state.
    cas_cmd()
        .current_dir(&temp)
        .arg("status")
        .assert()
        .success()
        .stdout(predicate::str::contains("entries"));
}


#[test]
fn test_hook_command_session_start() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Test SessionStart hook with JSON input
    let input = r#"{"session_id":"test123","cwd":"/test","hook_event_name":"SessionStart"}"#;

    cas_cmd()
        .current_dir(&temp)
        .args(["hook", "SessionStart"])
        .write_stdin(input)
        .assert()
        .success();
}


#[test]
fn test_hook_post_tool_use() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Test PostToolUse hook with Write tool
    let input = r#"{
        "session_id": "tool-use-test",
        "cwd": "/test",
        "hook_event_name": "PostToolUse",
        "tool_name": "Write",
        "tool_input": {"file_path": "/test/file.rs", "content": "fn main() {}"}
    }"#;

    cas_cmd()
        .current_dir(&temp)
        .args(["hook", "PostToolUse"])
        .write_stdin(input)
        .assert()
        .success();
}

#[test]
fn test_hook_user_prompt_submit() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Test UserPromptSubmit hook
    let input = r#"{
        "session_id": "prompt-test",
        "cwd": "/test",
        "hook_event_name": "UserPromptSubmit",
        "user_prompt": "Help me write tests"
    }"#;

    cas_cmd()
        .current_dir(&temp)
        .args(["hook", "UserPromptSubmit"])
        .write_stdin(input)
        .assert()
        .success();
}



#[test]
fn test_config_get_set() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Get a value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "get", "sync.enabled"])
        .assert()
        .success()
        .stdout(predicate::str::contains("true"));

    // Set a value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "set", "sync.enabled", "false"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Set sync.enabled"));

    // Verify the value was set
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "get", "sync.enabled"])
        .assert()
        .success()
        .stdout(predicate::str::contains("false"));
}

#[test]
fn test_config_get_unknown_key() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Try to get unknown key
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "get", "unknown.key"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("Unknown config key"));
}


#[test]
fn test_config_list_section_filter() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Filter by section
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "list", "--section", "hooks"])
        .assert()
        .success()
        .stdout(predicate::str::contains("hooks.capture_enabled"))
        .stdout(predicate::str::contains("hooks.token_budget"));
}

#[test]
fn test_config_list_modified() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Modify a value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "set", "hooks.token_budget", "8000"])
        .assert()
        .success();

    // List only modified values
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "list", "--modified"])
        .assert()
        .success()
        .stdout(predicate::str::contains("hooks.token_budget"))
        .stdout(predicate::str::contains("8000"));
}

#[test]
fn test_config_diff() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // After init --yes with defaults, there should be no differences from defaults
    // (mcp.enabled was removed - MCP is always enabled)
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "diff"])
        .assert()
        .success()
        .stdout(predicate::str::contains("No differences"));

    // Modify a value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "set", "sync.min_helpful", "5"])
        .assert()
        .success();

    // Now there should be differences
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "diff"])
        .assert()
        .success()
        .stdout(predicate::str::contains("sync.min_helpful"))
        .stdout(predicate::str::contains("5"))
        .stdout(predicate::str::contains("default: 1"));
}

#[test]
fn test_config_describe() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Describe a config key
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "describe", "hooks.token_budget"])
        .assert()
        .success()
        .stdout(predicate::str::contains("Token Budget"))
        .stdout(predicate::str::contains("integer"))
        .stdout(predicate::str::contains("4000"));
}

#[test]
fn test_config_export_import() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Modify a value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "set", "hooks.token_budget", "6000"])
        .assert()
        .success();

    // Export config
    let export_output = cas_cmd()
        .current_dir(&temp)
        .args(["--json", "config", "list"])
        .assert()
        .success();

    // Verify exported config contains our modification
    let stdout = String::from_utf8_lossy(&export_output.get_output().stdout);
    assert!(stdout.contains("6000"));
}

#[test]
fn test_doctor_json() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    cas_cmd()
        .current_dir(&temp)
        .args(["doctor", "--json"])
        .assert()
        .success()
        .stdout(predicate::str::contains(r#""name":"cas directory""#))
        .stdout(predicate::str::contains(r#""status":"ok""#));
}

#[test]
fn test_doctor_mcp_configured() {
    let temp = TempDir::new().unwrap();
    let cas_root = temp.path().join(".cas");

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Doctor should show MCP is configured after init
    // Use CAS_ROOT to isolate from parent project's .cas
    cas_cmd()
        .current_dir(&temp)
        .env("CAS_ROOT", &cas_root)
        .arg("doctor")
        .assert()
        .success()
        .stdout(predicate::str::contains("mcp config"))
        .stdout(predicate::str::contains("MCP configured"));
}

#[test]
fn test_doctor_mcp_not_configured() {
    let temp = TempDir::new().unwrap();
    let cas_root = temp.path().join(".cas");

    // Initialize CAS
    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Delete the .mcp.json file to simulate MCP not being configured
    std::fs::remove_file(temp.path().join(".mcp.json")).unwrap();

    // Doctor should warn about MCP not being configured
    // Use CAS_ROOT to isolate from parent project's .cas
    cas_cmd()
        .current_dir(&temp)
        .env("CAS_ROOT", &cas_root)
        .arg("doctor")
        .assert()
        .success()
        .stdout(predicate::str::contains("mcp config"))
        .stdout(predicate::str::contains("MCP not configured"));
}

#[test]
fn test_doctor_fix_initializes_project() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["doctor", "--fix"])
        .assert()
        .success()
        .stdout(predicate::str::contains("auto-fix"))
        .stdout(predicate::str::contains("Initialized CAS at"));
}



#[test]
fn test_noninteractive_factory_includes_preflight_hints() {
    let temp = TempDir::new().unwrap();
    let cas_root = temp.path().join(".cas");

    cas_cmd()
        .current_dir(&temp)
        .env("CAS_ROOT", &cas_root)
        .args(["--new", "-w", "0"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "Initialize CAS first with `cas doctor --fix` (or `cas init`).",
        ));
}

#[test]
fn test_doctor_not_initialized() {
    let temp = TempDir::new().unwrap();

    // Doctor on uninitialized directory should show error
    // Use CAS_ROOT pointing to non-existent .cas to prevent finding parent project's .cas
    cas_cmd()
        .current_dir(&temp)
        .env("CAS_ROOT", temp.path().join(".cas"))
        .arg("doctor")
        .assert()
        .success()
        .stdout(predicate::str::contains("Not found"));
}
