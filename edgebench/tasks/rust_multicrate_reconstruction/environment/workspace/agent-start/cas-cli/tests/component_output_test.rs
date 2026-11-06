//! Integration tests for CLI command output.
//!
//! Tests that commands produce correct output in piped mode (no TTY),
//! respect NO_COLOR, and produce clean snapshots.
//!
//! Includes PtyRunner-based tests that verify output in a real terminal.

use assert_cmd::Command;
use cas_tui_test::{PtyRunner, PtyRunnerConfig, WaitExt, screen};
use predicates::prelude::*;
use std::time::Duration;
use tempfile::TempDir;

fn cas_cmd() -> Command { todo!() }

fn cas_in_dir(dir: &TempDir) -> Command { todo!() }

fn init_cas(dir: &TempDir) { todo!() }

// ============================================================================
// Piped output tests — stdout is not a TTY (assert_cmd captures it)
// ============================================================================

#[test]
fn doctor_piped_no_ansi() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let output = cas_in_dir(&temp)
        .arg("doctor")
        .output()
        .expect("failed to run cas doctor");

    let stdout = String::from_utf8(output.stdout).unwrap();
    // Piped output should contain no ANSI escape sequences
    assert!(
        !stdout.contains('\x1b'),
        "Piped output contains ANSI escape codes:\n{stdout}"
    );
    // Should contain key doctor output
    assert!(
        stdout.contains("Doctor") || stdout.contains("doctor") || stdout.contains("Store"),
        "Doctor output missing expected content:\n{stdout}"
    );
}


#[test]
fn status_piped_no_ansi() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let output = cas_in_dir(&temp)
        .arg("status")
        .output()
        .expect("failed to run cas status");

    let stdout = String::from_utf8(output.stdout).unwrap();
    assert!(
        !stdout.contains('\x1b'),
        "Piped status output contains ANSI escape codes:\n{stdout}"
    );
}

#[test]
fn status_no_color_env() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let output = cas_in_dir(&temp)
        .arg("status")
        .env("NO_COLOR", "1")
        .output()
        .expect("failed to run cas status");

    let stdout = String::from_utf8(output.stdout).unwrap();
    assert!(
        !stdout.contains('\x1b'),
        "NO_COLOR=1 status output contains ANSI escape codes:\n{stdout}"
    );
}

// ============================================================================
// Content assertions for piped output
// ============================================================================

#[test]
fn doctor_piped_content() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    cas_in_dir(&temp)
        .arg("doctor")
        .assert()
        .success()
        .stdout(predicate::str::contains("Store").or(predicate::str::contains("store")));
}

#[test]
fn version_piped_no_ansi() {
    let output = cas_cmd()
        .arg("--version")
        .output()
        .expect("failed to run cas --version");

    let stdout = String::from_utf8(output.stdout).unwrap();
    assert!(
        !stdout.contains('\x1b'),
        "Version output contains ANSI escape codes:\n{stdout}"
    );
    assert!(
        stdout.contains("cas"),
        "Version output missing 'cas': {stdout}"
    );
}


// ============================================================================
// Snapshot tests for CLI output
// ============================================================================



// ============================================================================
// PtyRunner integration tests — real terminal (TTY) output
// ============================================================================

fn cas_bin_path() -> String { todo!() }

fn pty_cas_in_dir(dir: &TempDir, args: &[&str]) -> PtyRunner { todo!() }

#[test]
fn pty_doctor_output() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let mut runner = pty_cas_in_dir(&temp, &["doctor"]);

    // Wait for doctor output to appear
    let result = runner.wait_for_text_timeout("doctor", Duration::from_secs(10));
    assert!(result.is_ok(), "Should find 'doctor' in PTY output");

    let output = runner.get_output().as_str();
    let scr = screen(&output);
    scr.assert_contains("doctor").unwrap();
}

#[test]
fn pty_status_output() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let mut runner = pty_cas_in_dir(&temp, &["status"]);

    // Wait for status output
    let result = runner.wait_for_text_timeout("cas", Duration::from_secs(10));
    assert!(result.is_ok(), "Should find 'cas' in PTY status output");

    let output = runner.get_output().as_str();
    let scr = screen(&output);
    scr.assert_contains("cas").unwrap();
}

#[test]
fn pty_doctor_has_expected_sections() {
    let temp = TempDir::new().unwrap();
    init_cas(&temp);

    let mut runner = pty_cas_in_dir(&temp, &["doctor"]);

    // Wait for the output to stabilize
    runner
        .wait_for_text_timeout("checks", Duration::from_secs(10))
        .unwrap();

    let output = runner.get_output().as_str();
    let scr = screen(&output);

    // Verify key sections are present
    scr.assert_contains("database").unwrap();
    scr.assert_contains("schema").unwrap();
}

// ============================================================================
// Redaction helpers for snapshot stability
// ============================================================================

/// Redact dynamic values from CLI output for stable snapshots.
///
/// Replaces file paths, timestamps, byte sizes, and other
/// machine-specific values with placeholders.
fn redact_dynamic_values(s: &str) -> String { todo!() }
