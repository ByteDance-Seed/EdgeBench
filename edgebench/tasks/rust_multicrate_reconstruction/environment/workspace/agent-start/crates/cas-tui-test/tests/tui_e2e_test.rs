//! Real E2E tests against a ratatui-based TUI application
//!
//! These tests demonstrate the cas-tui-test framework's ability to:
//! - Spawn and control a real TUI application
//! - Navigate menus with keyboard input
//! - Wait for screen updates
//! - Assert on rendered TUI content
//! - Use snapshot testing for visual regression
//!
//! Run with: cargo test -p cas-tui-test --test tui_e2e_test --features test-tui

#![cfg(feature = "test-tui")]

use cas_tui_test::{
    Key, PtyRunner, PtyRunnerConfig, SnapshotStore, VtParser, WaitConfig, WaitExt, input, screen,
    screen_with_size,
};
use std::time::Duration;

/// Path to the test_tui binary (built with --features test-tui)
fn test_tui_binary() -> String { todo!() }

/// Helper to wait for TUI to fully render
fn wait_for_render(runner: &mut PtyRunner) { todo!() }

fn wait_for_screen_text(
    runner: &PtyRunner,
    text: &str,
    timeout: Duration,
    cols: u16,
    rows: u16,
) -> Result<(), String> { todo!() }

/// Test: Spawn TUI and verify initial menu screen
#[test]
fn test_tui_startup() {
    let config = PtyRunnerConfig::with_size(80, 24);
    let mut runner = PtyRunner::with_config(config);

    runner.spawn(&test_tui_binary(), &[]).unwrap();
    wait_for_render(&mut runner);

    // Wait for the TUI title
    runner
        .wait_for_text_timeout("Test TUI", Duration::from_secs(5))
        .expect("TUI should show title");

    wait_for_render(&mut runner);

    // Verify menu content
    let output = runner.get_output();
    assert!(
        output.contains("Counter"),
        "Menu should show Counter option"
    );
    assert!(output.contains("Menu"), "Should show Menu header");

    // Clean exit
    runner.send_input("q").unwrap();
}

/// Test: Navigate menu with arrow keys
#[test]
fn test_menu_navigation() {
    let config = PtyRunnerConfig::with_size(80, 24);
    let mut runner = PtyRunner::with_config(config);

    runner.spawn(&test_tui_binary(), &[]).unwrap();
    wait_for_render(&mut runner);

    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .unwrap();

    // Navigate down through menu items
    for _ in 0..3 {
        runner.send_key(Key::Down).unwrap();
        std::thread::sleep(Duration::from_millis(100));
    }

    // Navigate back up
    runner.send_key(Key::Up).unwrap();
    std::thread::sleep(Duration::from_millis(100));

    // Clean exit
    runner.send_input("q").unwrap();
}

/// Test: Enter Counter screen and modify value
#[test]
fn test_counter_screen() {
    let config = PtyRunnerConfig::with_size(80, 24);
    let mut runner = PtyRunner::with_config(config);

    runner.spawn(&test_tui_binary(), &[]).unwrap();
    wait_for_render(&mut runner);

    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .unwrap();

    // Select Counter (first item)
    runner.send_key(Key::Enter).unwrap();
    wait_for_render(&mut runner);

    // Wait for Counter screen
    runner
        .wait_for_text_timeout("Counter", Duration::from_secs(3))
        .expect("Should enter Counter screen");

    // Verify counter content
    let output = runner.get_output();
    assert!(
        output.contains("Current Value") || output.contains("value"),
        "Should show current value"
    );

    // Increment counter multiple times
    for _ in 0..3 {
        runner.send_input("+").unwrap();
        std::thread::sleep(Duration::from_millis(150));
    }

    // Decrement once
    runner.send_input("-").unwrap();
    std::thread::sleep(Duration::from_millis(150));

    // Go back to menu
    runner.send_key(Key::Escape).unwrap();
    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .expect("Should return to main menu");

    // Clean exit
    runner.send_input("q").unwrap();
}

