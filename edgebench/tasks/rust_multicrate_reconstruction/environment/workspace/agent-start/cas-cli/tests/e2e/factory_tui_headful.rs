//! Factory TUI headful e2e tests using cas-tui-test

#![cfg(target_os = "macos")]

use cas::store::{open_agent_store, open_prompt_queue_store};
use cas::ui::factory::{SessionInfo, SessionManager};
use cas_tui_test::{PtyRunner, PtyRunnerConfig, WaitConfig, WaitExt, screen_with_size};
use cas_types::AgentRole;
use std::process::Command;
use std::sync::{Mutex, OnceLock};
use std::time::{Duration, Instant};

use crate::fixtures::new_cas_instance;

fn headful_lock() -> &'static Mutex<()> { todo!() }

struct EnvGuard {
    saved: Vec<(String, Option<String>)>,
}

impl EnvGuard {
    fn set(vars: &[(&str, String)]) -> Self { todo!() }
}

impl Drop for EnvGuard {
    fn drop(&mut self) { todo!() }
}

fn cas_binary() -> String { todo!() }

fn wait_for_screen_text(
    runner: &PtyRunner,
    text: &str,
    timeout: Duration,
    cols: u16,
    rows: u16,
) -> Result<(), String> { todo!() }

fn terminal_window_ids(title: &str) -> Vec<String> { todo!() }

fn wait_for_terminal_window(title: &str, timeout: Duration) -> Vec<String> { todo!() }

fn close_terminal_window(window_id: &str) { todo!() }

fn wait_for_session_info(
    project_dir: &std::path::Path,
    timeout: Duration,
) -> Result<SessionInfo, String> { todo!() }

fn wait_for_worker_count(
    cas_root: &std::path::Path,
    expected: usize,
    timeout: Duration,
) -> Result<(), String> { todo!() }

fn count_worker_replies(output: &str, token: &str) -> usize { todo!() }

