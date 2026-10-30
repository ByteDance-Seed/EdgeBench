//! Mission Control: Workers Panel
//!
//! Full-width table showing two rows per agent: status/task line and detail line.

use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, Paragraph};

use super::DirectorData;
use super::agent_helpers::{self, find_agent_task, task_status_icon};
use crate::ui::theme::{ActiveTheme, get_agent_color};
use crate::ui::widgets::format_relative;

/// Render the WORKERS table panel with focus and selection support.
pub fn render_workers_panel_with_focus(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
    focused: bool,
    selected: Option<usize>,
) { todo!() }

/// Truncate text to max_len characters (UTF-8 safe)
fn truncate(text: &str, max_len: usize) -> String { todo!() }
