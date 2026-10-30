use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SessionInfo {
    /// Unique session identifier.
    pub session_id: String,
    /// Project path this session is running for.
    pub project_path: String,
    /// Current epic ID (if any).
    pub epic_id: Option<String>,
    /// Current epic title (if any).
    pub epic_title: Option<String>,
    /// Number of connected clients.
    pub client_count: usize,
    /// Number of active panes.
    pub pane_count: usize,
    /// Session creation timestamp (ISO 8601).
    pub created_at: String,
}

/// Type of client connecting to the Factory server.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ClientType {
    /// Terminal UI client (ratatui-based).
    Tui,
    /// Desktop application (Tauri).
    Desktop,
    /// Web browser client.
    Web,
}

/// Client capabilities for feature negotiation.
///
/// Clients send this in the Connect message to indicate what features they support.
/// The server uses this to decide which message types to send.
#[derive(Debug, Clone, Default, PartialEq, Eq, Serialize, Deserialize)]
pub struct ClientCapabilities {
    /// Client can handle raw PTY output (VT100 sequences).
    /// If true, server sends PaneOutput messages instead of PaneRowsUpdate.
    /// Useful for clients with native terminal emulation (e.g., ghostty-web).
    #[serde(default)]
    pub raw_pty_output: bool,
    /// Client can handle server-rendered RowData snapshots for scrollback.
    #[serde(default)]
    pub row_snapshots: bool,
}

impl ClientCapabilities {
    /// Check if all capabilities are at their default values.
    pub fn is_default(&self) -> bool { todo!() }
}

/// Session mode (live or playback).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum SessionMode {
    /// Live terminal multiplexing with real PTYs.
    Live,
    /// Recording playback mode.
    Playback,
}

/// Error codes for programmatic error handling.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ErrorCode {
    /// Protocol version mismatch.
    VersionMismatch,
    /// Invalid message format.
    InvalidMessage,
    /// Requested pane not found.
    PaneNotFound,
    /// Recording file not found.
    RecordingNotFound,
    /// Operation not allowed in current mode.
    InvalidMode,
    /// Session not found.
    SessionNotFound,
    /// Authentication failed (invalid or missing token).
    AuthFailed,
    /// Internal server error.
    Internal,
}

/// Connection quality assessment.
///
/// Used in ConnectionHealth messages to indicate overall connection status.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ConnectionQuality {
    /// Excellent connection (RTT < 50ms).
    Excellent,
    /// Good connection (RTT 50-150ms).
    Good,
    /// Fair connection (RTT 150-300ms).
    Fair,
    /// Poor connection (RTT > 300ms).
    Poor,
    /// Connection is degraded or experiencing issues.
    Degraded,
}

/// Snapshot of the current session state.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SessionState {
    /// Currently focused pane ID.
    pub focused_pane: Option<String>,
    /// All panes in the session.
    pub panes: Vec<PaneInfo>,
    /// Current epic ID (if any).
    pub epic_id: Option<String>,
    /// Current epic title (if any).
    pub epic_title: Option<String>,
    /// Terminal dimensions.
    pub cols: u16,
    /// Terminal dimensions.
    pub rows: u16,
}

/// Information about a single pane.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PaneInfo {
    /// Pane identifier.
    pub id: String,
    /// Kind of pane.
    pub kind: PaneKind,
    /// Whether this pane is currently focused.
    pub focused: bool,
    /// Display title for the pane.
    pub title: String,
    /// Whether the pane's process has exited.
    pub exited: bool,
}

/// Kind of pane in the multiplexer.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum PaneKind {
    /// Worker agent (Claude CLI).
    Worker,
    /// Supervisor agent (Claude CLI).
    Supervisor,
    /// Director panel (native TUI, no PTY).
    Director,
    /// Generic shell.
    Shell,
}

/// Data for the director panel.
///
/// This is a simplified serializable version of the internal DirectorData
/// suitable for transmission over the protocol.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct DirectorData {
    /// Ready tasks (open, not blocked).
    pub ready_tasks: Vec<TaskSummary>,
    /// In-progress tasks.
    pub in_progress_tasks: Vec<TaskSummary>,
    /// Epic tasks.
    pub epic_tasks: Vec<TaskSummary>,
    /// Active agents.
    pub agents: Vec<AgentSummary>,
    /// Recent activity events.
    pub activity: Vec<ActivityEvent>,
    /// Git changes by source.
    pub changes: Vec<SourceChanges>,
}

/// Summary of a task for director display.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TaskSummary {
    /// Task ID.
    pub id: String,
    /// Task title.
    pub title: String,
    /// Task status.
    pub status: String,
    /// Priority (0 = critical, 4 = backlog).
    pub priority: u8,
    /// Assigned agent ID.
    pub assignee: Option<String>,
    /// Task type (task, bug, feature, epic, chore).
    pub task_type: String,
    /// Parent epic ID.
    pub epic: Option<String>,
    /// Branch name (for epics).
    pub branch: Option<String>,
}

/// Summary of an agent for director display.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct AgentSummary {
    /// Agent ID.
    pub id: String,
    /// Agent name.
    pub name: String,
    /// Agent status.
    pub status: String,
    /// Current task ID (if any).
    pub current_task: Option<String>,
    /// Latest activity description.
    pub latest_activity: Option<String>,
    /// Last heartbeat ISO timestamp.
    pub last_heartbeat: Option<String>,
}

