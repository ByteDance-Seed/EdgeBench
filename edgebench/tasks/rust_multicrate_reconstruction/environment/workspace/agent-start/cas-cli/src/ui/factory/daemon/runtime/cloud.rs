use crate::ui::factory::daemon::FactoryDaemon;
use crate::ui::factory::daemon::cloud_client::{CloudClientHandle, serialize_factory_state};
use crate::ui::factory::director::DirectorEvent;
use std::path::Path;

impl FactoryDaemon {
    /// Try to start the cloud phone-home client.
    ///
    /// Reads CloudConfig (for endpoint + token) and DeviceConfig (for device_id).
    /// Returns None if not authenticated or on any error (phone-home is best-effort).
    pub(crate) fn try_start_cloud_client(session_name: &str) -> Option<CloudClientHandle> { todo!() }

    /// Push factory state snapshot to the cloud.
    ///
    /// Called after refresh_data() when cloud phone-home is active.
    pub(super) fn push_cloud_state(&self) { todo!() }

    /// Push lifecycle events to the cloud.
    ///
    /// Called after event detection when cloud phone-home is active.
    pub(super) fn push_cloud_events(&self, events: &[DirectorEvent]) { todo!() }

    /// Upload terminal recordings to the cloud after session ends.
    ///
    /// Reads each agent's .rec file, converts events to JSON format,
    /// and sends via the cloud WebSocket as recording chunks.
    pub(super) fn upload_recordings(&self) { todo!() }

    /// Disconnect the cloud client (called during cleanup).
    pub(super) fn disconnect_cloud(&self) { todo!() }
}

/// Convert a single .rec file to JSON events and upload via cloud client.
fn upload_single_recording(
    handle: &CloudClientHandle,
    rec_path: &Path,
    chunk_index: u32,
) -> anyhow::Result<()> { todo!() }
