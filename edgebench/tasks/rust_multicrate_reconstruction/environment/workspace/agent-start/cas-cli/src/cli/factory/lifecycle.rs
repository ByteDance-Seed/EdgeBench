use std::io::{self, Write};

use anyhow::{Result, bail};
use crossterm::style::Color;

use crate::cli::interactive::{PickerItem, PickerTag, pick};
use crate::ui::components::{Formatter, Renderable, StatusLine};
use crate::ui::factory::{SessionInfo, SessionManager};
use crate::ui::theme::ActiveTheme;

fn terminate_process(pid: u32) -> Result<()> { todo!() }

/// Build a picker item for a session (shared by kill and attach).
pub(super) fn session_picker_item(s: &SessionInfo) -> PickerItem { todo!() }

/// Kill a factory session. If no name is given, show an interactive picker.
pub fn execute_kill(name: Option<&str>, force: bool) -> Result<()> { todo!() }

/// Kill all factory sessions
pub fn execute_kill_all(force: bool) -> Result<()> { todo!() }

/// Kill a session if it's running (internal use, no confirmation)
pub(super) fn kill_session_if_running(name: &str) -> Result<bool> { todo!() }

/// Kill all orphaned daemon processes (running but socket gone)
pub(super) fn cleanup_orphaned_daemons() -> usize { todo!() }
