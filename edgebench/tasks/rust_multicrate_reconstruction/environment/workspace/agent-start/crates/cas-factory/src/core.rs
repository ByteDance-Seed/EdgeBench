//! Core factory orchestration logic.
//!
//! FactoryCore manages PTY sessions for multiple Claude Code agents,
//! providing a clean API for spawning and managing workers.

use std::collections::HashMap;
use std::path::PathBuf;

use cas_mux::{Mux, MuxEvent, PaneKind};
use cas_recording::WriterStats;
use thiserror::Error;

use crate::config::FactoryConfig;
use crate::recording::RecordingManager;

/// Unique identifier for a pane
pub type PaneId = String;

/// Errors from factory operations
#[derive(Error, Debug)]
pub enum FactoryError {
    /// Worker already exists
    #[error("Worker '{0}' already exists")]
    WorkerExists(String),

    /// Worker not found
    #[error("Worker '{0}' not found")]
    WorkerNotFound(String),

    /// Session not found
    #[error("Session '{0}' not found")]
    SessionNotFound(String),

    /// Supervisor already spawned
    #[error("Supervisor already spawned")]
    SupervisorExists,

    /// Supervisor not spawned yet
    #[error("Supervisor not spawned")]
    NoSupervisor,

    /// Mux error
    #[error("Mux error: {0}")]
    Mux(String),

    /// IO error
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

/// Result type for factory operations
pub type Result<T> = std::result::Result<T, FactoryError>;

/// Events from the factory
#[derive(Debug, Clone)]
pub enum FactoryEvent {
    /// A pane received output
    PaneOutput { pane_id: PaneId, data: Vec<u8> },
    /// A pane's process exited
    PaneExited {
        pane_id: PaneId,
        exit_code: Option<i32>,
    },
    /// Focus changed
    FocusChanged { from: Option<PaneId>, to: PaneId },
    /// A pane was added (could be worker or supervisor)
    PaneAdded { pane_id: PaneId },
    /// A pane was removed
    PaneRemoved { pane_id: PaneId },
}

impl From<MuxEvent> for FactoryEvent {
    fn from(event: MuxEvent) -> Self { todo!() }
}

/// Information about a pane
#[derive(Debug, Clone)]
pub struct PaneInfo {
    /// Pane identifier (agent name)
    pub id: PaneId,
    /// Kind of pane (worker, supervisor, etc.)
    pub kind: PaneKind,
    /// Whether this pane is currently focused
    pub focused: bool,
}

/// Core factory orchestration.
///
/// Manages the lifecycle of Claude Code agent PTY sessions,
/// abstracting away the details of the underlying mux system.
pub struct FactoryCore {
    /// Terminal multiplexer
    mux: Mux,
    /// Factory configuration
    config: FactoryConfig,
    /// Supervisor name (set after spawn)
    supervisor_name: Option<String>,
    /// Worker names
    worker_names: Vec<String>,
    /// Per-worker working directories
    worker_cwds: HashMap<String, PathBuf>,
    /// CAS root directory (for CAS_ROOT env var)
    cas_root: Option<PathBuf>,
    /// Terminal dimensions
    rows: u16,
    cols: u16,
    /// Recording manager (if recording is enabled)
    recording: Option<RecordingManager>,
}

impl FactoryCore {
    /// Create a new FactoryCore with the given configuration.
    ///
    /// This initializes the mux but does not spawn any agents yet.
    /// Call `spawn_supervisor()` to start the supervisor, then
    /// `spawn_worker()` to add workers.
    ///
    /// If `config.record` is true and running within a tokio runtime,
    /// recording will be automatically enabled for all spawned agents.
    pub fn new(config: FactoryConfig) -> Result<Self> { todo!() }

    /// Set the CAS root directory.
    ///
    /// This path is passed to agents via CAS_ROOT env var,
    /// allowing workers in clone directories to access the main repo's CAS state.
    pub fn set_cas_root(&mut self, path: PathBuf) { todo!() }

    /// Spawn the supervisor agent.
    ///
    /// # Arguments
    /// * `name` - Optional name for the supervisor. If None, uses config or generates one.
    ///
    /// # Returns
    /// The pane ID on success.
    pub fn spawn_supervisor(&mut self, name: Option<&str>) -> Result<PaneId> { todo!() }

    /// Spawn a worker agent.
    ///
    /// # Arguments
    /// * `name` - Worker name (also used as pane ID)
    /// * `cwd` - Optional working directory. If None, uses config cwd.
    ///
    /// # Returns
    /// The pane ID on success.
    pub fn spawn_worker(&mut self, name: &str, cwd: Option<PathBuf>) -> Result<PaneId> { todo!() }

