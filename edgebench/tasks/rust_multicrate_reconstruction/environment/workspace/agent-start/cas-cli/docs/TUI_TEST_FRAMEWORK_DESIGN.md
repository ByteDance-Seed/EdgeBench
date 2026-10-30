# TUI Test Framework - API Design Document

**Task**: cas-3d11
**Epic**: cas-1510 - TUI testing framework (Rust, reusable)
**Author**: loyal-bear
**Status**: Approved

## Decisions (2026-01-31)

| Question | Decision |
|----------|----------|
| Crate name | `cas-tui-test` |
| VT parser | `vte` crate (standard, well-maintained) |
| Snapshot format | YAML (readable for diffs) |
| Style assertions | Deferred to v2 |
| Image snapshots | Deferred to v2 |

## Overview

A Rust crate for PTY-driven TUI testing that enables deterministic end-to-end tests for terminal applications. Primary target is CAS Factory TUI, but designed for reuse across Rust terminal apps.

## Design Principles

1. **Tokio-first**: All async operations use tokio runtime
2. **Builder pattern**: Fluent API for test configuration
3. **DSL for clarity**: Concise input/assertion syntax
4. **Deterministic**: Fixed terminal size, env, locale control
5. **Artifact-rich failures**: Capture frames, logs, screenshots on failure

## Crate Name

`cas-tui-test`

---

## Module Layout

```
tui_test/
├── lib.rs              # Public API exports
├── runner/
│   ├── mod.rs          # PTY runner orchestration
│   ├── pty.rs          # PTY spawn/control (portable_pty wrapper)
│   ├── process.rs      # Process lifecycle management
│   └── env.rs          # Environment/locale control
├── screen/
│   ├── mod.rs          # Screen buffer types
│   ├── buffer.rs       # ScreenBuffer implementation
│   ├── cell.rs         # Cell/character representation
│   ├── parser.rs       # VT sequence parser (vte/ghostty_vt)
│   └── diff.rs         # Screen diffing for snapshots
├── input/
│   ├── mod.rs          # Input DSL
│   ├── keys.rs         # Key definitions (ctrl, alt, special)
│   ├── sequence.rs     # Input sequence builder
│   └── timing.rs       # Delays, waits, timeouts
├── assert/
│   ├── mod.rs          # Assertion API
│   ├── text.rs         # Text/regex matchers
│   ├── cursor.rs       # Cursor position assertions
│   ├── region.rs       # Region-based assertions
│   └── style.rs        # Style/color assertions (optional v1)
├── snapshot/
│   ├── mod.rs          # Snapshot testing
│   ├── capture.rs      # Frame capture
│   ├── storage.rs      # Snapshot file I/O
│   ├── compare.rs      # Snapshot comparison
│   └── update.rs       # Snapshot update mode
├── artifact/
│   ├── mod.rs          # Failure artifacts
│   ├── frames.rs       # Frame history
│   ├── log.rs          # PTY log capture
│   └── render.rs       # ASCII/image render
└── prelude.rs          # Common imports
```

---

## Core Data Model

### ScreenBuffer

The central data structure representing terminal state:

```rust
/// Terminal screen buffer with full cell state
#[derive(Clone, Debug)]
pub struct ScreenBuffer {
    /// Grid of cells (row-major order)
    cells: Vec<Vec<Cell>>,
    /// Terminal dimensions
    size: TermSize,
    /// Current cursor position
    cursor: CursorPos,
    /// Cursor visibility
    cursor_visible: bool,
    /// Scrollback buffer (optional)
    scrollback: Option<Vec<Vec<Cell>>>,
    /// Frame metadata
    metadata: FrameMetadata,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct TermSize {
    pub cols: u16,
    pub rows: u16,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub struct CursorPos {
    pub row: u16,
    pub col: u16,
}

#[derive(Clone, Debug)]
pub struct FrameMetadata {
    /// Monotonic frame number
    pub frame_id: u64,
    /// Capture timestamp
    pub timestamp: std::time::Instant,
    /// Bytes processed to reach this state
    pub bytes_processed: usize,
}
```

### Cell

Individual terminal cell with character and style:

```rust
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Cell {
    /// Unicode grapheme (may be multi-codepoint)
    pub grapheme: String,
    /// Cell width (1 for normal, 2 for wide chars)
    pub width: u8,
    /// Foreground color
    pub fg: Color,
    /// Background color
    pub bg: Color,
    /// Text attributes
    pub attrs: CellAttrs,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq, Default)]
pub struct CellAttrs {
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub blink: bool,
    pub reverse: bool,
    pub hidden: bool,
    pub strikethrough: bool,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Color {
    Default,
    Indexed(u8),
    Rgb(u8, u8, u8),
}
```

