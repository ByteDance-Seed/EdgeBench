//! Embedded daemon for MCP server
//!
//! Runs maintenance tasks in the background while the MCP server is active.
//! Includes idle detection to avoid running during active conversations.
//! Also handles cloud sync when user is logged in.
//!
//! # Architecture
//!
//! The daemon types (EmbeddedDaemonStatus, ActivityTracker, EmbeddedDaemonConfig,
//! MaintenanceResult) are defined in `cas-mcp` for cross-crate sharing.
//! This module provides the implementation that depends on CLI-specific modules.

use std::sync::Arc;
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::Duration;

use chrono::DateTime;
use chrono::Utc;
use tokio::sync::RwLock;

// Import types from cas-mcp
pub use cas_mcp::{ActivityTracker, EmbeddedDaemonConfig, EmbeddedDaemonStatus};

use crate::cloud::{
    CloudConfig, CloudCoordinator, CloudSyncer, CloudSyncerConfig, SyncQueue, SyncResult,
};
use crate::daemon::{CodeWatcher, DaemonConfig, DaemonRunResult, WatcherConfig};
use crate::error::CasError;
use crate::mcp::socket::{self, DaemonEvent, DaemonResponse};
use crate::orchestration::names as friendly_names;
use crate::store::open_agent_store;
use crate::store::{SqliteStore, open_rule_store, open_skill_store, open_store, open_task_store};
use crate::types::{Agent, AgentRole};

/// Extension trait for EmbeddedDaemonConfig to convert to DaemonConfig
///
/// This is CLI-specific since DaemonConfig is defined in cas-cli.
pub trait EmbeddedDaemonConfigExt {
    /// Convert to standard DaemonConfig for running maintenance
    fn to_daemon_config(&self) -> DaemonConfig;
}

impl EmbeddedDaemonConfigExt for EmbeddedDaemonConfig {
    fn to_daemon_config(&self) -> DaemonConfig { todo!() }
}

/// Background daemon runner for the MCP server
///
/// This struct orchestrates background maintenance tasks while the MCP server
/// is running. It uses types from `cas-mcp` but contains CLI-specific logic
/// for running maintenance, cloud sync, and embedding generation.
pub struct EmbeddedDaemon {
    config: EmbeddedDaemonConfig,
    activity: Arc<ActivityTracker>,
    status: Arc<RwLock<EmbeddedDaemonStatus>>,
    shutdown: Arc<AtomicBool>,
    /// Cloud syncer (if user is logged in)
    cloud_syncer: Option<Arc<CloudSyncer>>,
    /// Cloud coordinator for real-time agent registration/heartbeat
    cloud_coordinator: RwLock<Option<CloudCoordinator>>,
    /// Code watcher (if code indexing is enabled)
    code_watcher: Option<Arc<std::sync::Mutex<CodeWatcher>>>,
    /// MCP proxy engine for hot-reload (set after server startup)
    #[cfg(feature = "mcp-proxy")]
    proxy: RwLock<Option<Arc<cmcp_core::ProxyEngine>>>,
    /// Last known mtime of .cas/proxy.toml for change detection
    #[cfg(feature = "mcp-proxy")]
    proxy_config_mtime: std::sync::Mutex<Option<std::time::SystemTime>>,
    /// Agent ID for heartbeat (set after registration)
    agent_id: RwLock<Option<String>>,
    /// PID → session ID mapping for hooks to look up their session
    /// Key is Claude Code's PID, value is the session ID
    pid_sessions: RwLock<std::collections::HashMap<u32, String>>,
}

impl EmbeddedDaemon {
    /// Create a new embedded daemon
    pub fn new(config: EmbeddedDaemonConfig) -> Self { todo!() }

    /// Set the agent ID for heartbeat tracking
    pub async fn set_agent_id(&self, id: String) { todo!() }

