//! Factory phone-home WebSocket client
//!
//! Connects the factory daemon to CAS Cloud via Phoenix channels over WebSocket.
//! Pushes factory state and events for remote monitoring.
//!
//! Protocol: Phoenix channel JSON wire format `[join_ref, ref, topic, event, payload]`
//! Socket: `wss://{endpoint}/socket/websocket?token={token}`
//! Topic: `factory:{factory_id}`
//!

use futures_util::{SinkExt, StreamExt};
use serde_json::Value;
use std::sync::Arc;
use std::time::{Duration, Instant};
use tokio::sync::mpsc;
use tokio_tungstenite::tungstenite::Message;

/// Direct file-based logging for the cloud client.
/// tracing::info! doesn't work in the daemon because set_global_default silently fails.
fn cloud_log(factory_id: &str, msg: &str) { todo!() }

/// Messages the daemon sends to the cloud client task
#[derive(Debug, Clone)]
pub enum CloudMessage {
    /// Push factory state snapshot
    State(Value),
    /// Push a factory event
    Event { event_type: String, payload: Value },
    /// Upload a recording chunk (JSON event data, base64 encoded)
    RecordingChunk {
        worker_name: String,
        chunk_index: u32,
        data_base64: String,
        started_at: String,
        ended_at: Option<String>,
    },
    /// Graceful shutdown
    Disconnect,
    /// Accept a relay attach request
    RelayAttachAccept {
        client_id: String,
        cols: u16,
        rows: u16,
    },
    /// Reject a relay attach request
    #[allow(dead_code)]
    RelayAttachReject { client_id: String, reason: String },
    /// Send PTY output to a relay client
    RelayPtyOutput { client_id: String, data: Vec<u8> },
    /// Send per-pane PTY output to cloud (for web terminal viewers)
    PaneOutput { pane: String, data: Vec<u8> },
    /// Send available pane list to cloud
    PaneList { panes: Vec<String> },
}

/// Incoming relay event from cloud (pushed to daemon via callback)
#[derive(Debug, Clone)]
pub enum RelayEvent {
    /// Remote user wants to attach
    AttachRequest {
        client_id: String,
        cols: u16,
        rows: u16,
        mode: String,
    },
    /// Remote user sent keyboard input
    PtyInput { client_id: String, data: Vec<u8> },
    /// Remote user resized their terminal
    Resize {
        client_id: String,
        cols: u16,
        rows: u16,
    },
    /// Remote user detached
    Detach { client_id: String },
    /// Web user started watching a pane
    PaneAttach {
        pane: String,
        cols: Option<u16>,
        rows: Option<u16>,
    },
    /// Web user resized their terminal (e.g. maximize/minimize)
    PaneResize { pane: String, cols: u16, rows: u16 },
    /// Web user stopped watching a pane
    PaneDetach { pane: String },
    /// Web user sent input to a specific pane
    PaneInput { pane: String, data: Vec<u8> },
}

/// Configuration for the cloud client
#[derive(Debug, Clone)]
pub struct CloudClientConfig {
    /// Cloud API endpoint (e.g., "https://cas.dev")
    pub endpoint: String,
    /// API token for authentication
    pub token: String,
    /// Factory ID (supervisor agent ID)
    pub factory_id: String,
    /// Device ID (from device registration)
    pub device_id: Option<String>,
    /// CAS data directory (for writing to local queues on cloud commands)
    pub cas_dir: Option<std::path::PathBuf>,
    /// Factory session name (for prompt queue isolation)
    pub factory_session: Option<String>,
}

/// Handle for sending messages to the cloud client from the daemon
#[derive(Clone)]
pub struct CloudClientHandle {
    tx: mpsc::UnboundedSender<CloudMessage>,
    /// Receiver for relay events from cloud (daemon polls this)
    relay_rx: Arc<tokio::sync::Mutex<mpsc::UnboundedReceiver<RelayEvent>>>,
}

impl CloudClientHandle {
    /// Send a state snapshot to the cloud
    pub fn send_state(&self, state: Value) { todo!() }

