use crate::ui::factory::daemon::imports::*;

use crate::ui::factory::protocol::{self, DaemonMessage};
use std::path::PathBuf;

/// Result of fork_first_daemon
pub enum ForkFirstResult {
    /// Parent process - should run boot screen client
    Parent {
        session_name: String,
        sock_path: PathBuf,
        daemon_pid: u32,
    },
    /// Child process - should run initialization then daemon loop
    Child { init_phase: Box<DaemonInitPhase> },
}

/// Initialization phase for fork-first daemon
///
/// After fork, the child process uses this to:
/// 1. Accept the parent as the first client (for progress updates)
/// 2. Do all initialization (worktrees, CAS data, PTY spawning)
/// 3. Send progress messages to parent
/// 4. Convert to FactoryDaemon when ready
pub struct DaemonInitPhase {
    /// Session name
    pub session_name: String,
    /// Factory configuration
    pub factory_config: FactoryConfig,
    /// Boot configuration for names
    pub supervisor_name: String,
    /// Worker names
    pub worker_names: Vec<String>,
    /// Whether to enable cloud phone-home
    pub phone_home: bool,
    /// Socket listener
    listener: UnixListener,
    /// First client connection (parent's boot screen)
    init_client: Option<UnixStream>,
}

/// Create a daemon init phase without calling fork().
///
/// Used by subprocess-based daemon startup paths that still want to stream
/// boot progress over the standard factory socket protocol.
#[cfg(unix)]
pub fn init_phase_without_fork(
    session_name: String,
    factory_config: FactoryConfig,
    supervisor_name: String,
    worker_names: Vec<String>,
    phone_home: bool,
) -> anyhow::Result<(DaemonInitPhase, PathBuf)> { todo!() }

/// Fork immediately, child becomes daemon and does initialization
///
/// This is the correct approach (like tmux): fork first, then initialize.
/// PTY reader threads are created IN the daemon process, never crossing fork.
///
/// Returns:
/// - `ForkFirstResult::Parent` - Parent should run boot screen client
/// - `ForkFirstResult::Child` - Child should initialize and run daemon
#[cfg(unix)]
pub fn fork_first_daemon(
    session_name: String,
    factory_config: FactoryConfig,
    supervisor_name: String,
    worker_names: Vec<String>,
    phone_home: bool,
) -> anyhow::Result<ForkFirstResult> { todo!() }

#[cfg(not(unix))]
pub fn fork_first_daemon(
    _session_name: String,
    _factory_config: FactoryConfig,
    _supervisor_name: String,
    _worker_names: Vec<String>,
    _phone_home: bool,
) -> anyhow::Result<ForkFirstResult> { todo!() }

impl DaemonInitPhase {
    /// Run initialization with progress reporting
    ///
    /// This does all heavy lifting in the daemon process:
    /// 1. Waits for parent to connect
    /// 2. Sends progress updates during initialization
    /// 3. Spawns all PTYs (reader threads created here, in daemon)
    /// 4. Returns ready-to-run FactoryDaemon
    pub fn run_with_progress(mut self) -> anyhow::Result<FactoryDaemon> { todo!() }

    fn send_progress(
        &mut self,
        step: &str,
        num: u8,
        total: u8,
        completed: bool,
    ) -> anyhow::Result<()> { todo!() }

    fn send_agent_progress(
        &mut self,
        name: &str,
        is_supervisor: bool,
        progress: f32,
        ready: bool,
    ) -> anyhow::Result<()> { todo!() }

    fn send_init_complete(&mut self) -> anyhow::Result<()> { todo!() }

    fn send_message(&mut self, msg: &DaemonMessage) -> anyhow::Result<()> { todo!() }
}

/// Check if a process is running by PID
#[cfg(unix)]
fn is_process_running(pid: u32) -> bool { todo!() }

#[cfg(not(unix))]
fn is_process_running(_pid: u32) -> bool { todo!() }
