//! Factory boot screen - animated startup sequence for daemon initialization.

use std::thread;
use std::time::Duration;

/// Boot screen configuration
pub struct BootConfig {
    /// Supervisor name
    pub supervisor_name: String,
    /// Worker names
    pub worker_names: Vec<String>,
    /// Working directory
    pub cwd: String,
    /// Session name
    pub session_name: String,
    /// Startup profile summary (workers, mode, harness)
    pub profile: String,
    /// Skip animations (for testing)
    pub skip_animation: bool,
}

mod screen;

use crate::ui::factory::boot::screen::BootScreen;

/// Boot screen client mode - receives progress from daemon socket
///
/// This is used in the fork-first architecture where the daemon does
/// all initialization and sends progress updates via socket.
pub fn run_boot_screen_client(
    boot_config: &BootConfig,
    sock_path: &std::path::Path,
    _daemon_pid: u32,
) -> anyhow::Result<()> { todo!() }

/// Connect to daemon socket with retry
fn connect_with_retry(
    sock_path: &std::path::Path,
    timeout: Duration,
) -> anyhow::Result<std::os::unix::net::UnixStream> { todo!() }
