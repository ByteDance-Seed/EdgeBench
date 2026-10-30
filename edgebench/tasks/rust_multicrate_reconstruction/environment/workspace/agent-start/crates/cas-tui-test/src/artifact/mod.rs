//! Test artifacts and snapshot management
//!
//! This module provides infrastructure for snapshot testing and failure artifacts:
//!
//! - [`SnapshotStore`] - Manages snapshot files with stable directory layout
//! - [`ArtifactCollector`] - Captures debugging artifacts on test failure
//!
//! # Snapshot Testing
//!
//! ```ignore
//! use cas_tui_test::artifact::SnapshotStore;
//!
//! let store = SnapshotStore::new("my_test");
//! store.assert_snapshot("initial", &buffer)?;
//! ```
//!
//! # Environment Variables
//!
//! - `TUI_TEST_SNAPSHOT_DIR` - Override default snapshot directory
//! - `TUI_TEST_UPDATE_SNAPSHOTS` - Set to "1" to update snapshots
//! - `TUI_TEST_ARTIFACT_DIR` - Override default artifact directory

mod collector;
mod store;

pub use collector::{ArtifactCollector, ArtifactConfig, ArtifactPaths, render_buffer_ascii};
pub use store::{SnapshotError, SnapshotResult, SnapshotStore, SnapshotStoreConfig};
