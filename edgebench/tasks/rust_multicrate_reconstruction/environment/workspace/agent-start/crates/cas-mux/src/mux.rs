//! Main multiplexer
//!
//! Manages multiple panes, handles input routing, and coordinates rendering.

use crate::error::{Error, Result};
use crate::harness::SupervisorCli;
use crate::pane::{Pane, PaneId, PaneKind};
use crate::pty::{PtyEvent, TeamsSpawnConfig};
use cas_factory_protocol::ServerMessage;
use indexmap::IndexMap;
use std::collections::HashMap;
use std::path::PathBuf;
use tokio::sync::mpsc;

/// Configuration for the multiplexer
#[derive(Debug, Clone)]
pub struct MuxConfig {
    /// Working directory for agents (supervisor and fallback for workers)
    pub cwd: PathBuf,
    /// Path to the .cas directory (if set, passes CAS_ROOT env var to agents)
    /// This allows workers in clone directories to access the main repo's CAS state.
    pub cas_root: Option<PathBuf>,
    /// Per-worker working directories (worker_name -> clone path)
    /// Workers not in this map use the default `cwd`.
    pub worker_cwds: HashMap<String, PathBuf>,
    /// Number of worker agents
    pub workers: usize,
    /// Worker names (if not provided, generated)
    pub worker_names: Vec<String>,
    /// Supervisor name
    pub supervisor_name: String,
    /// Supervisor CLI (codex, claude, or pi)
    pub supervisor_cli: SupervisorCli,
    /// Worker CLI (codex, claude, or pi)
    pub worker_cli: SupervisorCli,
    /// Model for supervisor (passed as --model flag)
    pub supervisor_model: Option<String>,
    /// Model for workers (passed as --model flag)
    pub worker_model: Option<String>,
    /// Include director pane
    pub include_director: bool,
    /// Terminal size
    pub rows: u16,
    pub cols: u16,
    /// Per-agent Teams spawn configs (agent_name -> config).
    /// When set, agents are spawned with native Agent Teams CLI flags.
    pub teams_configs: HashMap<String, TeamsSpawnConfig>,
}

impl Default for MuxConfig {
    fn default() -> Self { todo!() }
}

/// Events from the multiplexer
#[derive(Debug, Clone)]
pub enum MuxEvent {
    /// A pane received output (includes raw bytes for client-side rendering)
    PaneOutput {
        pane_id: PaneId,
        /// Raw PTY bytes for client-side terminal emulation
        data: Vec<u8>,
    },
    /// A pane's process exited
    PaneExited {
        pane_id: PaneId,
        exit_code: Option<i32>,
    },
    /// Focus changed
    FocusChanged { from: Option<PaneId>, to: PaneId },
    /// A pane was added
    PaneAdded { pane_id: PaneId },
    /// A pane was removed
    PaneRemoved { pane_id: PaneId },
}

/// The main terminal multiplexer
pub struct Mux {
    /// All panes, keyed by ID (insertion order preserved)
    panes: IndexMap<PaneId, Pane>,
    /// Currently focused pane
    focused: Option<PaneId>,
    /// Event sender
    event_tx: mpsc::Sender<MuxEvent>,
    /// Event receiver
    event_rx: mpsc::Receiver<MuxEvent>,
    /// Terminal size
    rows: u16,
    cols: u16,
    /// Worker CLI used for dynamic worker spawns
    worker_cli: SupervisorCli,
    /// Worker model used for dynamic worker spawns
    worker_model: Option<String>,
}

impl Mux {
    /// Create a new multiplexer
    pub fn new(rows: u16, cols: u16) -> Self { todo!() }

    /// Set CLI used for worker pane spawns.
    pub fn set_worker_cli(&mut self, worker_cli: SupervisorCli) { todo!() }

    /// Set model used for worker pane spawns.
    pub fn set_worker_model(&mut self, model: Option<String>) { todo!() }

    /// Create a multiplexer with factory configuration
    pub fn factory(config: MuxConfig) -> Result<Self> { todo!() }

    /// Add a pane to the multiplexer
    pub fn add_pane(&mut self, pane: Pane) { todo!() }

    /// Remove a pane
    pub fn remove_pane(&mut self, id: &str) -> Option<Pane> { todo!() }

    /// Get a pane by ID
    pub fn get(&self, id: &str) -> Option<&Pane> { todo!() }