/// Test: Enter About screen and verify content

/// Test: Input screen with text entry
#[test]
fn test_input_screen() {
    let config = PtyRunnerConfig::with_size(80, 24);
    let mut runner = PtyRunner::with_config(config);

    runner.spawn(&test_tui_binary(), &[]).unwrap();
    wait_for_render(&mut runner);

    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .unwrap();

    // Navigate to Input (second item)
    runner.send_key(Key::Down).unwrap();
    std::thread::sleep(Duration::from_millis(100));
    runner.send_key(Key::Enter).unwrap();
    wait_for_render(&mut runner);

    // Wait for Input screen
    runner
        .wait_for_text_timeout("Input", Duration::from_secs(3))
        .expect("Should enter Input screen");

    // Type some text
    input().text("Hello").execute(&mut runner).unwrap();
    std::thread::sleep(Duration::from_millis(200));

    // Verify text appears
    wait_for_screen_text(&runner, "Hello", Duration::from_secs(3), 80, 24)
        .expect("Typed text should appear");

    // Submit with Enter
    runner.send_key(Key::Enter).unwrap();
    std::thread::sleep(Duration::from_millis(200));

    // Go back
    runner.send_key(Key::Escape).unwrap();
    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .expect("Should return to main menu");

    // Clean exit
    runner.send_input("q").unwrap();
}

/// Test: VT parser with real TUI output

/// Test: Vim-style navigation (j/k keys)
#[test]
fn test_vim_navigation() {
    let config = PtyRunnerConfig::with_size(80, 24);
    let mut runner = PtyRunner::with_config(config);

    runner.spawn(&test_tui_binary(), &[]).unwrap();
    wait_for_render(&mut runner);

    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .unwrap();

    // Use j/k for navigation
    runner.send_input("j").unwrap();
    std::thread::sleep(Duration::from_millis(100));
    runner.send_input("j").unwrap();
    std::thread::sleep(Duration::from_millis(100));
    runner.send_input("k").unwrap();
    std::thread::sleep(Duration::from_millis(100));

    // Select (should be on Input now)
    runner.send_key(Key::Enter).unwrap();
    wait_for_render(&mut runner);

    // Should be on Input screen
    runner
        .wait_for_text_timeout("Input", Duration::from_secs(3))
        .expect("Should navigate to Input screen with vim keys");

    // Go back and exit
    runner.send_key(Key::Escape).unwrap();
    std::thread::sleep(Duration::from_millis(200));
    runner.send_input("q").unwrap();
}

/// Test: Snapshot testing with TUI output
#[test]
fn test_tui_snapshot() {
    use tempfile::TempDir;

    let dir = TempDir::new().unwrap();
    let config = PtyRunnerConfig::with_size(80, 24);
    let mut runner = PtyRunner::with_config(config);

    runner.spawn(&test_tui_binary(), &[]).unwrap();
    wait_for_render(&mut runner);

    runner
        .wait_for_text_timeout("Menu", Duration::from_secs(3))
        .unwrap();

    wait_for_render(&mut runner);

    // Parse output
    let output = runner.read_available().unwrap();
    let mut parser = VtParser::new(80, 24);
    parser.process(output.as_bytes());

    // Create snapshot in update mode
    let store = SnapshotStore::with_config(
        "tui_snapshot_test",
        cas_tui_test::SnapshotStoreConfig::default()
            .with_dir(dir.path())
            .with_update_mode(true),
    );

    store
        .assert_snapshot("main_menu", parser.buffer())
        .expect("Should create snapshot");

    // Verify snapshot was created
    assert!(store.snapshot_path("main_menu").exists());

    // Compare against itself (should match)
    let compare_store = SnapshotStore::with_config(
        "tui_snapshot_test",
        cas_tui_test::SnapshotStoreConfig::default().with_dir(dir.path()),
    );
    compare_store
        .assert_snapshot("main_menu", parser.buffer())
        .expect("Snapshot should match");

    // Clean exit
    runner.send_input("q").unwrap();
}
