//! Example integration test demonstrating cas-tui-test framework
//!
//! This test shows how to use the framework for testing terminal applications.

use cas_tui_test::{
    ArtifactCollector, Key, PtyRunner, PtyRunnerConfig, SnapshotStore, VtParser, WaitExt, input,
    screen,
};
use std::time::Duration;

/// Test basic PTY spawning and output capture
#[test]
fn test_basic_echo() {
    let mut runner = PtyRunner::new();
    runner.spawn("echo", &["Hello, TUI Test!"]).unwrap();

    // Wait for output
    let result = runner.wait_for_text_timeout("Hello", Duration::from_secs(2));
    assert!(result.is_ok(), "Should find 'Hello' in output");

    // Check full output
    let output = runner.get_output();
    assert!(output.contains("TUI Test"), "Output: {}", output.as_str());
}

/// Test input DSL with cat command
#[test]
fn test_input_dsl() {
    let mut runner = PtyRunner::new();
    runner.spawn("cat", &[]).unwrap();

    // Send input using DSL
    input()
        .text("first line")
        .enter()
        .text("second line")
        .enter()
        .execute(&mut runner)
        .unwrap();

    // Wait for echo
    runner
        .wait_for_text_timeout("second line", Duration::from_secs(2))
        .unwrap();

    // Verify both lines are in output
    let output = runner.get_output();
    assert!(output.contains("first line"));
    assert!(output.contains("second line"));

    // Send EOF to exit cat
    runner.send_key(Key::CtrlD).unwrap();
}

/// Test assertion DSL with screen parsing
#[test]
fn test_assertion_dsl() {
    let mut runner = PtyRunner::new();
    runner
        .spawn("echo", &["-e", "Line1\\nLine2\\nLine3"])
        .unwrap();

    // Wait for output
    runner
        .wait_for_text_timeout("Line3", Duration::from_secs(2))
        .unwrap();

    // Use assertion DSL
    let output = runner.get_output();
    let scr = screen(&output.as_str());

    // Various assertions
    scr.assert_contains("Line1").unwrap();
    scr.assert_contains("Line2").unwrap();
    scr.assert_not_contains("Line99").unwrap();
}

/// Test VT parser with escape sequences
#[test]
fn test_vt_parser() {
    let mut runner = PtyRunner::new();
    // Use printf for ANSI escape sequences
    runner
        .spawn("printf", &["\\033[1mBold\\033[0m Normal"])
        .unwrap();

    // Wait and read
    std::thread::sleep(Duration::from_millis(100));
    let output = runner.read_available().unwrap();

    // Parse through VT parser
    let mut parser = VtParser::new(80, 24);
    parser.process(output.as_bytes());

    // Check parsed content
    let buffer = parser.buffer();
    assert!(buffer.contains_text("Bold"));
    assert!(buffer.contains_text("Normal"));
}

/// Test wait DSL with regex
#[test]
fn test_wait_regex() {
    let mut runner = PtyRunner::new();
    runner.spawn("echo", &["Count: 42"]).unwrap();

    // Wait for regex pattern
    let result = runner.wait_for_regex_timeout(r"Count:\s+\d+", Duration::from_secs(2));
    assert!(result.is_ok());
}

/// Test custom terminal size
#[test]
fn test_custom_size() {
    let config = PtyRunnerConfig::with_size(100, 30);
    let runner = PtyRunner::with_config(config);
    assert_eq!(runner.size(), (100, 30));
}

/// Test environment variable injection
#[test]
fn test_env_injection() {
    let config = PtyRunnerConfig::default().env("TEST_VAR", "custom_value");
    let mut runner = PtyRunner::with_config(config);

    runner.spawn("sh", &["-c", "echo $TEST_VAR"]).unwrap();

    runner
        .wait_for_text_timeout("custom_value", Duration::from_secs(2))
        .unwrap();
}

/// Test snapshot store operations (uses temp directory)
#[test]
fn test_snapshot_store() {
    use tempfile::TempDir;

    let dir = TempDir::new().unwrap();
    let store = SnapshotStore::with_config(
        "snapshot_test",
        cas_tui_test::SnapshotStoreConfig::default()
            .with_dir(dir.path())
            .with_update_mode(true),
    );

    // Parse some output
    let mut parser = VtParser::new(80, 24);
    parser.process(b"Hello World\nSecond Line");

    // Create snapshot
    store.assert_snapshot("test_snap", parser.buffer()).unwrap();

    // Verify snapshot file exists
    assert!(store.snapshot_path("test_snap").exists());

    // Compare (should match)
    let compare_store = SnapshotStore::with_config(
        "snapshot_test",
        cas_tui_test::SnapshotStoreConfig::default().with_dir(dir.path()),
    );
    compare_store
        .assert_snapshot("test_snap", parser.buffer())
        .unwrap();
}

/// Test artifact collection
#[test]
fn test_artifact_collection() {
    use tempfile::TempDir;

    let dir = TempDir::new().unwrap();
    let config = cas_tui_test::ArtifactConfig::with_dir(dir.path());
    let mut collector = ArtifactCollector::with_config("artifact_test", config);

    // Record some output
    collector.record_pty_output(b"Sample PTY output\nLine 2\n");

    // Record a frame
    let mut parser = VtParser::new(80, 24);
    parser.process(b"Frame content");
    collector.record_frame(parser.buffer().clone(), b"Frame content".to_vec());

    // Persist artifacts (requires final buffer)
    let paths = collector.persist(parser.buffer()).unwrap();

    // Verify files exist (paths are Option<PathBuf>)
    assert!(paths.pty_log.as_ref().map(|p| p.exists()).unwrap_or(false));
    assert!(
        paths
            .screenshot
            .as_ref()
            .map(|p| p.exists())
            .unwrap_or(false)
    );
}

/// Example test showing full workflow
#[test]
fn test_full_workflow() {
    // 1. Create runner with custom config
    let config = PtyRunnerConfig::with_size(80, 24).env("TERM", "xterm");
    let mut runner = PtyRunner::with_config(config);

    // 2. Spawn a simple interactive program
    runner.spawn("cat", &[]).unwrap();

    // 3. Send input
    input()
        .line("Hello from cas-tui-test!")
        .execute(&mut runner)
        .unwrap();

    // 4. Wait for echo
    runner
        .wait_for_text_timeout("cas-tui-test", Duration::from_secs(2))
        .unwrap();

    // 5. Assert on screen
    let output = runner.get_output();
    let scr = screen(&output.as_str());
    scr.assert_contains("Hello").unwrap();
    scr.assert_matches(r"Hello.*cas-tui-test").unwrap();

    // 6. Clean exit
    runner.send_key(Key::CtrlD).unwrap();
}