### Frame & FrameHistory

For artifact capture and debugging:

```rust
/// A captured frame with full state
#[derive(Clone, Debug)]
pub struct Frame {
    pub buffer: ScreenBuffer,
    pub raw_output: Vec<u8>,  // Raw PTY output that produced this
}

/// Rolling buffer of recent frames
pub struct FrameHistory {
    frames: VecDeque<Frame>,
    max_frames: usize,  // Default: 10
}
```

### Snapshot

For snapshot testing:

```rust
/// Serializable snapshot for comparison
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Snapshot {
    /// Snapshot name/identifier
    pub name: String,
    /// Terminal size at capture
    pub size: TermSize,
    /// Text content (rows of strings)
    pub content: Vec<String>,
    /// Optional: style information
    pub styles: Option<Vec<Vec<CellStyle>>>,
    /// Metadata
    pub metadata: SnapshotMetadata,
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct SnapshotMetadata {
    pub created_at: String,  // ISO8601
    pub framework_version: String,
}
```

---

## Public API

### TuiTest Builder

Main entry point with fluent configuration:

```rust
use tui_test::prelude::*;

// Basic usage
let test = TuiTest::new("my-tui-app")
    .args(["--config", "test.toml"])
    .size(80, 24)
    .timeout(Duration::from_secs(10))
    .build()
    .await?;

// Full configuration
let test = TuiTest::new("cas-factory")
    .args(["--mode", "test"])
    .env("TERM", "xterm-256color")
    .env("LC_ALL", "en_US.UTF-8")
    .size(120, 40)
    .working_dir("/tmp/test-workspace")
    .timeout(Duration::from_secs(30))
    .frame_history(20)  // Keep last 20 frames
    .on_failure(ArtifactMode::Full)  // Capture everything on failure
    .build()
    .await?;
```

### TuiTestBuilder

```rust
pub struct TuiTestBuilder {
    command: String,
    args: Vec<String>,
    env: HashMap<String, String>,
    size: TermSize,
    working_dir: Option<PathBuf>,
    timeout: Duration,
    frame_history_size: usize,
    artifact_mode: ArtifactMode,
}

impl TuiTestBuilder {
    pub fn new(command: impl Into<String>) -> Self;
    pub fn args<I, S>(self, args: I) -> Self
        where I: IntoIterator<Item = S>, S: Into<String>;
    pub fn env(self, key: impl Into<String>, value: impl Into<String>) -> Self;
    pub fn size(self, cols: u16, rows: u16) -> Self;
    pub fn working_dir(self, path: impl Into<PathBuf>) -> Self;
    pub fn timeout(self, duration: Duration) -> Self;
    pub fn frame_history(self, count: usize) -> Self;
    pub fn on_failure(self, mode: ArtifactMode) -> Self;

    /// Build and spawn the PTY process
    pub async fn build(self) -> Result<TuiTestRunner, TuiTestError>;
}

#[derive(Clone, Copy, Debug, Default)]
pub enum ArtifactMode {
    /// No artifacts
    None,
    /// Last frame only
    #[default]
    LastFrame,
    /// All captured frames + PTY log
    Full,
}
```

### TuiTestRunner

The main test driver:

