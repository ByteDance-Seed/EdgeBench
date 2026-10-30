//! Activity log widget for the director panel

use ratatui::Frame;
use ratatui::layout::Rect;

use crate::ui::factory::director::data::DirectorData;
use crate::ui::theme::ActiveTheme;
use crate::ui::widgets::render_compact_activity_list;

/// Render the activity section with optional focus indicator
pub fn render_with_focus(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
    focused: bool,
    _selected: Option<usize>,
    collapsed: bool,
) { todo!() }