    /// Send an event to the cloud
    pub fn send_event(&self, event_type: &str, payload: Value) { todo!() }

    /// Send a recording chunk to the cloud
    pub fn send_recording_chunk(
        &self,
        worker_name: &str,
        chunk_index: u32,
        data_base64: String,
        started_at: &str,
        ended_at: Option<&str>,
    ) { todo!() }

    /// Send disconnect and stop the client
    pub fn disconnect(&self) { todo!() }

    /// Accept a relay attach request
    pub fn relay_accept(&self, client_id: &str, cols: u16, rows: u16) { todo!() }

    /// Reject a relay attach request
    #[allow(dead_code)]
    pub fn relay_reject(&self, client_id: &str, reason: &str) { todo!() }

    /// Send PTY output to a relay client
    pub fn relay_output(&self, client_id: &str, data: Vec<u8>) { todo!() }

    /// Send per-pane PTY output to cloud
    pub fn send_pane_output(&self, pane: &str, data: Vec<u8>) { todo!() }

    /// Send available pane list to cloud
    pub fn send_pane_list(&self, panes: Vec<String>) { todo!() }

    /// Try to receive pending relay events (non-blocking)
    pub fn try_recv_relay(&self) -> Vec<RelayEvent> { todo!() }
}

/// Spawn the cloud client background task.
/// Returns a handle for sending messages and receiving relay events.
pub fn spawn_cloud_client(config: CloudClientConfig) -> CloudClientHandle { todo!() }

use crate::ui::factory::phoenix::{encode_msg, ws_url};

/// Duration threshold for delta vs full state re-push on reconnect.
/// Within this window, only changed state is sent; beyond it, a full snapshot is pushed.
const RECONNECT_FULL_STATE_THRESHOLD: Duration = Duration::from_secs(300);

/// The main cloud client loop with reconnection
async fn cloud_client_task(
    config: CloudClientConfig,
    mut rx: mpsc::UnboundedReceiver<CloudMessage>,
    relay_tx: mpsc::UnboundedSender<RelayEvent>,
) { todo!() }

enum ShouldStop {
    Yes,
    Reconnect,
}

/// Single connection lifecycle: connect → join → push messages → handle disconnect
///
/// `request_full_state`: when true, sends a `factory.request_full_state` event after join
/// to signal the cloud that it should expect a full snapshot (reconnect after >5 min).
/// When false (reconnect within 5 min), the daemon relies on buffered events for delta sync.
async fn connect_and_run(
    config: &CloudClientConfig,
    rx: &mut mpsc::UnboundedReceiver<CloudMessage>,
    event_buffer: &mut Vec<CloudMessage>,
    request_full_state: bool,
    relay_tx: &mpsc::UnboundedSender<RelayEvent>,
) -> anyhow::Result<ShouldStop> { todo!() }

/// Send a CloudMessage over the WebSocket
async fn send_cloud_message<S>(
    write: &mut S,
    topic: &str,
    join_ref: &str,
    msg: &CloudMessage,
) -> anyhow::Result<()>
where
    S: SinkExt<Message, Error = tokio_tungstenite::tungstenite::Error> + Unpin,
{ todo!() }

/// Handle incoming messages from the cloud
fn handle_cloud_message(
    text: &str,
    relay_tx: &mpsc::UnboundedSender<RelayEvent>,
    cas_dir: Option<&std::path::Path>,
    factory_session: Option<&str>,
) { todo!() }

/// Handle a cloud command by writing to the appropriate local queue.
///
/// Commands arrive from the web UI via Phoenix channel broadcast.
/// The daemon's main loop picks up queued items on its next tick.
fn handle_cloud_command(
    cas_dir: &std::path::Path,
    command_type: &str,
    params: &Value,
    factory_session: Option<&str>,
) { todo!() }

/// Serialize DirectorData into a JSON Value suitable for the cloud
pub fn serialize_factory_state(
    factory_id: &str,
    supervisor_name: &str,
    data: &cas_factory::DirectorData,
) -> Value { todo!() }

// Phoenix protocol tests (ws_url, encode_msg, refs) are in ui::factory::phoenix::tests