```rust
pub struct TuiTestRunner {
    // Internal state (opaque)
}

impl TuiTestRunner {
    // === Input Methods ===

    /// Send raw bytes to PTY
    pub async fn send(&mut self, data: impl AsRef<[u8]>) -> Result<(), TuiTestError>;

    /// Send a key press
    pub async fn key(&mut self, key: Key) -> Result<(), TuiTestError>;

    /// Send multiple keys
    pub async fn keys(&mut self, keys: impl IntoIterator<Item = Key>) -> Result<(), TuiTestError>;

    /// Type text (as if user typed it)
    pub async fn type_text(&mut self, text: &str) -> Result<(), TuiTestError>;

    /// Execute input sequence from DSL
    pub async fn input(&mut self, seq: InputSequence) -> Result<(), TuiTestError>;

    // === Wait Methods ===

    /// Wait for a condition with timeout
    pub async fn wait_for<F>(&mut self, condition: F) -> Result<(), TuiTestError>
        where F: Fn(&ScreenBuffer) -> bool;

    /// Wait for text to appear anywhere on screen
    pub async fn wait_for_text(&mut self, text: &str) -> Result<(), TuiTestError>;

    /// Wait for regex match
    pub async fn wait_for_regex(&mut self, pattern: &str) -> Result<(), TuiTestError>;

    /// Wait fixed duration (use sparingly)
    pub async fn wait(&mut self, duration: Duration) -> Result<(), TuiTestError>;

    /// Wait for screen to stabilize (no changes for N ms)
    pub async fn wait_stable(&mut self, duration: Duration) -> Result<(), TuiTestError>;

    // === Screen Access ===

    /// Get current screen buffer
    pub fn screen(&self) -> &ScreenBuffer;

    /// Get frame history
    pub fn frames(&self) -> &FrameHistory;

    // === Assertions ===

    /// Assert using fluent API
    pub fn assert(&self) -> Assertions<'_>;

    // === Snapshots ===

    /// Capture snapshot for comparison
    pub fn snapshot(&self, name: &str) -> Result<(), TuiTestError>;

    /// Capture snapshot of a region
    pub fn snapshot_region(&self, name: &str, region: Region) -> Result<(), TuiTestError>;

    // === Lifecycle ===

    /// Check if process is still running
    pub fn is_running(&self) -> bool;

    /// Get process exit status (if exited)
    pub fn exit_status(&self) -> Option<ExitStatus>;

    /// Terminate the process
    pub async fn terminate(self) -> Result<TestResult, TuiTestError>;
}
```

### Input DSL

Ergonomic input construction:

```rust
use tui_test::input::*;

// Using builder
let seq = InputSequence::new()
    .key(Key::Ctrl('c'))
    .wait_ms(100)
    .type_text("hello")
    .key(Key::Enter)
    .wait_for_text("Ready")
    .key(Key::Tab)
    .keys([Key::Down, Key::Down, Key::Enter]);

// Using macro (optional, more concise)
let seq = input! {
    ctrl+c,
    wait 100ms,
    type "hello",
    enter,
    wait_for "Ready",
    tab,
    down, down, enter,
};

// Execute
runner.input(seq).await?;
```

### Key Definitions

```rust
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Key {
    // Printable
    Char(char),

    // Modifiers + char
    Ctrl(char),
    Alt(char),
    CtrlAlt(char),

    // Special keys
    Enter,
    Tab,
    Backspace,
    Escape,

    // Arrow keys
    Up,
    Down,
    Left,
    Right,

    // Navigation
    Home,
    End,
    PageUp,
    PageDown,
    Insert,
    Delete,

    // Function keys
    F(u8),  // F1-F12
}

impl Key {
    /// Convert to escape sequence bytes
    pub fn to_bytes(&self) -> Vec<u8>;
}
```

### Assertions API

Fluent assertion builder:

```rust
// Text assertions
runner.assert()
    .text_contains("Welcome")
    .text_at(0, 0, "Title")
    .text_matches(r"Status: \w+")
    .line(5).contains("Item 1")
    .line(5).starts_with(">")
    .no_text("Error");

// Cursor assertions
runner.assert()
    .cursor_at(10, 5)
    .cursor_visible()
    .cursor_in_region(Region::new(0, 0, 80, 10));

// Region assertions
runner.assert()
    .region(Region::new(0, 0, 40, 10))
        .contains("Panel A")
        .not_empty();

// Combined
runner.assert()
    .text_contains("Ready")
    .cursor_visible()
    .line(0).eq("=== My App ===");
```

```rust
pub struct Assertions<'a> {
    runner: &'a TuiTestRunner,
}

impl<'a> Assertions<'a> {
    // Text
    pub fn text_contains(self, text: &str) -> Self;
    pub fn text_at(self, row: u16, col: u16, text: &str) -> Self;
    pub fn text_matches(self, regex: &str) -> Self;
    pub fn no_text(self, text: &str) -> Self;
    pub fn line(self, row: u16) -> LineAssertion<'a>;

    // Cursor
    pub fn cursor_at(self, row: u16, col: u16) -> Self;
    pub fn cursor_visible(self) -> Self;
    pub fn cursor_hidden(self) -> Self;
    pub fn cursor_in_region(self, region: Region) -> Self;

    // Region
    pub fn region(self, region: Region) -> RegionAssertion<'a>;

    // Execute all assertions (panics on failure with diagnostics)
    pub fn check(self);

    // Execute and return Result
    pub fn try_check(self) -> Result<(), AssertionError>;
}

#[derive(Clone, Copy, Debug)]
pub struct Region {
    pub start_col: u16,
    pub start_row: u16,
    pub end_col: u16,
    pub end_row: u16,
}
```

### Snapshot Testing

