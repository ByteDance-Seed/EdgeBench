//! Socket protocol for factory daemon communication
//!
//! Defines the message types exchanged between the factory daemon (which owns PTYs)
//! and the TUI client (which renders and sends input).

use serde::{Deserialize, Serialize};
use std::collections::HashMap;

/// Messages sent from TUI client to daemon
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum ClientMessage {
    /// Attach to the session (sent on connect)
    Attach {
        /// Request full scrollback buffer
        request_scrollback: bool,
    },

    /// Detach from the session (graceful disconnect)
    Detach,

    /// Send keyboard input to a specific pane
    Input {
        /// Target pane ID
        pane_id: String,
        /// Raw bytes to send
        data: Vec<u8>,
    },

    /// Send keyboard input to the focused pane
    InputFocused {
        /// Raw bytes to send
        data: Vec<u8>,
    },

    /// Change focus to a specific pane
    Focus {
        /// Target pane ID
        pane_id: String,
    },

    /// Focus next pane
    FocusNext,

    /// Focus previous pane
    FocusPrev,

    /// Request terminal resize (global, used by TUI clients)
    Resize {
        /// New column count
        cols: u16,
        /// New row count
        rows: u16,
    },

    /// Resize a specific pane (used by GUI clients where each pane has its own terminal)
    ResizePane {
        /// Target pane ID
        pane_id: String,
        /// New column count
        cols: u16,
        /// New row count
        rows: u16,
    },

    /// Spawn new workers
    SpawnWorkers {
        /// Number of workers to spawn
        count: usize,
        /// Optional specific names
        names: Vec<String>,
    },

    /// Shutdown workers
    ShutdownWorkers {
        /// Number to shutdown (0 = all)
        count: usize,
        /// Optional specific names (overrides count)
        names: Vec<String>,
    },

    /// Inject a prompt into a pane
    Inject {
        /// Target pane ID
        pane_id: String,
        /// Prompt text to inject
        prompt: String,
    },

    /// Request current state snapshot
    GetState,

    /// Ping to check connection
    Ping,

    /// Interrupt the focused pane (Ctrl+C)
    Interrupt,

    /// Spawn a new shell pane
    SpawnShell {
        /// Pane name
        name: String,
        /// Shell command (uses $SHELL if not specified)
        shell: Option<String>,
    },

    /// Kill a shell pane
    KillShell {
        /// Pane name to kill
        name: String,
    },
}

/// Messages sent from daemon to TUI client
#[derive(Debug, Clone, Serialize, Deserialize)]
pub enum DaemonMessage {
    /// Welcome message on attach with current state
    Welcome {
        /// Session name
        session_name: String,
        /// Current state snapshot
        state: SessionState,
        /// Scrollback buffers for each pane (if requested)
        scrollback: Option<HashMap<String, Vec<Vec<u8>>>>,
    },

    /// Terminal output from a pane
    Output {
        /// Source pane ID
        pane_id: String,
        /// Output data (terminal escape sequences included)
        data: Vec<u8>,
    },

    /// A pane exited
    PaneExited {
        /// Pane ID that exited
        pane_id: String,
        /// Exit code if available
        exit_code: Option<i32>,
    },

    /// A pane was added
    PaneAdded {
        /// New pane info
        pane: PaneInfo,
    },

    /// A pane was removed
    PaneRemoved {
        /// Removed pane ID
        pane_id: String,
    },

    /// Focus changed
    FocusChanged {
        /// Previously focused pane (if any)
        from: Option<String>,
        /// Newly focused pane
        to: String,
    },

    /// State update (periodic or on significant change)
    StateUpdate {
        /// Updated state
        state: SessionState,
    },

    /// Error response
    Error {
        /// Error message
        message: String,
    },

    /// Pong response to ping
    Pong,

    /// Acknowledgment of detach
    Detached,

    /// Initialization progress (sent during daemon startup)
    InitProgress {
        /// Current step name
        step: String,
        /// Step number (1-based)
        step_num: u8,
        /// Total steps
        total_steps: u8,
        /// Whether this step completed successfully
        completed: bool,
    },

    /// Agent spawn progress
    AgentProgress {
        /// Agent name
        name: String,
        /// Whether this is a supervisor (vs worker)
        is_supervisor: bool,
        /// Progress 0.0-1.0
        progress: f32,
        /// Whether spawn completed
        ready: bool,
    },

    /// Initialization complete - daemon ready for TUI
    InitComplete,
}

/// Snapshot of session state
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionState {
    /// Currently focused pane ID
    pub focused_pane: Option<String>,
    /// All panes in the session
    pub panes: Vec<PaneInfo>,
    /// Current epic ID (if any)
    pub epic_id: Option<String>,
    /// Current epic title (if any)
    pub epic_title: Option<String>,
    /// Terminal dimensions
    pub cols: u16,
    pub rows: u16,
}

/// Information about a single pane
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PaneInfo {
    /// Pane ID (also the name)
    pub id: String,
    /// Pane kind
    pub kind: PaneKind,
    /// Whether this pane is focused
    pub focused: bool,
    /// Title for display
    pub title: String,
    /// Whether the pane process has exited
    pub exited: bool,
}

