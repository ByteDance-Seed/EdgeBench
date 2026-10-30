//! Factory dashboard panel - summary view of factory state
//!
//! Shows epic progress, worker status, and queue at a glance.

use cas_types::{EventType, TaskStatus};
use ratatui::Frame;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, BorderType, Borders, Paragraph};

use crate::ui::factory::director::agent_helpers;
use crate::ui::factory::director::data::DirectorData;
use crate::ui::theme::{ActiveTheme, Icons};
use crate::ui::widgets::truncate_to_width;

/// Render the factory dashboard with optional focus indicator
#[allow(clippy::too_many_arguments)]
pub fn render_with_focus(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
    focused: bool,
    selected_agent: Option<usize>,
    supervisor_name: &str,
    collapsed: bool,
) { todo!() }

/// Render epic status bar
fn render_epic_progress(frame: &mut Frame, area: Rect, data: &DirectorData, theme: &ActiveTheme) { todo!() }

/// Render worker list with current tasks
fn render_worker_list(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
    selected: Option<usize>,
    supervisor_name: &str,
) { todo!() }

/// Render summary bar with counts
fn render_summary_bar(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
    supervisor_name: &str,
) { todo!() }
