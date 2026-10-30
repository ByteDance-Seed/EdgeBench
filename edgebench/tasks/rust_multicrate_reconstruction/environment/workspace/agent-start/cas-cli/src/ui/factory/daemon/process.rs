use crate::ui::factory::daemon::imports::*;

/// Daemonize and run factory daemon (legacy - spawns subprocess)
#[cfg(unix)]
pub fn daemonize(config: DaemonConfig) -> anyhow::Result<()> { todo!() }

#[cfg(not(unix))]
pub fn daemonize(_config: DaemonConfig) -> anyhow::Result<()> { todo!() }

/// Fork after initialization - parent becomes client, child becomes daemon
///
/// This is the preferred approach for boot screen with real progress:
/// 1. Parent does all initialization (shown in boot screen)
/// 2. After init, fork()
/// 3. Child inherits PTY file descriptors, becomes daemon
/// 4. Parent connects as client
///
/// Returns Ok(true) in parent (should attach as client)
/// Returns Ok(false) in child (will run daemon loop)
#[cfg(unix)]
pub fn fork_into_daemon(app: FactoryApp, session_name: String) -> anyhow::Result<ForkResult> { todo!() }

#[cfg(not(unix))]
pub fn fork_into_daemon(_app: FactoryApp, _session_name: String) -> anyhow::Result<ForkResult> { todo!() }

/// Result of fork_into_daemon
#[allow(clippy::large_enum_variant)]
pub enum ForkResult {
    /// Parent process - should attach as client
    Parent,
    /// Child process - should run daemon loop
    Child {
        app: FactoryApp,
        listener: UnixListener,
        session_name: String,
    },
}

/// Run the daemon loop after fork (called by child process)
pub async fn run_daemon_after_fork(
    mut app: FactoryApp,
    listener: UnixListener,
    session_name: String,
) -> anyhow::Result<()> { todo!() }

/// Run the factory daemon (called by the daemon subprocess - legacy mode)
pub async fn run_daemon(config: DaemonConfig) -> anyhow::Result<()> { todo!() }

/// Run daemon with boot progress handshake (subprocess-safe, no raw fork).
pub async fn run_daemon_with_boot_progress(
    config: DaemonConfig,
    supervisor_name: String,
    worker_names: Vec<String>,
) -> anyhow::Result<()> { todo!() }

pub(super) fn open_log_file_append(path: &std::path::Path) -> std::io::Result<std::fs::File> { todo!() }

pub(super) fn open_log_file_truncate(path: &std::path::Path) -> std::io::Result<std::fs::File> { todo!() }

pub(super) fn install_panic_hook(path: std::path::PathBuf) { todo!() }
