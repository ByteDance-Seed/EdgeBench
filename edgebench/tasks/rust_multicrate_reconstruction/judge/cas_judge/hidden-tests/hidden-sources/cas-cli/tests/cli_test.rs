#[test]
fn test_init_already_initialized() {
    let temp = TempDir::new().unwrap();

    // First init
    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Second init without force should inform user
    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success()
        .stdout(predicate::str::contains("already initialized"));
}

#[test]
fn test_status() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    cas_cmd()
        .current_dir(&temp)
        .arg("status")
        .assert()
        .success()
        .stdout(predicate::str::contains("entries"));
}

#[test]
fn test_doctor() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    cas_cmd()
        .current_dir(&temp)
        .arg("doctor")
        .assert()
        .success()
        .stdout(predicate::str::contains("cas directory"));
}

#[test]
fn test_config_list_offline_no_auth_required() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Ensure local config command remains available without login state.
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("sync.enabled"));
}

#[test]
fn test_cloud_command_requires_auth() {
    let temp = TempDir::new().unwrap();
    let home = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    cas_cmd()
        .current_dir(&temp)
        .env("HOME", home.path())
        .args(["cloud", "status"])
        .assert()
        .failure()
        .stderr(predicate::str::contains("Not logged in"));
}

#[test]
fn test_hook_config() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Check default hook config
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "get", "hooks.capture_enabled"])
        .assert()
        .success()
        .stdout(predicate::str::contains("true"));

    // Set hook config
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "set", "hooks.capture_enabled", "false"])
        .assert()
        .success();

    // Verify it was set
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "get", "hooks.capture_enabled"])
        .assert()
        .success()
        .stdout(predicate::str::contains("false"));
}

#[test]
fn test_config_list() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Test config list
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("sync.enabled"))
        .stdout(predicate::str::contains("hooks.token_budget"));
}

#[test]
fn test_config_list_json() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Test config list with JSON output
    cas_cmd()
        .current_dir(&temp)
        .args(["--json", "config", "list"])
        .assert()
        .success()
        .stdout(predicate::str::contains("sync"))
        .stdout(predicate::str::contains("hooks"));
}

#[test]
fn test_config_set_validation() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    // Try to set invalid boolean value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "set", "sync.enabled", "notabool"])
        .assert()
        .failure();

    // Try to set invalid integer value
    cas_cmd()
        .current_dir(&temp)
        .args(["config", "set", "hooks.token_budget", "notanumber"])
        .assert()
        .failure();
}

#[test]
fn test_doctor_fix_json_before_init_errors() {
    let temp = TempDir::new().unwrap();

    cas_cmd()
        .current_dir(&temp)
        .args(["doctor", "--fix", "--json"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "`cas doctor --fix --json` is not supported before initialization",
        ));
}

#[test]
fn test_bare_factory_flags_are_parsed() {
    let temp = TempDir::new().unwrap();
    let cas_root = temp.path().join(".cas");

    cas_cmd()
        .current_dir(&temp)
        .args(["init", "--yes"])
        .assert()
        .success();

    cas_cmd()
        .current_dir(&temp)
        .env("CAS_ROOT", &cas_root)
        .args(["--new", "-w", "0"])
        .assert()
        .failure()
        .stderr(predicate::str::contains(
            "Factory mode requires an interactive terminal",
        ));
}
