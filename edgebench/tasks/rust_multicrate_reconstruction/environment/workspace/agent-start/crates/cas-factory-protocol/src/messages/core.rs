use serde::{Deserialize, Serialize};
use std::collections::HashMap;

use crate::messages::is_zero;
use crate::messages::model::{
    CacheRow, ClientCapabilities, ClientType, ConnectionQuality, CursorPosition, DirectorData,
    ErrorCode, PaneInfo, PlaybackMetadata, RowData, SessionInfo, SessionMode, SessionState,
    TerminalSnapshot,
};
// =============================================================================
// Client Messages (Client → Server)
// =============================================================================

/// Messages sent from clients to the Factory server.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ClientMessage {
    // -------------------------------------------------------------------------
    // Connection Management
    // -------------------------------------------------------------------------
    /// Request list of available sessions (can be sent before Connect).
    ListSessions,

    /// Initial connection handshake.
    Connect {
        /// Type of client connecting.
        client_type: ClientType,
        /// Protocol version for compatibility checking.
        protocol_version: String,
        /// Authentication token for remote connections.
        /// Optional - localhost connections can skip auth.
        #[serde(default, skip_serializing_if = "Option::is_none")]
        auth_token: Option<String>,
        /// Target session ID (None = create new or use default).
        #[serde(default, skip_serializing_if = "Option::is_none")]
        session_id: Option<String>,
        /// Client capabilities for feature negotiation.
        #[serde(default, skip_serializing_if = "ClientCapabilities::is_default")]
        capabilities: ClientCapabilities,
    },

    /// Ping for latency measurement and keepalive.
    Ping {
        /// Unique ID to correlate with Pong response.
        id: u32,
    },

    /// Reconnect to an existing session after connection loss.
    ///
    /// The server will attempt to resume the session and send any
    /// missed updates since `last_seq`.
    Reconnect {
        /// Protocol version (must be compatible with server).
        protocol_version: String,
        /// Authentication token (required for remote connections).
        auth_token: Option<String>,
        /// Client type (TUI, Desktop, Web).
        client_type: ClientType,
        /// Client capabilities (same as Connect).
        capabilities: ClientCapabilities,
        /// Session ID to reconnect to.
        session_id: String,
        /// Client ID from previous connection.
        client_id: String,
        /// Last received sequence number for delta sync.
        last_seq: u64,
    },

    /// Pong response to server-initiated Ping.
    ///
    /// Clients must respond to server Ping messages with Pong
    /// for connection health monitoring.
    Pong {
        /// ID from the corresponding server Ping.
        id: u32,
    },

    // -------------------------------------------------------------------------
    // Live Mode - Terminal I/O
    // -------------------------------------------------------------------------
    /// Send keyboard input to a specific pane.
    SendInput {
        /// Target pane ID.
        pane_id: String,
        /// Raw bytes to send (terminal escape sequences included).
        data: Vec<u8>,
    },

    /// Request terminal resize for all panes.
    Resize {
        /// New column count.
        cols: u16,
        /// New row count.
        rows: u16,
    },

    /// Change focus to a specific pane.
    Focus {
        /// Target pane ID.
        pane_id: String,
    },

    /// Scroll a pane's viewport (like tmux scrollback).
    Scroll {
        /// Target pane ID.
        pane_id: String,
        /// Lines to scroll (negative = up/back, positive = down/forward).
        delta: i32,
        /// Number of extra rows to cache beyond the viewport.
        /// Default 0 = viewport only.
        #[serde(default, skip_serializing_if = "is_zero")]
        cache_window: u32,
        /// Absolute target scroll offset (lines from bottom).
        #[serde(default, skip_serializing_if = "Option::is_none")]
        target_offset: Option<u32>,
        /// Optional client-generated request ID for scroll responses.
        #[serde(default, skip_serializing_if = "Option::is_none")]
        request_id: Option<u64>,
    },

    /// Request full terminal snapshot for a pane (for initial sync or after scroll).
    RequestSnapshot {
        /// Target pane ID.
        pane_id: String,
    },

    /// Request to spawn new worker agents.
    SpawnWorkers {
        /// Number of workers to spawn.
        count: usize,
        /// Optional specific names for the workers.
        #[serde(default)]
        names: Vec<String>,
    },

    /// Request to shutdown worker agents.
    ShutdownWorkers {
        /// Number to shutdown (None = all workers).
        count: Option<usize>,
        /// Optional specific worker names to shutdown.
        #[serde(default)]
        names: Vec<String>,
        /// Force shutdown even with dirty worktree.
        #[serde(default)]
        force: bool,
    },

    /// Inject a prompt into a pane's Claude session.
    InjectPrompt {
        /// Target pane ID.
        pane_id: String,
        /// Prompt text to inject.
        prompt: String,
    },

    /// Send interrupt signal (SIGINT) to a pane's process.
    Interrupt {
        /// Target pane ID.
        pane_id: String,
    },

    /// Request refresh of director panel data.
    RefreshDirector,

    // -------------------------------------------------------------------------
    // Playback Mode
    // -------------------------------------------------------------------------
    /// Load a recording file for playback.
    PlaybackLoad {
        /// Path to the recording file.
        recording_path: String,
    },

    /// Seek to a specific timestamp in the recording.
    PlaybackSeek {
        /// Target timestamp in milliseconds from recording start.
        timestamp_ms: u64,
    },

    /// Set playback speed multiplier.
    PlaybackSetSpeed {
        /// Speed multiplier (1.0 = normal, 2.0 = 2x, 0.5 = half speed).
        speed: f32,
    },

    /// Close the current recording.
    PlaybackClose,
}