```rust
// Capture and compare
runner.snapshot("initial_screen")?;

// After some actions...
runner.key(Key::Enter).await?;
runner.wait_stable(Duration::from_millis(100)).await?;
runner.snapshot("after_enter")?;

// Region snapshot
runner.snapshot_region("status_bar", Region::new(0, 23, 80, 24))?;
```

Snapshot configuration via environment:
- `TUI_TEST_UPDATE_SNAPSHOTS=1` - Update snapshots instead of comparing
- `TUI_TEST_SNAPSHOT_DIR=path` - Custom snapshot directory (default: `tests/snapshots`)

Snapshot file format (YAML for readability):
```yaml
name: initial_screen
size: { cols: 80, rows: 24 }
content:
  - "=== My Application ==="
  - ""
  - "  Status: Ready"
  - ""
  # ... remaining rows
metadata:
  created_at: "2026-01-31T10:30:00Z"
  framework_version: "0.1.0"
```

---

## Error Handling

```rust
#[derive(Debug, thiserror::Error)]
pub enum TuiTestError {
    #[error("Failed to spawn PTY: {0}")]
    SpawnError(#[source] std::io::Error),

    #[error("Timeout after {0:?} waiting for: {1}")]
    Timeout(Duration, String),

    #[error("Process exited unexpectedly with status: {0:?}")]
    ProcessExited(Option<i32>),

    #[error("Assertion failed: {0}")]
    AssertionFailed(AssertionError),

    #[error("Snapshot mismatch for '{name}': {diff}")]
    SnapshotMismatch { name: String, diff: String },

    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}
```

---

## Example Test

```rust
use tui_test::prelude::*;
use std::time::Duration;

#[tokio::test]
async fn test_factory_tui_navigation() -> Result<(), TuiTestError> {
    // Setup
    let mut runner = TuiTest::new("cas-factory")
        .args(["--test-mode"])
        .size(120, 40)
        .timeout(Duration::from_secs(30))
        .build()
        .await?;

    // Wait for startup
    runner.wait_for_text("Factory TUI").await?;
    runner.snapshot("startup")?;

    // Navigate to workers panel
    runner.key(Key::Tab).await?;
    runner.wait_stable(Duration::from_millis(50)).await?;

    // Assertions
    runner.assert()
        .text_contains("Workers")
        .cursor_visible()
        .check();

    // Spawn a worker
    runner.key(Key::Char('s')).await?;
    runner.wait_for_text("Worker spawned").await?;

    runner.snapshot("worker_spawned")?;

    // Cleanup
    let result = runner.terminate().await?;
    assert!(result.success());

    Ok(())
}
```

---

## Tokio Compatibility

All async methods are designed for tokio runtime:

```rust
// In Cargo.toml
[dependencies]
tui-test = { version = "0.1" }
tokio = { version = "1", features = ["rt-multi-thread", "macros"] }

// In tests
#[tokio::test]
async fn my_test() {
    // TuiTest works seamlessly with tokio
}

// Or with custom runtime
#[test]
fn my_sync_test() {
    let rt = tokio::runtime::Runtime::new().unwrap();
    rt.block_on(async {
        let runner = TuiTest::new("app").build().await.unwrap();
        // ...
    });
}
```

---

## Dependencies (Proposed)

```toml
[dependencies]
# PTY handling
portable-pty = "0.8"

# Terminal parsing (choose one based on cas-aa21 decision)
# Option A: vte crate
vte = "0.13"
# Option B: ghostty_vt wrapper (if cas-aa21 completes)
# ghostty-vt = { path = "../ghostty-vt" }

# Async runtime
tokio = { version = "1", features = ["rt", "time", "sync", "process"] }

# Serialization for snapshots
serde = { version = "1", features = ["derive"] }
serde_yaml = "0.9"

# Regex for assertions
regex = "1"

# Error handling
thiserror = "1"

[dev-dependencies]
tokio = { version = "1", features = ["rt-multi-thread", "macros"] }
```

---

## Resolved Questions

All open questions resolved (see Decisions table at top):
- Crate name: `cas-tui-test`
- VT parser: `vte` crate
- Snapshot format: YAML
- Style assertions: v2
- Image snapshots: v2

---

## Next Steps

1. [ ] Review and approve this design (cas-3d11)
2. [ ] Implement PTY runner + process control (cas-7b33)
3. [ ] Implement screen buffer + VT parser
4. [ ] Implement input DSL
5. [ ] Implement assertions
6. [ ] Implement snapshot testing
7. [ ] Integration tests with CAS Factory TUI
