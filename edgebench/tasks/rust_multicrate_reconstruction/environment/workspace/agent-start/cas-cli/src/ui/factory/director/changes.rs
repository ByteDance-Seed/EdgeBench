//! Changes widget for the director panel

use std::collections::HashSet;

use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::widgets::ListState;

use crate::ui::factory::director::data::DirectorData;
use crate::ui::theme::ActiveTheme;
use crate::ui::widgets::{TreeItemType, render_compact_changes_list_with_state};

/// Render the changes section with optional focus indicator and scroll state
#[allow(clippy::too_many_arguments)]
pub fn render_with_focus(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
    focused: bool,
    _selected: Option<usize>,
    collapsed: bool,
    state: Option<&mut ListState>,
    collapsed_dirs: &HashSet<String>,
) -> Vec<TreeItemType> { todo!() }
