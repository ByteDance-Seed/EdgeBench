//! Reminders panel widget for the director sidebar
//!
//! Shows pending reminders set by the supervisor. Only displayed when
//! there are active reminders in the session.

use cas_store::{Reminder, ReminderTriggerType};
use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::text::{Line, Span};
use ratatui::widgets::{List, ListItem, ListState};

use crate::ui::factory::director::data::DirectorData;
use crate::ui::theme::ActiveTheme;

/// Render the reminders section with optional focus indicator.
///
/// Only call this when `data.reminders` is non-empty.
pub fn render_with_focus(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
    focused: bool,
    collapsed: bool,
    reminders_state: Option<&mut ListState>,
) { todo!() }

/// Format a single reminder as a ListItem
fn format_reminder(
    reminder: &Reminder,
    styles: &crate::ui::theme::Styles,
    available_width: usize,
) -> ListItem<'static> { todo!() }
