//! Factory TUI - Native terminal multiplexer for CAS factory mode
//!
//! Spawns and manages worker/supervisor agents directly using cas-mux,
//! with an integrated Director panel for monitoring CAS tasks/agents/activity.
//!
//! # Architecture
//!
//! The factory TUI uses a daemon + client architecture for session persistence:
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────┐
//! │                    FACTORY DAEMON                        │
//! │  (persistent process, owns PTYs, manages sessions)      │
//! │                                                         │
//! │  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐    │
//! │  │ PTY: super   │ │ PTY: worker1 │ │ PTY: worker2 │    │
//! │  │ ┌──────────┐ │ │ ┌──────────┐ │ │ ┌──────────┐ │    │
//! │  │ │ Agent    │ │ │ │ Agent    │ │ │ │ Agent    │ │    │
//! │  │ └──────────┘ │ │ └──────────┘ │ │ └──────────┘ │    │
//! │  └──────────────┘ └──────────────┘ └──────────────┘    │
//! │                                                         │
//! │  Socket: ~/.cas/factory-{session}.sock                  │
//! └─────────────────────────────────────────────────────────┘
//!            ▲
//!            │ attach/detach (socket protocol)
//!            ▼
//! ┌─────────────────────────────────────────────────────────┐
//! │                    TUI (client)                          │
//! │  - Renders terminal output from daemon                  │
//! │  - Sends keyboard input to daemon                       │
//! │  - Can disconnect without killing daemon                │
//! └─────────────────────────────────────────────────────────┘
//! ```
//!
//! # Layout
//!
//! ```text
//! ┌──────────────────┬──────────────────┬────────────────────────────┐
//! │    WORKERS       │   SUPERVISOR     │      DIRECTOR              │
//! │   (Stacked)      │                  │    (Native Widgets)        │
//! │ ┌──────────────┐ │ ┌──────────────┐ │  ┌────────────────────┐   │
//! │ │ swift-fox    │ │ │ wise-eagle   │ │  │ Tasks (ready/prog) │   │
//! │ │ (Agent CLI)  │ │ │ (Agent CLI)  │ │  ├────────────────────┤   │
//! │ ├──────────────┤ │ │              │ │  │ Agents (status)    │   │
//! │ │ calm-owl     │ │ │              │ │  ├────────────────────┤   │
//! │ │ (Agent CLI)  │ │ │              │ │  │ Activity (events)  │   │
//! │ └──────────────┘ │ └──────────────┘ │  └────────────────────┘   │
//! └──────────────────┴──────────────────┴────────────────────────────┘
//! ```
//!
//! # Key constraints
//!
//! - Workers and supervisor accept keyboard input when focused
//! - Inject mode ('i') allows programmatic prompt injection to any pane
//! - Detach with Ctrl+D keeps daemon running

mod app;
mod boot;
mod buffer_backend;
mod client;
mod clipboard;
pub(crate) mod daemon;
mod director;
mod input;
mod layout;
mod notification;
pub(crate) mod phoenix;
mod protocol;
pub mod renderer;
mod selection;
mod session;
mod status_bar;
pub use app::{FactoryApp, FactoryConfig};
pub use boot::{BootConfig, run_boot_screen_client};
pub use client::{
    attach, find_session_for_project, list_session_summaries, list_session_summaries_for_project,
    list_sessions, list_sessions_for_project,
};
pub use clipboard::copy_to_clipboard;
pub use daemon::{
    DaemonConfig, DaemonInitPhase, FactoryDaemon, ForkFirstResult, ForkResult, daemonize,
    fork_first_daemon, fork_into_daemon, run_daemon, run_daemon_after_fork,
    run_daemon_with_boot_progress,
};
pub use layout::{Direction, MissionControlLayout, PANE_SIDECAR, PaneGrid};
pub use notification::{Notifier, NotifyBackend, NotifyConfig};
pub use protocol::{ClientMessage, DaemonMessage, PaneInfo, PaneKind, SessionState};
pub use renderer::{FactoryViewMode, MissionControlFocus};
pub use selection::{Selection, apply_selection_to_line};
pub use session::{
    SessionInfo, SessionManager, create_metadata, daemon_log_path, daemon_trace_log_path,
    generate_session_name, metadata_path, panic_log_path, session_log_dir, socket_path,
    tui_log_path,
};
use std::io;
use std::path::Path;

use crossterm::{execute, terminal::SetTitle};

/// Build the terminal title string for factory mode
///
/// Format: "CAS Factory - [Project] - [Epic]" or "CAS Factory - [Project]" if no epic
fn build_terminal_title(project_dir: &Path, epic_title: Option<&str>) -> String { todo!() }

/// Set the terminal window/tab title
///
/// Uses OSC escape sequence to set the title, supported by most terminal emulators.
pub fn set_terminal_title(project_dir: &Path, epic_title: Option<&str>) { todo!() }
