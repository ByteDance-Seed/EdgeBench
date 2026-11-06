use crate::ui::factory::app::imports::*;

impl FactoryApp {
    // Recording methods

    /// Check if recording is enabled for this session
    pub fn record_enabled(&self) -> bool { todo!() }

    /// Get the recording session ID (if recording is enabled)
    pub fn recording_session_id(&self) -> Option<&str> { todo!() }

    /// Record a director event for later export
    ///
    /// Called when significant events occur (task completed, epic started, etc.)
    pub fn record_event(&mut self, event: DirectorEvent) { todo!() }

    /// Record multiple director events
    pub fn record_events(&mut self, events: &[DirectorEvent]) { todo!() }

    /// Start recording on all panes (supervisor and workers)
    ///
    /// This should be called after the app is created and inside an async context.
    /// Recording files are saved to ~/.cas/recordings/{session_id}/{agent_name}.rec
    pub async fn start_recording(&mut self) -> anyhow::Result<()> { todo!() }

    /// Start recording for a single pane by name
    ///
    /// Used when workers are spawned dynamically after initial recording setup.
    pub async fn start_recording_for_pane(&mut self, pane_name: &str) -> anyhow::Result<()> { todo!() }

    /// Stop recording for a single pane by name
    ///
    /// Used when workers are shut down during a session.
    pub async fn stop_recording_for_pane(&mut self, pane_name: &str) -> anyhow::Result<()> { todo!() }

    /// Stop recording on all panes and finalize recordings
    ///
    /// Also exports the session to a .casrec archive in the recordings directory.
    pub async fn stop_recording(&mut self) -> anyhow::Result<()> { todo!() }
}