// =============================================================================
// Server Messages (Server → Client)
// =============================================================================

/// Messages sent from the Factory server to clients.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
#[serde(tag = "type", rename_all = "snake_case")]
pub enum ServerMessage {
    // -------------------------------------------------------------------------
    // Connection Management
    // -------------------------------------------------------------------------
    /// List of available sessions (response to ListSessions).
    SessionList {
        /// Available sessions.
        sessions: Vec<SessionInfo>,
    },

    /// Connection accepted response.
    Connected {
        /// Unique session identifier.
        session_id: String,
        /// Unique client identifier (for reconnection).
        client_id: u64,
        /// Current session mode.
        mode: SessionMode,
    },

    /// Pong response to client-initiated Ping.
    Pong {
        /// ID from the corresponding Ping.
        id: u32,
    },

    /// Server-initiated Ping for connection health monitoring.
    ///
    /// Clients must respond with ClientMessage::Pong.
    /// Used to measure RTT and detect stale connections.
    Ping {
        /// Unique ID to correlate with Pong response.
        id: u32,
    },

    /// Reconnection accepted response.
    ///
    /// Sent in response to ClientMessage::Reconnect when the session
    /// is successfully resumed.
    ReconnectAccepted {
        /// New client ID for this connection.
        new_client_id: String,
        /// Whether a full resync is needed (true if too many updates missed).
        resync_needed: bool,
    },

    /// Connection health metrics.
    ///
    /// Sent periodically to inform clients about connection quality.
    ConnectionHealth {
        /// Round-trip time in milliseconds.
        rtt_ms: u32,
        /// Overall connection quality assessment.
        quality: ConnectionQuality,
    },

    /// Batch of multiple messages.
    ///
    /// Used to group multiple updates into a single WebSocket frame
    /// for efficiency. Clients should process all messages in order.
    Batch {
        /// Messages in this batch.
        messages: Vec<ServerMessage>,
    },

    /// Error response.
    Error {
        /// Error code for programmatic handling.
        code: ErrorCode,
        /// Human-readable error message.
        message: String,
    },

    // -------------------------------------------------------------------------
    // Boot Progress (sent before Connected)
    // -------------------------------------------------------------------------
    /// Boot progress during server initialization (sent before Connected).
    BootProgress {
        /// Step name (e.g., "Loading configuration").
        step: String,
        /// Step number (1-based).
        step_num: u8,
        /// Total steps.
        total_steps: u8,
        /// Whether step completed.
        completed: bool,
    },