    /// Shutdown a worker by name.
    ///
    /// This kills the worker's PTY process, stops recording, and removes it from the mux.
    pub fn shutdown_worker(&mut self, name: &str) -> Result<()> { todo!() }

    /// Shutdown the supervisor.
    ///
    /// This kills the supervisor's PTY process, stops recording, and removes it from the mux.
    pub fn shutdown_supervisor(&mut self) -> Result<()> { todo!() }

    /// Poll for events from all panes.
    ///
    /// Returns all pending events. Call this regularly to process
    /// pane output, exit events, etc. If recording is enabled,
    /// pane output is automatically written to recordings.
    pub fn poll_events(&mut self) -> Vec<FactoryEvent> { todo!() }

    /// Get information about all panes.
    pub fn panes(&self) -> Vec<PaneInfo> { todo!() }

    /// Get the supervisor name, if spawned.
    pub fn supervisor_name(&self) -> Option<&str> { todo!() }

    /// Get the worker names.
    pub fn worker_names(&self) -> &[String] { todo!() }

    /// Get mutable access to the underlying mux.
    ///
    /// Use this for operations not exposed by FactoryCore,
    /// like sending input to panes or resizing.
    pub fn mux_mut(&mut self) -> &mut Mux { todo!() }

    /// Get read-only access to the underlying mux.
    pub fn mux(&self) -> &Mux { todo!() }

    /// Focus a specific pane by name.
    pub fn focus(&mut self, name: &str) { todo!() }

    /// Get the terminal dimensions.
    pub fn terminal_size(&self) -> (u16, u16) { todo!() }

    /// Resize all panes.
    ///
    /// Also updates recordings with resize events if recording is enabled.
    pub fn resize(&mut self, cols: u16, rows: u16) { todo!() }

    /// Check if recording is enabled.
    pub fn is_recording(&self) -> bool { todo!() }

    /// Get the recording session ID, if recording.
    pub fn recording_session_id(&self) -> Option<&str> { todo!() }

    /// Get the recordings directory, if recording.
    pub fn recordings_dir(&self) -> Option<&PathBuf> { todo!() }

    /// Stop all recordings and return statistics.
    ///
    /// This should be called when shutting down the factory to ensure
    /// all recordings are properly finalized.
    pub fn stop_all_recordings(&mut self) -> HashMap<String, WriterStats> { todo!() }

    /// Get the number of active recordings.
    pub fn active_recording_count(&self) -> usize { todo!() }
}

/// Generate a unique session ID for recordings.
fn generate_session_id() -> String { todo!() }

#[cfg(test)]
mod tests {
    use crate::core::*;

    fn test_config() -> FactoryConfig {
        FactoryConfig {
            cwd: std::env::temp_dir(),
            workers: 0,
            worker_names: vec![],
            supervisor_name: Some("test-supervisor".to_string()),
            supervisor_cli: cas_mux::SupervisorCli::Claude,
            worker_cli: cas_mux::SupervisorCli::Claude,
            supervisor_model: None,
            worker_model: None,
            enable_worktrees: false,
            worktree_root: None,
            notify: Default::default(),
            tabbed_workers: false,
            auto_prompt: Default::default(),
            record: false,
            session_id: None,
            teams_configs: std::collections::HashMap::new(),
            lead_session_id: None,
        }
    }

    #[test]
    fn test_factory_core_new() {
        let config = test_config();
        let core = FactoryCore::new(config);
        assert!(core.is_ok());

        let core = core.unwrap();
        assert!(core.supervisor_name().is_none());
        assert!(core.worker_names().is_empty());
    }

    #[test]
    fn test_spawn_worker_without_supervisor_fails() {
        let config = test_config();
        let mut core = FactoryCore::new(config).unwrap();

        let result = core.spawn_worker("worker-1", None);
        assert!(matches!(result, Err(FactoryError::NoSupervisor)));
    }


    #[test]
    fn test_spawn_supervisor_twice_fails() {
        let config = test_config();
        let mut core = FactoryCore::new(config).unwrap();

        // First spawn should succeed (but may fail due to no TTY in test)
        let first = core.spawn_supervisor(None);
        if first.is_ok() {
            // Second spawn should fail
            let second = core.spawn_supervisor(None);
            assert!(matches!(second, Err(FactoryError::SupervisorExists)));
        }
    }


    #[test]
    fn test_panes_empty_initially() {
        let config = test_config();
        let core = FactoryCore::new(config).unwrap();

        let panes = core.panes();
        assert!(panes.is_empty());
    }
}