    /// Set the proxy engine for hot-reload watching
    #[cfg(feature = "mcp-proxy")]
    pub async fn set_proxy(&self, proxy: Arc<cmcp_core::ProxyEngine>) { todo!() }

    /// Check if proxy.toml has changed since last check, reload if so
    #[cfg(feature = "mcp-proxy")]
    async fn check_proxy_config_reload(&self) { todo!() }

    /// Get the activity tracker for use by the MCP service
    pub fn activity_tracker(&self) -> Arc<ActivityTracker> { todo!() }

    /// Get current status
    pub async fn status(&self) -> EmbeddedDaemonStatus { todo!() }

    /// Signal shutdown
    pub fn shutdown(&self) { todo!() }

    /// Run the background daemon loop using proper Tokio intervals
    pub async fn run(self: Arc<Self>) -> Result<(), CasError> { todo!() }

    /// Run code indexing cycle
    async fn run_code_index_cycle(&self) -> Result<(), CasError> { todo!() }

    /// Run full maintenance cycle
    async fn run_maintenance(&self) -> Result<DaemonRunResult, CasError> { todo!() }

    /// Trigger immediate maintenance (ignores idle check)
    pub async fn trigger_maintenance(&self) -> Result<DaemonRunResult, CasError> { todo!() }

    /// Handle events from hooks via Unix socket
    async fn handle_socket_event(&self, event: DaemonEvent) -> DaemonResponse { todo!() }

    /// Register an agent with the given session_id
    ///
    /// The agent_name is passed from the hook's environment (CAS_AGENT_NAME in Claude Code process).
    /// If not provided, falls back to generating a friendly name.
    ///
    /// The agent_role is passed from the hook's environment (CAS_AGENT_ROLE set by factory mode).
    /// The cc_pid is the Claude Code process's PID (the process that sent the event).
    async fn register_agent(
        &self,
        session_id: String,
        agent_name: Option<String>,
        agent_role: Option<String>,
        cc_pid: u32,
        clone_path: Option<String>,
    ) { todo!() }

    /// Send agent heartbeat to keep agent alive
    ///
    /// Agent registration is handled via Unix socket events from hooks.
    /// Heartbeat only sends keepalive for the registered agent.
    ///
    /// When agent_id is None (e.g. this daemon lost the socket race in factory
    /// mode), tries to adopt the agent by matching our Claude Code parent PID
    /// against agent records in the database.
    ///
    /// Retries up to 3 times with backoff on failure, since heartbeat
    /// failures under SQLite lock contention can cause workers to be
    /// incorrectly marked stale in multi-agent factory sessions.
    async fn send_agent_heartbeat(&self) { todo!() }

    /// Run cloud sync cycle
    async fn run_cloud_sync(&self) -> Result<SyncResult, CasError> { todo!() }

    /// Trigger immediate cloud sync (ignores idle check)
    pub async fn trigger_cloud_sync(&self) -> Result<SyncResult, CasError> { todo!() }
}

/// Initialize cloud syncer if user is logged in
fn init_cloud_syncer(cas_root: &std::path::Path) -> Option<Arc<CloudSyncer>> { todo!() }

fn init_cloud_coordinator(cas_root: &std::path::Path) -> Option<CloudCoordinator> { todo!() }

/// Initialize code watcher if code indexing is enabled
fn init_code_watcher(config: &EmbeddedDaemonConfig) -> Option<Arc<std::sync::Mutex<CodeWatcher>>> { todo!() }

/// Get sessions that need to be synced to cloud
fn get_sessions_for_sync(
    cas_root: &std::path::Path,
    queue: &SyncQueue,
) -> Vec<crate::types::Session> { todo!() }

/// Spawn the embedded daemon as a background task
pub fn spawn_daemon(
    config: EmbeddedDaemonConfig,
) -> (Arc<EmbeddedDaemon>, tokio::task::JoinHandle<()>) { todo!() }

#[cfg(test)]
#[path = "daemon_tests/tests.rs"]
mod tests;
