//! Factory daemon - owns PTYs and runs TUI with PTY forwarding
//!
//! The daemon:
//! - Owns all PTY file descriptors for agents
//! - Runs the full TUI event loop
//! - Renders to a buffer and sends to connected clients
//! - Receives input from clients and processes it
//! - Persists across TUI attach/detach cycles

use crate::ui::factory::app::{FactoryApp, FactoryConfig, WorkerSpawnResult};
use crate::ui::factory::buffer_backend::BufferBackend;
use crate::ui::factory::session::SessionManager;
use ratatui::Terminal;
use std::collections::{HashMap, VecDeque};
use std::os::unix::net::{UnixListener, UnixStream};
use std::sync::Arc;
use std::sync::atomic::AtomicBool;
use std::time::Instant;
use tokio::task::JoinHandle;

/// Special escape sequence prefix for control messages from client
/// Using OSC (Operating System Command) private sequence: ESC ] 777 ;
const CONTROL_PREFIX: &[u8] = b"\x1b]777;";
const CONTROL_SUFFIX: u8 = 0x07; // BEL

/// Max buffered output per client before forcing a full redraw.
const MAX_CLIENT_OUTPUT_BYTES: usize = 2 * 1024 * 1024;
/// Seconds before another client can take input ownership.
const INPUT_OWNER_IDLE_SECS: u64 = 2;

/// Factory daemon configuration
#[derive(Debug, Clone)]
pub struct DaemonConfig {
    /// Session name
    pub session_name: String,
    /// Factory configuration
    pub factory_config: FactoryConfig,
    /// Run in foreground (don't daemonize)
    pub foreground: bool,
    /// Enable boot progress socket handshake before entering daemon loop.
    pub boot_progress: bool,
    /// Enable cloud phone-home (push state/events to CAS Cloud)
    pub phone_home: bool,
}

/// Client view mode determines rendering layout
#[derive(Debug, Clone, Copy, PartialEq)]
enum ClientViewMode {
    /// Full factory TUI (desktop)
    Full,
    /// Compact supervisor-focused view (phone/narrow terminal)
    Compact,
}

/// Threshold below which a client is auto-assigned compact mode
const COMPACT_WIDTH_THRESHOLD: u16 = 80;

/// A connected TUI client
struct ClientConnection {
    /// Socket stream
    stream: UnixStream,
    /// Input buffer for parsing control sequences
    input_buf: Vec<u8>,
    /// Buffered output for this client
    output_buf: VecDeque<u8>,
    /// Whether this client needs a full redraw
    needs_full_redraw: bool,
    /// Client's view mode
    view_mode: ClientViewMode,
    /// Client's terminal dimensions
    client_cols: u16,
    client_rows: u16,
}

/// A connected GUI client (cas-desktop) using length-prefixed JSON protocol
struct GuiConnection {
    /// Socket stream
    stream: UnixStream,
    /// Buffer for accumulating incoming bytes until a complete message is available
    read_buf: Vec<u8>,
    /// Buffered outgoing framed messages
    write_buf: VecDeque<u8>,
    /// Per-pane dimensions reported by this client (pane_id -> (cols, rows))
    pane_sizes: HashMap<String, (u16, u16)>,
}

/// A single pending spawn action (one worker at a time)
#[derive(Debug)]
enum PendingSpawn {
    /// Spawn a worker with an auto-generated name
    Anonymous { isolate: bool },
    /// Spawn a worker with a specific name
    Named { name: String, isolate: bool },
    /// Shutdown workers
    Shutdown {
        count: Option<usize>,
        names: Vec<String>,
        force: bool,
    },
    /// Respawn a crashed worker
    Respawn(String),
    /// Spawn a shell pane
    Shell { name: String, shell: Option<String> },
    /// Kill a shell pane
    KillShell { name: String },
}

/// Factory daemon state
pub struct FactoryDaemon {
    /// Session name
    session_name: String,
    /// The factory app (owns the mux)
    app: FactoryApp,
    /// Socket listener
    listener: UnixListener,
    /// Connected clients
    clients: HashMap<usize, ClientConnection>,
    /// Next client ID
    next_client_id: usize,
    /// Client id that owns input/resize focus
    owner_client_id: Option<usize>,
    /// Last time the owner sent input
    owner_last_activity: Instant,
    /// Session manager
    session_manager: SessionManager,
    /// Shutdown flag
    shutdown: Arc<AtomicBool>,
    /// Terminal size (full mode)
    cols: u16,
    rows: u16,
    /// Resize debounce: pending resize event and when it was received
    pending_resize: Option<(u16, u16)>,
    pending_resize_at: Instant,
    /// Compact mode terminal (separate render target for compact clients)
    compact_terminal: Option<Terminal<BufferBackend>>,
    compact_cols: u16,
    compact_rows: u16,
    /// Pending spawn/shutdown actions (processed one per tick to avoid blocking TUI)
    pending_spawns: VecDeque<PendingSpawn>,
    /// In-flight background spawn task: (worker_name, join_handle).
    /// One at a time, runs git worktree ops off main thread.
    spawn_task: Option<(String, JoinHandle<anyhow::Result<WorkerSpawnResult>>)>,
    /// Cloud phone-home WebSocket client handle
    cloud_handle: Option<cloud_client::CloudClientHandle>,
    /// Remote relay clients connected via cloud WebSocket
    relay_clients: HashMap<String, runtime::relay::RelayClient>,
    /// Per-pane web watchers: pane_name -> set of watcher IDs
    pane_watchers: HashMap<String, std::collections::HashSet<String>>,
    /// Per-pane ring buffer of raw PTY bytes for replay on attach
    pane_buffers: HashMap<String, runtime::relay::PaneBuffer>,
    /// GUI socket listener (for desktop GUI clients using JSON protocol)
    gui_listener: UnixListener,
    /// Connected GUI clients
    gui_clients: HashMap<usize, GuiConnection>,
    /// Next GUI client ID
    next_gui_client_id: usize,
    /// Per-pane sizes allocated by TUI layout (pane_id -> (cols, rows))
    tui_pane_sizes: HashMap<String, (u16, u16)>,
    /// Per-pane sizes reported by web viewers (pane_id -> (cols, rows))
    web_pane_sizes: HashMap<String, (u16, u16)>,
    /// Native Agent Teams manager for inter-agent messaging.
    /// When present, messages are delivered via Teams inbox files instead of PTY injection.
    teams: Option<runtime::teams::TeamsManager>,
    /// Notification socket for instant prompt queue wakeup.
    /// Falls back to pure polling if socket creation fails.
    notify_rx: Option<cas_factory::DaemonNotifier>,
}

/// Parsed control events from client
#[derive(Debug)]
enum ControlEvent {
    Resize(u16, u16),
    SetMode(ClientViewMode),
    MouseDown(u16, u16),
    MouseDrag(u16, u16),
    MouseUp,
    MouseScrollUp,
    MouseScrollDown,
    DropImage { col: u16, row: u16, path: String },
}

pub mod cloud_client;
mod fork_first;
mod imports;
mod process;
pub(crate) mod runtime;

pub use fork_first::{DaemonInitPhase, ForkFirstResult, fork_first_daemon};
pub use process::{
    ForkResult, daemonize, fork_into_daemon, run_daemon, run_daemon_after_fork,
    run_daemon_with_boot_progress,
};
