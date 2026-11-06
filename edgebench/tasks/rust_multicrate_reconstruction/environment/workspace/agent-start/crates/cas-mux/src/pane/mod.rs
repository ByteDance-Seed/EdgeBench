//! Pane abstraction using ghostty_vt for terminal emulation
//!
//! A pane combines:
//! - A PTY process (optional - director pane is native)
//! - A ghostty_vt Terminal for state management
//! - Metadata (agent name, role, etc.)

mod snapshot;
mod style;
mod tests;

use crate::error::{Error, Result};
use crate::harness::SupervisorCli;
use crate::pane::style::{cell_style_to_ratatui, debug_log_enabled, styles_equal};
use crate::pty::{Pty, PtyConfig, PtyEvent, TeamsSpawnConfig};
pub use cas_factory_protocol::TerminalSnapshot;
use ghostty_vt::{CellStyle, Rgb, Terminal};
use ratatui::style::Style;
use ratatui::text::{Line, Span};
use std::borrow::Cow;
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;

use cas_recording::{RecordingWriter, WriterConfig};

/// Unique identifier for a pane
pub type PaneId = String;

/// The kind of pane
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum PaneKind {
    /// Worker agent (Claude/Codex CLI)
    Worker,
    /// Supervisor agent (Claude/Codex CLI)
    Supervisor,
    /// Director (native TUI, no PTY)
    Director,
    /// Generic shell
    Shell,
}

impl PaneKind {
    pub fn as_str(&self) -> &'static str { todo!() }
}

/// Backend for a pane — either a PTY (Claude/Codex interactive) or
/// none (director pane).
pub enum PaneBackend {
    /// No backend (director pane — rendered natively)
    None,
    /// PTY-based interactive terminal (Claude, Codex)
    Pty(Pty),
}

/// A pane in the multiplexer
pub struct Pane {
    /// Unique identifier (usually agent name)
    id: PaneId,
    /// What kind of pane
    kind: PaneKind,
    /// The ghostty_vt terminal (handles escape sequences, cursor, colors)
    pub(crate) terminal: Terminal,
    /// Process backend
    backend: PaneBackend,
    /// Whether this pane has focus
    focused: bool,
    /// Title for display
    title: String,
    /// Color for the pane border (hex)
    color: Option<String>,
    /// Whether the process has exited
    exited: bool,
    /// Exit code if exited
    exit_code: Option<i32>,
    /// Terminal dimensions
    pub(crate) rows: u16,
    pub(crate) cols: u16,
    /// Optional recording writer for session capture
    recorder: Option<Arc<Mutex<RecordingWriter>>>,
    /// Whether to force all rows dirty on next take (for new client sync)
    force_all_dirty: bool,
    /// Last known total scrollback lines (for scroll detection)
    pub(crate) last_total_scrollback: u32,
    /// Sequence counter for incremental updates (pane-scoped)
    pub(crate) seq_counter: u64,
}

impl Pane {
    /// Create a new pane with a specific backend.
    fn new_with_backend(
        id: impl Into<String>,
        title: impl Into<String>,
        kind: PaneKind,
        backend: PaneBackend,
        rows: u16,
        cols: u16,
    ) -> Result<Self> { todo!() }

    /// Create a new pane with a PTY
    pub fn with_pty(
        id: impl Into<String>,
        kind: PaneKind,
        pty: Pty,
        rows: u16,
        cols: u16,
    ) -> Result<Self> { todo!() }

    /// Create a director pane (no PTY)
    pub fn director(id: impl Into<String>, rows: u16, cols: u16) -> Result<Self> { todo!() }

    /// Create a shell pane running the user's default shell (or a specific command).
    pub fn shell(
        name: &str,
        cwd: PathBuf,
        shell_command: Option<&str>,
        rows: u16,
        cols: u16,
    ) -> Result<Self> { todo!() }

    #[allow(clippy::too_many_arguments)]
    #[allow(clippy::too_many_arguments)]
    pub fn worker(
        name: &str,
        cwd: PathBuf,
        cas_root: Option<&PathBuf>,
        supervisor_name: &str,
        cli: SupervisorCli,
        model: Option<&str>,
        rows: u16,
        cols: u16,
        teams: Option<&TeamsSpawnConfig>,
    ) -> Result<Self> { todo!() }