    /// Agent spawn progress during boot.
    BootAgentProgress {
        /// Agent name.
        name: String,
        /// Is supervisor (vs worker).
        is_supervisor: bool,
        /// Progress 0.0-1.0.
        progress: f32,
        /// Spawn complete.
        ready: bool,
    },

    /// Boot complete, server ready for normal operation.
    BootComplete,

    // -------------------------------------------------------------------------
    // State Updates
    // -------------------------------------------------------------------------
    /// Full session state (sent on connect and periodically).
    FullState {
        /// Complete session state snapshot.
        state: SessionState,
    },

    // -------------------------------------------------------------------------
    // Live Mode - Terminal Updates
    // -------------------------------------------------------------------------
    /// Raw PTY output for clients with native terminal emulation.
    ///
    /// Sent to clients that set `raw_pty_output: true` in their capabilities.
    /// Contains raw VT100/ANSI sequences that the client's terminal emulator
    /// (e.g., ghostty-web) can process directly. Much more efficient than
    /// pre-rendered cells for clients with native terminal support.
    PaneOutput {
        /// Source pane ID.
        pane_id: String,
        /// Raw PTY output bytes (VT100/ANSI sequences).
        data: Vec<u8>,
    },

    /// Incremental terminal update with only changed rows.
    ///
    /// Server renders terminal to cells using ghostty_vt, tracks dirty rows,
    /// and sends only changed rows to clients. This is the primary update
    /// mechanism for live terminal display.
    ///
    /// Sent to clients that do NOT set `raw_pty_output` capability.
    PaneRowsUpdate {
        /// Source pane ID.
        pane_id: String,
        /// Changed rows with pre-rendered style runs.
        rows: Vec<RowData>,
        /// Current cursor position (if changed).
        cursor: Option<CursorPosition>,
        /// Sequence number for ordering and detecting missed updates.
        seq: u64,
    },

    /// Full terminal snapshot for a pane (rendered by server).
    ///
    /// Sent in response to RequestSnapshot or Scroll.
    /// This is how tmux-style scrollback works - server renders and sends.
    PaneSnapshot {
        /// Source pane ID.
        pane_id: String,
        /// Current scroll offset (0 = bottom/live, >0 = scrolled back).
        scroll_offset: u32,
        /// Total scrollback lines available.
        scrollback_lines: u32,
        /// Rendered terminal state.
        snapshot: TerminalSnapshot,
        /// Snapshot rows rendered as style runs (preferred for themed TUI clients).
        #[serde(default, skip_serializing_if = "Vec::is_empty")]
        snapshot_rows: Vec<RowData>,
        /// Extra rows beyond viewport for caching (if requested).
        #[serde(default, skip_serializing_if = "Vec::is_empty")]
        cache_rows: Vec<CacheRow>,
        /// First screen row in cache_rows (absolute position in scrollback).
        #[serde(default, skip_serializing_if = "Option::is_none")]
        cache_start_row: Option<u32>,
        /// Optional request ID echoed from the Scroll request.
        #[serde(default, skip_serializing_if = "Option::is_none")]
        request_id: Option<u64>,
    },

    /// A pane's process exited.
    PaneExited {
        /// Pane ID that exited.
        pane_id: String,
        /// Exit code if available.
        exit_code: Option<i32>,
    },

    /// A new pane was added.
    PaneAdded {
        /// New pane information.
        pane: PaneInfo,
    },

    /// A pane was removed.
    PaneRemoved {
        /// Removed pane ID.
        pane_id: String,
    },

    /// Director panel data update.
    DirectorUpdate {
        /// Updated director data.
        data: DirectorData,
    },

    // -------------------------------------------------------------------------
    // Playback Mode
    // -------------------------------------------------------------------------
    /// Recording opened successfully.
    PlaybackOpened {
        /// Recording metadata.
        metadata: PlaybackMetadata,
    },

    /// Terminal snapshot at a playback timestamp.
    PlaybackSnapshot {
        /// Current playback timestamp in milliseconds.
        timestamp_ms: u64,
        /// Terminal snapshots keyed by pane ID.
        snapshots: HashMap<String, TerminalSnapshot>,
    },
}

// =============================================================================
// Supporting Types
// =============================================================================
