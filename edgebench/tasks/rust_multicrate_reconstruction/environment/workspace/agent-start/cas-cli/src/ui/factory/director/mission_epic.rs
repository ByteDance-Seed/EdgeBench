//! Mission Control: Status Strip
//!
//! Compact single-row strip showing epic progress, task counts, and worker status chips.

use cas_types::TaskStatus;
use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::Paragraph;

use super::DirectorData;
use super::agent_helpers::count_agent_statuses;
use crate::ui::theme::{ActiveTheme, Icons};

/// Render the status strip into a single-row area.
///
/// Layout: `cas-a1b2 ████░░ 60%  Done:4 Active:2 Queue:1 Blocked:0  ●3 ◐1 ⊘0`
pub fn render_status_strip(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
) { todo!() }
