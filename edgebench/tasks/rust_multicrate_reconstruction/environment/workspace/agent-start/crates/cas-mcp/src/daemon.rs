//! Embedded daemon types for MCP server
//!
//! This module contains types for the embedded daemon that runs maintenance
//! tasks in the background while the MCP server is active.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::sync::atomic::{AtomicU64, Ordering};

/// Status of the embedded daemon
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct EmbeddedDaemonStatus {
    /// Whether the daemon is running
    pub running: bool,
    /// Last maintenance run timestamp
    pub last_maintenance: Option<DateTime<Utc>>,
    /// Last cloud sync timestamp
    pub last_cloud_sync: Option<DateTime<Utc>>,
    /// Next scheduled maintenance
    pub next_maintenance: Option<DateTime<Utc>>,
    /// Total observations processed this session
    pub observations_processed: usize,
    /// Total memory decay applied this session
    pub decay_applied: usize,
    /// Pending items in cloud sync queue
    pub cloud_sync_pending: usize,
    /// Whether cloud sync is available (user logged in)
    pub cloud_sync_available: bool,
    /// Items pushed to cloud this session
    pub cloud_items_pushed: usize,
    /// Items pulled from cloud this session
    pub cloud_items_pulled: usize,
    /// Seconds since last MCP request
    pub idle_seconds: u64,
    /// Whether currently idle (eligible for maintenance)
    pub is_idle: bool,
    /// Last error if any
    pub last_error: Option<String>,
}

/// Activity tracker for idle detection
#[derive(Debug)]
pub struct ActivityTracker {
    /// Timestamp of last MCP request (as unix timestamp millis)
    last_request: AtomicU64,
    /// Minimum idle time before running maintenance (seconds)
    min_idle_secs: u64,
}

impl ActivityTracker {
    /// Create a new activity tracker
    pub fn new(min_idle_secs: u64) -> Self { todo!() }

    /// Record that a request was received
    pub fn touch(&self) { todo!() }

    /// Get seconds since last request
    pub fn idle_seconds(&self) -> u64 { todo!() }

    /// Check if we've been idle long enough for maintenance
    pub fn is_idle(&self) -> bool { todo!() }
}

impl Default for ActivityTracker {
    fn default() -> Self { todo!() }
}

fn now_millis() -> u64 { todo!() }

/// Configuration for the embedded daemon
#[derive(Debug, Clone)]
pub struct EmbeddedDaemonConfig {
    /// Path to CAS root
    pub cas_root: std::path::PathBuf,
    /// How often to run full maintenance (seconds)
    pub maintenance_interval_secs: u64,
    /// How often to run cloud sync (seconds)
    pub cloud_sync_interval_secs: u64,
    /// Minimum idle time before maintenance (seconds)
    pub min_idle_secs: u64,
    /// Enable memory decay
    pub apply_decay: bool,
    /// Enable observation processing
    pub process_observations: bool,
    /// Enable cloud sync
    pub cloud_sync_enabled: bool,
    /// Batch size for operations
    pub batch_size: usize,
    // === Code indexing configuration ===
    /// Enable background code indexing
    pub index_code: bool,
    /// Paths to watch for code changes (relative to project root)
    pub code_watch_paths: Vec<std::path::PathBuf>,
    /// File extensions to index
    pub code_extensions: Vec<String>,
    /// Glob patterns to exclude from indexing
    pub code_exclude_patterns: Vec<String>,
    /// Code indexing interval (seconds)
    pub code_index_interval_secs: u64,
    /// Debounce time for file watcher (milliseconds)
    pub code_debounce_ms: u64,
}

impl Default for EmbeddedDaemonConfig {
    fn default() -> Self { todo!() }
}

/// Result from running maintenance
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct MaintenanceResult {
    /// Duration in seconds
    pub duration_secs: f64,
    /// Observations processed
    pub observations_processed: usize,
    /// Decay applied
    pub decay_applied: bool,
}

#[cfg(test)]
mod tests {
    use crate::daemon::*;

    #[test]
    fn test_activity_tracker() {
        let tracker = ActivityTracker::new(1);
        tracker.touch();
        assert!(!tracker.is_idle());
        assert!(tracker.idle_seconds() < 1);
    }


    #[test]
    fn test_daemon_status_default() {
        let status = EmbeddedDaemonStatus::default();
        assert!(!status.running);
        assert!(status.last_maintenance.is_none());
    }
}
