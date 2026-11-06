# cas-tui-test

A PTY-based testing framework for terminal applications in Rust.

## Features

- **PTY Runner** - Spawn terminal apps in a pseudo-terminal with fixed size, env, and locale
- **VT Parser** - Parse terminal escape sequences into a screen buffer
- **Input DSL** - Fluent builder for composing input sequences
- **Wait DSL** - Wait for text, regex patterns, or output stability
- **Assertion DSL** - Assert on screen content, positions, and regions
- **Snapshot Testing** - Compare screen output against stored snapshots
- **Artifact Collection** - Capture debugging artifacts (logs, frames, screenshots) on failure

## Installation

Add to your `Cargo.toml`:

```toml
[dev-dependencies]
cas-tui-test = { path = "../crates/cas-tui-test" }
```

## Quick Start

```rust
use cas_tui_test::{PtyRunner, input, WaitExt, screen};
use std::time::Duration;

#[test]
fn test_my_tui_app() {
    // Spawn app in PTY
    let mut runner = PtyRunner::new();
    runner.spawn("my-tui-app", &[]).unwrap();

    // Wait for app to be ready
    runner.wait_for_text_timeout("Ready>", Duration::from_secs(5)).unwrap();

    // Send input
    input()
        .line("help")       // Type "help" and press Enter
        .wait_ms(100)       // Wait 100ms
        .execute(&mut runner)
        .unwrap();

    // Wait for response
    runner.wait_for_text("Available commands").unwrap();

    // Assert on output
    let output = runner.get_output();
    let scr = screen(&output.as_str());
    scr.assert_contains("help").unwrap();
    scr.assert_contains("quit").unwrap();
}
```

## API Reference

### PTY Runner

```rust
use cas_tui_test::{PtyRunner, PtyRunnerConfig, Key};

// Create with defaults (80x24 terminal)
let mut runner = PtyRunner::new();

// Create with custom config
let config = PtyRunnerConfig::with_size(120, 40)
    .env("MY_VAR", "value")
    .cwd("/some/path");
let mut runner = PtyRunner::with_config(config);

// Spawn a process
runner.spawn("program", &["arg1", "arg2"])?;

// Send input
runner.send_input("hello\n")?;
runner.send_key(Key::Enter)?;
runner.send_key(Key::CtrlC)?;

// Read output
let output = runner.read_available()?;
println!("{}", output.as_str());

// Get all captured output
let all_output = runner.get_output();

// Control process
runner.resize(100, 30)?;
runner.kill()?;
```

### Input DSL

```rust
use cas_tui_test::input;

let seq = input()
    .text("hello")          // Raw text
    .enter()                // Press Enter
    .line("command")        // Text + Enter
    .tab()                  // Tab key
    .escape()               // Escape key
    .ctrl_c()               // Ctrl+C
    .ctrl_d()               // Ctrl+D
    .up().down()            // Arrow keys
    .left().right()
    .wait_ms(100)           // Wait 100ms
    .key(Key::PageDown);    // Any key

// Execute on runner
seq.execute(&mut runner)?;
```

### Wait DSL

```rust
use cas_tui_test::{WaitExt, WaitConfig};
use std::time::Duration;

// Wait for text (5s default timeout)
runner.wait_for_text("expected")?;

// Wait with custom timeout
runner.wait_for_text_timeout("expected", Duration::from_secs(10))?;

// Wait for regex pattern
runner.wait_for_regex(r"value:\s+\d+")?;

// Wait for output to stabilize
runner.wait_stable()?;

// Custom wait config
let config = WaitConfig::with_timeout_ms(2000)
    .poll_interval(Duration::from_millis(10))
    .stable_duration(Duration::from_millis(50));
```

### Assertion DSL

```rust
use cas_tui_test::screen;

let output = runner.get_output();
let scr = screen(&output.as_str());

// Content assertions
scr.assert_contains("expected text")?;
scr.assert_not_contains("error")?;
scr.assert_matches(r"count:\s+\d+")?;

// Row-level assertions
scr.assert_row_contains(0, "Header")?;
scr.assert_row_matches(1, r"Item \d+")?;

// Positional assertions
scr.assert_text_at(0, 5, "value")?;
scr.assert_region(0, 0, 10, 3, &[
    "Header    ",
    "Line 1    ",
    "Line 2    ",
])?;
```

### VT Parser and Screen Buffer

```rust
use cas_tui_test::{VtParser, ScreenBuffer};

// Parse terminal output
let mut parser = VtParser::new(80, 24);
parser.process(output.as_bytes());

// Access parsed screen
let buffer = parser.buffer();
println!("Cursor at: {:?}", buffer.cursor_pos());
println!("Cell at (0,0): {:?}", buffer.cell(0, 0));
println!("Line 0: {:?}", buffer.line(0));

// Check for text
assert!(buffer.contains_text("expected"));
```

### Snapshot Testing

```rust
use cas_tui_test::{SnapshotStore, VtParser};

// Parse output
let mut parser = VtParser::new(80, 24);
parser.process(output.as_bytes());

// Compare against snapshot
let store = SnapshotStore::new("my_test");
store.assert_snapshot("initial_state", parser.buffer())?;

// Update snapshots (run with TUI_TEST_UPDATE_SNAPSHOTS=1)
// $ TUI_TEST_UPDATE_SNAPSHOTS=1 cargo test
```

### Artifact Collection

```rust
use cas_tui_test::{ArtifactCollector, ArtifactConfig};

let mut collector = ArtifactCollector::new("my_test");

// Record PTY output
collector.record_pty_output(output.as_bytes());

// Record frame (for animation/history)
collector.record_frame(parser.buffer());

// On failure, persist artifacts
if test_failed {
    let paths = collector.persist()?;
    println!("PTY log: {:?}", paths.pty_log);
    println!("Screenshot: {:?}", paths.screenshot);
    println!("Frames: {:?}", paths.frames_dir);
}
```

## Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `TUI_TEST_SNAPSHOT_DIR` | Snapshot storage directory | `tests/snapshots` |
| `TUI_TEST_UPDATE_SNAPSHOTS` | Set to "1" to update snapshots | (compare mode) |
| `TUI_TEST_ARTIFACT_DIR` | Artifact output directory | `test-artifacts` |

## Artifacts on Failure

When a test fails, artifacts are saved to help debugging:

```
test-artifacts/
  my_test/
    pty.log           # Raw PTY output
    screenshot.txt    # ASCII rendering of final screen
    frames/
      frame_001.yaml  # Frame history (if recorded)
      frame_002.yaml
```

## Platform Support

- macOS (primary target)
- Linux (supported)
- Windows (not supported in v1)

## License

MIT
