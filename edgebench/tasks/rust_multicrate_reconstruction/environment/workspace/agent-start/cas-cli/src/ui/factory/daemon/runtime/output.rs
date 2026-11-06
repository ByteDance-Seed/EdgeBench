use crate::ui::factory::daemon::imports::*;

impl FactoryDaemon {
    /// Broadcast output only to clients with a specific view mode
    pub(super) fn broadcast_output_to(&mut self, data: &[u8], mode: ClientViewMode) { todo!() }

    /// Flush pending output to all clients without adding new data
    pub(super) fn flush_client_output(&mut self) { todo!() }

    /// Get the smallest terminal dimensions among clients of a given view mode.
    ///
    /// Uses the smallest attached viewport so all clients see the complete TUI.
    /// When a client detaches, the daemon recalibrates to the new smallest.
    pub(super) fn dims_for_mode(&self, mode: ClientViewMode) -> (u16, u16) { todo!() }

    /// Recalibrate render dimensions after a client disconnects.
    /// If the disconnected client was the smallest, the TUI can now expand.
    pub(super) fn recalibrate_after_disconnect(&mut self) { todo!() }
}