    /// Get a mutable pane by ID
    pub fn get_mut(&mut self, id: &str) -> Option<&mut Pane> { todo!() }

    /// Get the focused pane
    pub fn focused(&self) -> Option<&Pane> { todo!() }

    /// Get the focused pane mutably
    pub fn focused_mut(&mut self) -> Option<&mut Pane> { todo!() }

    /// Get the focused pane ID
    pub fn focused_id(&self) -> Option<&str> { todo!() }

    /// Focus a pane by ID
    pub fn focus(&mut self, id: &str) -> bool { todo!() }

    /// Focus the next pane
    pub fn focus_next(&mut self) { todo!() }

    /// Focus the previous pane
    pub fn focus_prev(&mut self) { todo!() }

    /// Get all pane IDs
    pub fn pane_ids(&self) -> Vec<&str> { todo!() }

    /// Get all panes
    pub fn panes(&self) -> impl Iterator<Item = &Pane> { todo!(); #[allow(unreachable_code)] std::iter::empty() }

    /// Get all panes mutably
    pub fn panes_mut(&mut self) -> impl Iterator<Item = &mut Pane> { todo!(); #[allow(unreachable_code)] std::iter::empty() }

    /// Get panes of a specific kind
    pub fn panes_by_kind(&self, kind: PaneKind) -> impl Iterator<Item = &Pane> { todo!(); #[allow(unreachable_code)] std::iter::empty() }

    /// Get worker panes
    pub fn workers(&self) -> impl Iterator<Item = &Pane> { todo!(); #[allow(unreachable_code)] std::iter::empty() }

    /// Get the count of all panes
    pub fn pane_count(&self) -> usize { todo!() }

    /// Get the count of worker panes
    pub fn worker_count(&self) -> usize { todo!() }

    /// Add a worker pane at runtime
    ///
    /// This is the primary method for dynamic worker spawning.
    ///
    /// # Arguments
    /// * `name` - Worker name (also used as pane ID)
    /// * `cwd` - Working directory for the worker (typically a clone directory)
    /// * `cas_root` - Optional path to .cas directory for CAS_ROOT env var
    /// * `supervisor_name` - Name of the supervisor (enables `target: supervisor` in message action)
    ///
    /// # Returns
    /// The pane ID on success
    pub fn add_worker(
        &mut self,
        name: &str,
        cwd: PathBuf,
        cas_root: Option<&PathBuf>,
        supervisor_name: &str,
        teams: Option<&TeamsSpawnConfig>,
    ) -> Result<PaneId> { todo!() }

    /// Add a new shell pane to the mux.
    pub fn add_shell(
        &mut self,
        name: &str,
        cwd: PathBuf,
        shell_command: Option<&str>,
    ) -> Result<PaneId> { todo!() }

    /// Remove a shell pane by name.
    pub fn remove_shell(&mut self, name: &str) -> Result<()> { todo!() }

    /// Remove a worker pane by name and cleanup its PTY
    ///
    /// This is the primary method for dynamic worker shutdown.
    /// The pane's PTY will be dropped, sending SIGHUP to the process.
    pub fn remove_worker(&mut self, name: &str) -> Result<()> { todo!() }

    /// Get the supervisor pane
    pub fn supervisor(&self) -> Option<&Pane> { todo!() }

    /// Get the director pane
    pub fn director(&self) -> Option<&Pane> { todo!() }

    /// Inject a prompt into a specific pane
    pub async fn inject(&self, pane_id: &str, prompt: &str) -> Result<()> { todo!() }

    /// Inject a prompt into the focused pane
    pub async fn inject_focused(&self, prompt: &str) -> Result<()> { todo!() }

    /// Inject a prompt into all workers
    pub async fn inject_all_workers(&self, prompt: &str) -> Result<()> { todo!() }

    /// Inject a prompt into the supervisor
    pub async fn inject_supervisor(&self, prompt: &str) -> Result<()> { todo!() }

    /// Send input to the focused pane
    pub async fn send_input(&self, data: &[u8]) -> Result<()> { todo!() }

    /// Send input to a specific pane.
    pub async fn send_input_to(&self, pane_id: &str, data: &[u8]) -> Result<()> { todo!() }

    /// Poll all panes for events (non-blocking)
    ///
    /// Returns one event at a time. Call in a loop until None to process all events.
    pub fn poll(&mut self) -> Option<MuxEvent> { todo!() }

    /// Poll all panes and drain all available events at once (more efficient for multi-pane)
    ///
    /// Returns (total_bytes, events). Uses coalesced output feeding for efficiency when
    /// multiple Claude instances are generating long responses simultaneously.
    ///
    /// The MuxEvent::PaneOutput events include the raw PTY bytes so WebSocket clients
    /// can feed them to their own terminal emulators.
    pub fn poll_batch(&mut self) -> (usize, Vec<MuxEvent>) { todo!() }

    /// Get incremental terminal updates for all panes with changes.
    ///
    /// Returns a list of (pane_id, ServerMessage::PaneRowsUpdate) for each pane
    /// that has dirty rows since the last call. This is the tmux-style approach
    /// where the server renders terminals and sends pre-rendered cells to clients.
    ///
    /// Call this after `poll_batch()` to get rendered updates instead of raw bytes.
    pub fn get_incremental_updates(&mut self) -> Vec<ServerMessage> { todo!() }

    /// Get full terminal snapshot for a specific pane.
    ///
    /// Used for initial sync when a client connects or when scrollback is requested.
    pub fn get_pane_snapshot(
        &self,
        pane_id: &str,
    ) -> Option<(cas_factory_protocol::TerminalSnapshot, u32, u32)> { todo!() }

    /// Receive the next event (blocking)
    pub async fn recv(&mut self) -> Option<MuxEvent> { todo!() }

    /// Resize all panes
    pub fn resize(&mut self, rows: u16, cols: u16) -> Result<()> { todo!() }

    /// Get the terminal size
    pub fn size(&self) -> (u16, u16) { todo!() }

    /// Interrupt the focused pane
    pub async fn interrupt_focused(&self) -> Result<()> { todo!() }

    /// Interrupt a specific pane by ID
    pub async fn interrupt(&self, pane_id: &str) -> Result<()> { todo!() }

    /// Scroll the focused pane by delta lines
    ///
    /// Positive delta scrolls down (towards newer content), negative scrolls up (towards older content).
    pub fn scroll_focused(&mut self, delta: i32) -> Result<()> { todo!() }

    /// Scroll the focused pane to top of scrollback
    pub fn scroll_focused_to_top(&mut self) -> Result<()> { todo!() }

    /// Scroll the focused pane to bottom (most recent content)
    pub fn scroll_focused_to_bottom(&mut self) -> Result<()> { todo!() }

    /// Scroll a specific pane by delta lines
    pub fn scroll_pane(&mut self, pane_id: &str, delta: i32) -> Result<()> { todo!() }

    /// Scroll a specific pane and return snapshot with cache rows for smooth scrolling.
    ///
    /// This is the main entry point for handling Scroll messages with cache_window.
    /// Returns (snapshot, cache_rows, cache_start_row, scroll_offset, scrollback_lines).
    #[allow(clippy::type_complexity)]
    pub fn scroll_pane_with_cache(
        &mut self,
        pane_id: &str,
        delta: i32,
        cache_window: u32,
    ) -> Result<(
        cas_factory_protocol::TerminalSnapshot,
        Vec<cas_factory_protocol::CacheRow>,
        Option<u32>,
        u32,
        u32,
    )> { todo!() }

    /// Scroll a specific pane and return RowData snapshot with cache rows.
    ///
    /// Returns (snapshot_rows, cache_rows, cache_start_row, scroll_offset, scrollback_lines).
    #[allow(clippy::type_complexity)]
    pub fn scroll_pane_with_cache_rows(
        &mut self,
        pane_id: &str,
        delta: i32,
        cache_window: u32,
    ) -> Result<(
        Vec<cas_factory_protocol::RowData>,
        Vec<cas_factory_protocol::CacheRow>,
        Option<u32>,
        u32,
        u32,
    )> { todo!() }

    /// Get the current scroll offset for a pane (lines from bottom).
    pub fn scroll_offset(&self, pane_id: &str) -> Option<u32> { todo!() }

    /// Scroll a specific pane to bottom
    pub fn scroll_pane_to_bottom(&mut self, pane_id: &str) -> Result<()> { todo!() }

    /// Kill all panes (terminate all PTY processes)
    ///
    /// This should be called during shutdown to ensure all child processes are terminated.
    pub fn kill_all(&mut self) { todo!() }
}

#[cfg(test)]
#[path = "mux_tests/tests.rs"]
mod tests;