    #[allow(clippy::too_many_arguments)]
    pub fn supervisor(
        name: &str,
        cwd: PathBuf,
        cas_root: Option<&PathBuf>,
        rows: u16,
        cols: u16,
        cli: SupervisorCli,
        worker_cli: SupervisorCli,
        worker_names: &[String],
        model: Option<&str>,
        teams: Option<&TeamsSpawnConfig>,
    ) -> Result<Self> { todo!() }

    fn push_supervisor_env(
        env: &mut Vec<(String, String)>,
        cli: SupervisorCli,
        worker_names_csv: &Option<String>,
    ) { todo!() }

    pub fn id(&self) -> &str { todo!() }

    pub fn cols(&self) -> u16 { todo!() }

    pub fn rows(&self) -> u16 { todo!() }

    pub fn kind(&self) -> &PaneKind { todo!() }

    pub fn title(&self) -> &str { todo!() }

    pub fn set_title(&mut self, title: impl Into<String>) { todo!() }

    pub fn color(&self) -> Option<&str> { todo!() }

    pub fn set_color(&mut self, color: impl Into<String>) { todo!() }

    pub fn is_focused(&self) -> bool { todo!() }

    pub fn set_focused(&mut self, focused: bool) { todo!() }

    pub fn mark_all_dirty(&mut self) { todo!() }

    pub(crate) fn take_force_all_dirty(&mut self) -> bool { todo!() }

    pub fn has_exited(&self) -> bool { todo!() }

    pub fn exit_code(&self) -> Option<i32> { todo!() }

    pub fn size(&self) -> (u16, u16) { todo!() }

    pub fn cursor_position(&self) -> (u16, u16) { todo!() }

    pub fn resize(&mut self, rows: u16, cols: u16) -> Result<()> { todo!() }

    pub fn feed(&mut self, data: &[u8]) -> Result<()> { todo!() }

    /// Strip literal cursor-position report echoes such as `^[[1;1R`.
    ///
    /// Some agent CLIs emit this as plain text when probing terminal support,
    /// which creates visual noise in pane output.
    fn strip_literal_cursor_reports(data: &[u8]) -> Cow<'_, [u8]> { todo!() }

    fn literal_cursor_report_len(data: &[u8]) -> Option<usize> { todo!() }

    pub fn dump_viewport(&self) -> Result<String> { todo!() }

    pub fn dump_row(&self, row: u16) -> Result<String> { todo!() }

    pub fn row_styles(&self, row: u16) -> Result<Vec<CellStyle>> { todo!() }

    pub fn row_as_line(&self, row: u16) -> Result<Line<'static>> { todo!() }

    pub fn viewport_as_lines(&self) -> Result<Vec<Line<'static>>> { todo!() }

    pub fn poll(&mut self) -> Option<PtyEvent> { todo!() }

    pub fn drain_output(&mut self) -> (Vec<u8>, Vec<PtyEvent>) { todo!() }

    pub async fn write(&self, data: &[u8]) -> Result<()> { todo!() }

    pub async fn send_line(&self, line: &str) -> Result<()> { todo!() }

    pub async fn inject_prompt(&self, prompt: &str) -> Result<()> { todo!() }

    pub async fn interrupt(&self) -> Result<()> { todo!() }

    pub fn scroll(&mut self, delta: i32) -> Result<()> { todo!() }

    pub fn scroll_to_top(&mut self) -> Result<()> { todo!() }

    pub fn scroll_to_bottom(&mut self) -> Result<()> { todo!() }

    pub fn kill(&mut self) { todo!() }

    pub async fn start_recording(
        &mut self,
        session_id: impl Into<String>,
        config: WriterConfig,
    ) -> Result<()> { todo!() }

    pub async fn stop_recording(&mut self) -> Result<Option<PathBuf>> { todo!() }

    async fn generate_keyframe(&mut self) -> Result<()> { todo!() }

    pub async fn record_output(&mut self, data: &[u8]) -> Result<()> { todo!() }

    pub fn is_recording(&self) -> bool { todo!() }
}
