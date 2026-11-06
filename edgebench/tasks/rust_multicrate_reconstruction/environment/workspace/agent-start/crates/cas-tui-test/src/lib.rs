//! TUI Testing Framework
//!
//! A PTY-based testing framework for terminal applications.
//! Provides deterministic terminal execution with fixed size, environment,
//! and locale settings.
//!
//! # Core Components
//!
//! - [`PtyRunner`] - Spawns and controls terminal processes in a PTY (sync)
//! - [`AsyncPtyRunner`] - Async/tokio-compatible PTY runner
//! - [`ScreenBuffer`] - Represents terminal display state (grid, cursor, attributes)
//! - [`VtParser`] - Parses VT escape sequences and updates the screen buffer
//! - [`Snapshot`] - Serializable screen state for snapshot testing
//! - [`SnapshotStore`] - Manages snapshot files with stable directory layout
//! - [`ArtifactCollector`] - Captures debugging artifacts on test failure
//!
//! # DSL Modules
//!
//! - [`input`] - Input DSL for composing key/text sequences
//! - [`wait`] - Wait methods with configurable timeouts
//! - [`assert`] - Assertions for terminal output
//!
//! # Sync Example
//!
//! ```no_run
//! use cas_tui_test::{PtyRunner, input, WaitExt, screen};
//! use std::time::Duration;
//!
//! let mut runner = PtyRunner::new();
//! runner.spawn("my-tui-app", &[]).unwrap();
//!
//! // Send input using DSL
//! input().line("hello").ctrl_c().execute(&mut runner).unwrap();
//!
//! // Wait for output
//! runner.wait_for_text_timeout("welcome", Duration::from_secs(2)).unwrap();
//!
//! // Assert on screen content
//! let output = runner.get_output();
//! let scr = screen(&output.as_str());
//! scr.assert_contains("welcome").unwrap();
//! ```
//!
//! # Async Example
//!
//! ```rust,no_run
//! use cas_tui_test::{AsyncPtyRunner, Key, WaitExt};
//! use std::time::Duration;
//!
//! #[tokio::test]
//! async fn test_tui_app() {
//!     let mut runner = AsyncPtyRunner::new();
//!     runner.spawn("my-app", &["--test-mode"]).await.unwrap();
//!
//!     // Wait for startup
//!     runner.wait_for_text("Ready", Duration::from_secs(5)).await.unwrap();
//!
//!     // Send input
//!     runner.send_key(Key::Enter).await.unwrap();
//!
//!     // Wait for response
//!     runner.wait_for_text("Done", Duration::from_secs(5)).await.unwrap();
//! }
//! ```
//!
//! # Snapshot Testing Example
//!
//! ```ignore
//! use cas_tui_test::{PtyRunner, VtParser, SnapshotStore};
//!
//! let mut runner = PtyRunner::new();
//! runner.spawn("my-tui-app", &[])?;
//!
//! // Parse output into screen buffer
//! let output = runner.read_available()?;
//! let mut parser = VtParser::new(80, 24);
//! parser.process(output.as_bytes());
//!
//! // Assert against stored snapshot
//! let store = SnapshotStore::new("my_test");
//! store.assert_snapshot("initial", parser.buffer())?;
//! ```
//!
//! # Environment Variables
//!
//! - `TUI_TEST_SNAPSHOT_DIR` - Override default snapshot directory (default: "tests/snapshots")
//! - `TUI_TEST_UPDATE_SNAPSHOTS` - Set to "1" to update snapshots instead of comparing
//! - `TUI_TEST_ARTIFACT_DIR` - Override default artifact directory (default: "test-artifacts")

pub mod artifact;
pub mod assert;
pub mod async_runner;
pub mod input;
pub mod pty_runner;
pub mod screen;
pub mod wait;

// Re-export PTY runner types (sync and async)
pub use async_runner::{AsyncPtyError, AsyncPtyRunner};
pub use pty_runner::{
    HeadfulConfig, Key, OutputBuffer, PtyRunner, PtyRunnerConfig, PtyRunnerError,
};

// Re-export screen types
pub use screen::{
    Attr, Cell, CellAttrs, Color, CursorPos, DiffItem, Frame, FrameHistory, FrameMetadata, Pen,
    ScreenBuffer, Snapshot, SnapshotDiff, SnapshotMetadata, TermSize, VtParser,
};

// Re-export artifact types
pub use artifact::{
    ArtifactCollector, ArtifactConfig, ArtifactPaths, SnapshotError, SnapshotResult, SnapshotStore,
    SnapshotStoreConfig, render_buffer_ascii,
};

// Re-export input DSL
pub use input::{InputAction, InputSequence, input};

// Re-export wait DSL
pub use wait::{
    DEFAULT_POLL_INTERVAL, DEFAULT_STABLE_DURATION, DEFAULT_TIMEOUT, WaitConfig, WaitError,
    WaitExt, wait_for_regex, wait_for_text, wait_stable,
};

// Re-export assertion DSL
pub use assert::{AssertError, AssertResult, Screen, screen, screen_with_size};