/// Kind of pane (matches cas_mux::PaneKind)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
pub enum PaneKind {
    /// Worker agent pane
    Worker,
    /// Supervisor agent pane
    Supervisor,
    /// Director panel (no PTY)
    Director,
    /// Generic shell
    Shell,
}

impl From<cas_mux::PaneKind> for PaneKind {
    fn from(kind: cas_mux::PaneKind) -> Self { todo!() }
}

/// Session metadata persisted to disk
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SessionMetadata {
    /// Session name
    pub name: String,
    /// When the session was created
    pub created_at: String,
    /// Daemon process ID
    pub daemon_pid: u32,
    /// Socket path
    pub socket_path: String,
    /// WebSocket server port (for client connections)
    #[serde(default)]
    pub ws_port: Option<u16>,
    /// Log directory for this session
    #[serde(default)]
    pub log_dir: Option<String>,
    /// Daemon stderr log path
    #[serde(default)]
    pub daemon_log_path: Option<String>,
    /// Daemon tracing log path
    #[serde(default)]
    pub daemon_trace_log_path: Option<String>,
    /// Server stderr log path
    #[serde(default)]
    pub server_log_path: Option<String>,
    /// Server tracing log path
    #[serde(default)]
    pub server_trace_log_path: Option<String>,
    /// TUI tracing log path
    #[serde(default)]
    pub tui_log_path: Option<String>,
    /// Panic log path
    #[serde(default)]
    pub panic_log_path: Option<String>,
    /// Supervisor info
    pub supervisor: AgentInfo,
    /// Worker info
    pub workers: Vec<AgentInfo>,
    /// Epic ID if active
    pub epic_id: Option<String>,
    /// Project directory this session belongs to (for multi-project isolation)
    #[serde(default)]
    pub project_dir: Option<String>,
    /// Native Agent Teams team name (when Teams messaging is enabled)
    #[serde(default)]
    pub team_name: Option<String>,
}

/// Basic agent info for session metadata
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct AgentInfo {
    /// Agent name
    pub name: String,
    /// Process ID
    pub pid: Option<u32>,
    /// Worktree path (if using worktrees)
    pub worktree_path: Option<String>,
}

/// Frame header for length-prefixed messages
pub const FRAME_HEADER_SIZE: usize = 4;

/// Maximum message size (16 MB)
pub const MAX_MESSAGE_SIZE: usize = 16 * 1024 * 1024;

/// Encode a message with length prefix
pub fn encode_message<T: Serialize>(msg: &T) -> Result<Vec<u8>, serde_json::Error> { todo!() }

/// Decode message length from header
pub fn decode_length(header: &[u8; FRAME_HEADER_SIZE]) -> usize { todo!() }

#[cfg(test)]
mod tests {
    use crate::ui::factory::protocol::*;

    #[test]
    fn test_encode_decode_client_message() {
        let msg = ClientMessage::Input {
            pane_id: "worker-1".to_string(),
            data: vec![0x1b, 0x5b, 0x41], // Up arrow
        };

        let encoded = encode_message(&msg).unwrap();
        assert!(encoded.len() > FRAME_HEADER_SIZE);

        let len = decode_length(encoded[..FRAME_HEADER_SIZE].try_into().unwrap());
        assert_eq!(len, encoded.len() - FRAME_HEADER_SIZE);

        let decoded: ClientMessage = serde_json::from_slice(&encoded[FRAME_HEADER_SIZE..]).unwrap();

        match decoded {
            ClientMessage::Input { pane_id, data } => {
                assert_eq!(pane_id, "worker-1");
                assert_eq!(data, vec![0x1b, 0x5b, 0x41]);
            }
            _ => panic!("Wrong message type"),
        }
    }

    #[test]
    fn test_encode_decode_daemon_message() {
        let msg = DaemonMessage::Output {
            pane_id: "supervisor".to_string(),
            data: b"Hello, world!\n".to_vec(),
        };

        let encoded = encode_message(&msg).unwrap();
        let len = decode_length(encoded[..FRAME_HEADER_SIZE].try_into().unwrap());

        let decoded: DaemonMessage =
            serde_json::from_slice(&encoded[FRAME_HEADER_SIZE..FRAME_HEADER_SIZE + len]).unwrap();

        match decoded {
            DaemonMessage::Output { pane_id, data } => {
                assert_eq!(pane_id, "supervisor");
                assert_eq!(data, b"Hello, world!\n");
            }
            _ => panic!("Wrong message type"),
        }
    }

    #[test]
    fn test_pane_kind_conversion() {
        assert_eq!(PaneKind::from(cas_mux::PaneKind::Worker), PaneKind::Worker);
        assert_eq!(
            PaneKind::from(cas_mux::PaneKind::Supervisor),
            PaneKind::Supervisor
        );
        assert_eq!(
            PaneKind::from(cas_mux::PaneKind::Director),
            PaneKind::Director
        );
    }
}