/// Activity event for director display.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct ActivityEvent {
    /// Event type.
    pub event_type: String,
    /// Event summary.
    pub summary: String,
    /// Session/agent ID.
    pub session_id: Option<String>,
    /// Task ID.
    pub task_id: Option<String>,
    /// ISO timestamp.
    pub created_at: String,
}

/// Git changes from a source (main repo or worktree).
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct SourceChanges {
    /// Source name (e.g., "main" or worker name).
    pub source_name: String,
    /// Filesystem path to this source's root directory.
    #[serde(default)]
    pub source_path: String,
    /// Agent name if this is a worktree.
    pub agent_name: Option<String>,
    /// File changes.
    pub changes: Vec<FileChange>,
    /// Total lines added.
    pub total_added: usize,
    /// Total lines removed.
    pub total_removed: usize,
}

/// A single file change.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct FileChange {
    /// File path relative to repo root.
    pub file_path: String,
    /// Lines added.
    pub lines_added: usize,
    /// Lines removed.
    pub lines_removed: usize,
    /// Change status (modified, added, deleted, renamed, untracked).
    pub status: String,
    /// Whether the change is staged.
    pub staged: bool,
}

// =============================================================================
// Terminal Row Data (for incremental updates)
// =============================================================================

/// A single terminal row with pre-rendered style runs.
///
/// Style runs are a compact representation where consecutive cells with
/// the same styling are grouped together, reducing bandwidth.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct RowData {
    /// Row index (0-indexed from top of visible area).
    pub row: u16,
    /// Style runs for this row (consecutive cells with same style).
    pub runs: Vec<StyleRun>,
}

/// A cached row for scrollback caching beyond the viewport.
///
/// Used in `PaneSnapshot.cache_rows` to provide extra rows that clients
/// can cache for smoother scrolling.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct CacheRow {
    /// Absolute row position in the scrollback buffer.
    pub screen_row: u32,
    /// Text content of the row.
    pub text: String,
    /// Style runs for rendering (same format as RowData).
    pub style_runs: Vec<StyleRun>,
}

/// A run of text with consistent styling.
///
/// Instead of sending per-cell data, we group consecutive cells that share
/// the same foreground, background, and style flags into a single run.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct StyleRun {
    /// Text content (UTF-8 string of consecutive cells).
    pub text: String,
    /// Foreground color RGB.
    pub fg: (u8, u8, u8),
    /// Background color RGB.
    pub bg: (u8, u8, u8),
    /// Style flags (bold, italic, etc.) - uses STYLE_* constants.
    pub flags: u32,
}

impl StyleRun {
    /// Create a new style run with default colors.
    pub fn new(text: impl Into<String>) -> Self { todo!() }

    /// Create a style run with full styling.
    pub fn with_style(
        text: impl Into<String>,
        fg: (u8, u8, u8),
        bg: (u8, u8, u8),
        flags: u32,
    ) -> Self { todo!() }
}

// =============================================================================
// Playback Types
// =============================================================================

/// Metadata about a recording file.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct PlaybackMetadata {
    /// Recording duration in milliseconds.
    pub duration_ms: u64,
    /// Number of keyframes for seeking.
    pub keyframe_count: usize,
    /// Terminal dimensions.
    pub cols: u16,
    /// Terminal dimensions.
    pub rows: u16,
    /// Agent name.
    pub agent_name: String,
    /// Session ID.
    pub session_id: String,
    /// Agent role (supervisor, worker, primary).
    pub agent_role: String,
    /// Recording creation timestamp (ISO 8601).
    pub created_at: String,
}

/// Complete terminal state snapshot for playback.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TerminalSnapshot {
    /// Grid of cells in row-major order.
    pub cells: Vec<TerminalCell>,
    /// Cursor position.
    pub cursor: CursorPosition,
    /// Terminal columns.
    pub cols: u16,
    /// Terminal rows.
    pub rows: u16,
}

/// A single terminal cell.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub struct TerminalCell {
    /// Unicode codepoint (0 for empty).
    pub codepoint: u32,
    /// Foreground color RGB.
    pub fg: (u8, u8, u8),
    /// Background color RGB.
    pub bg: (u8, u8, u8),
    /// Style flags (bold, italic, etc.).
    pub flags: u32,
    /// Character width (1 or 2 for wide chars).
    pub width: u8,
}

impl Default for TerminalCell {
    fn default() -> Self { todo!() }
}

/// Cursor position in the terminal.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub struct CursorPosition {
    /// Column (0-indexed).
    pub x: u16,
    /// Row (0-indexed).
    pub y: u16,
}

// Style flag constants - must match ghostty-web's CellFlags enum
/// Bold text style.
pub const STYLE_BOLD: u32 = 1 << 0;
/// Italic text style.
pub const STYLE_ITALIC: u32 = 1 << 1;
/// Underline text style.
pub const STYLE_UNDERLINE: u32 = 1 << 2;
/// Strikethrough text style.
pub const STYLE_STRIKETHROUGH: u32 = 1 << 3;
/// Inverse/reverse video style.
pub const STYLE_INVERSE: u32 = 1 << 4;
/// Invisible text style.
pub const STYLE_INVISIBLE: u32 = 1 << 5;
/// Blink text style.
pub const STYLE_BLINK: u32 = 1 << 6;
/// Faint/dim text style.
pub const STYLE_FAINT: u32 = 1 << 7;

impl TerminalSnapshot {
    /// Create an empty snapshot with given dimensions.
    pub fn empty(cols: u16, rows: u16) -> Self { todo!() }
}
