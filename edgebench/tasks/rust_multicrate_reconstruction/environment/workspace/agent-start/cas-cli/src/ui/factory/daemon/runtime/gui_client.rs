use crate::ui::factory::daemon::imports::*;
use crate::ui::factory::protocol::{
    ClientMessage, DaemonMessage, FRAME_HEADER_SIZE, MAX_MESSAGE_SIZE, PaneInfo, PaneKind,
    SessionState, decode_length, encode_message,
};

/// Encode a DaemonMessage into a framed byte vector, or None on error.
fn encode_frame(msg: &DaemonMessage) -> Option<Vec<u8>> { todo!() }

/// Queue a pre-encoded frame into a GUI client's write buffer.
fn queue_frame(client: &mut GuiConnection, frame: &[u8]) { todo!() }

impl FactoryDaemon {
    /// Accept new GUI client connections (non-blocking).
    pub(super) fn accept_gui_clients(&mut self) -> bool { todo!() }

    /// Process input from all GUI clients, returning whether any activity occurred.
    pub(super) async fn process_gui_client_input(&mut self) -> bool { todo!() }

    /// Flush pending output to all GUI clients.
    pub(super) fn flush_gui_client_output(&mut self) { todo!() }

    /// Forward per-pane PTY output to all connected GUI clients.
    pub(super) fn forward_pane_output_to_gui(&mut self, pane_id: &str, data: &[u8]) { todo!() }

    /// Notify GUI clients that a pane was added.
    pub(super) fn gui_notify_pane_added(&mut self, pane_id: &str, kind: cas_mux::PaneKind) { todo!() }

    /// Notify GUI clients that a pane was removed.
    pub(super) fn gui_notify_pane_removed(&mut self, pane_id: &str) { todo!() }

    /// Notify GUI clients that a pane exited.
    pub(super) fn gui_notify_pane_exited(&mut self, pane_id: &str, exit_code: Option<i32>) { todo!() }

    /// Send periodic state updates to GUI clients.
    pub(super) fn gui_send_state_update(&mut self) { todo!() }

    /// Handle a single ClientMessage from a GUI client.
    async fn handle_gui_message(&mut self, client_id: usize, msg: ClientMessage) { todo!() }

    /// Build a SessionState snapshot from current daemon state.
    fn build_session_state(&self) -> SessionState { todo!() }

    /// Build scrollback buffers for all panes from the ring buffers.
    fn build_scrollback(&self) -> std::collections::HashMap<String, Vec<Vec<u8>>> { todo!() }

    /// Resolve "supervisor" to the actual pane name.
    fn resolve_pane_name(&self, name: &str) -> String { todo!() }

    /// Broadcast a DaemonMessage to all connected GUI clients.
    fn gui_broadcast(&mut self, msg: &DaemonMessage) { todo!() }

    /// Recalculate effective pane sizes after a GUI client disconnects.
    /// The disconnected client may have been the smallest, so panes can expand.
    fn reconcile_after_gui_disconnect(&mut self) { todo!() }

    /// Calculate and apply the effective size for a pane across all client types
    /// (TUI, GUI, web). Uses the smallest dimensions so every viewer can display
    /// the content without clipping.
    pub(super) fn apply_effective_pane_size(&mut self, pane_id: &str) { todo!() }

    /// Snapshot current mux pane sizes into tui_pane_sizes after a TUI layout resize.
    /// Then re-apply effective sizes for panes that have GUI or web constraints.
    pub(super) fn snapshot_tui_pane_sizes_and_reconcile(&mut self) { todo!() }
}
