use crate::config::Config;
use crate::store::find_cas_root;
use crate::ui::factory::{
    BootConfig, DaemonConfig, FactoryConfig, ForkFirstResult, NotifyBackend, NotifyConfig, attach,
    daemon_log_path, daemonize, fork_first_daemon, run_boot_screen_client,
};
use anyhow::{Result, bail};
use std::time::Duration;

#[allow(clippy::too_many_arguments)]
pub(super) fn execute_daemon(
    session: &str,
    cwd: &std::path::Path,
    workers: u8,
    no_worktrees: bool,
    worktree_root: Option<std::path::PathBuf>,
    notify: bool,
    tabbed: bool,
    record: bool,
    phone_home: bool,
    supervisor_cli: cas_mux::SupervisorCli,
    worker_cli: cas_mux::SupervisorCli,
    foreground: bool,
    boot_progress: bool,
    supervisor_name: Option<String>,
    worker_names: Vec<String>,
) -> Result<()> { todo!() }

pub(super) fn execute_legacy_daemon(
    session_name: String,
    config: FactoryConfig,
    phone_home: bool,
) -> Result<()> { todo!() }

#[cfg(unix)]
pub(super) fn run_factory_with_daemon(
    session_name: String,
    config: FactoryConfig,
    phone_home: bool,
) -> Result<()> { todo!() }

fn wait_for_socket(sock_path: &std::path::Path, timeout: Duration) -> Result<()> { todo!() }

fn attach_with_retry(session_name: &str, timeout: Duration) -> Result<()> { todo!() }

#[cfg(target_os = "macos")]
fn should_use_subprocess_daemon_on_macos() -> bool { todo!() }

#[cfg(not(target_os = "macos"))]
fn should_use_subprocess_daemon_on_macos() -> bool { todo!() }

fn explain_boot_error(message: &str, worktrees_enabled: bool) -> String { todo!() }

fn build_boot_profile(config: &FactoryConfig, worker_count: usize) -> String { todo!() }

#[cfg(not(unix))]
pub(super) fn run_factory_with_daemon(
    _session_name: String,
    _config: FactoryConfig,
    _phone_home: bool,
) -> Result<()> { todo!() }
