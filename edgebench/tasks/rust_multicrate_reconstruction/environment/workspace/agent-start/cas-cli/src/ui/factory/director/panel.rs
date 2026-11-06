//! Shared sidecar panel state and rendering helpers.
//!
//! All sidecar panels (Factory, Tasks, Reminders, Changes, Activity) share
//! the same scroll/select/collapse mechanics. This module provides a
//! `PanelState` struct that owns that logic and a `PanelRegistry` that
//! groups all five panel states together.

use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, ListState, Paragraph};

use super::SidecarFocus;
use crate::ui::theme::Styles;

/// Per-panel state: scroll position and collapse flag.
#[derive(Debug, Default)]
pub struct PanelState {
    pub list_state: ListState,
    pub collapsed: bool,
}

impl PanelState {
    /// Initialize selection to 0 if nothing is selected and items exist.
    pub fn init_selection(&mut self, item_count: usize) { todo!() }

    /// Scroll up by one position.
    pub fn scroll_up(&mut self) { todo!() }

    /// Scroll down by one, bounded by `item_count`.
    pub fn scroll_down(&mut self, item_count: usize) { todo!() }

    /// Toggle the collapsed state.
    pub fn toggle_collapsed(&mut self) { todo!() }
}

/// Registry of all sidecar panel states.
#[derive(Debug, Default)]
pub struct PanelRegistry {
    pub factory: PanelState,
    pub tasks: PanelState,
    pub reminders: PanelState,
    pub changes: PanelState,
    pub activity: PanelState,
}

impl PanelRegistry {
    /// Get a mutable reference to the panel for the given focus.
    pub fn get_mut(&mut self, focus: SidecarFocus) -> Option<&mut PanelState> { todo!() }

    /// Get an immutable reference to the panel for the given focus.
    pub fn get(&self, focus: SidecarFocus) -> Option<&PanelState> { todo!() }
}

// =========================================================================
// Shared rendering helpers
// =========================================================================

/// Content description for a collapsed panel header.
pub struct CollapsedHeader<'a> {
    pub title: &'a str,
    pub count: usize,
    pub hotkey: Option<&'a str>,
    pub focused: bool,
    pub icon_style: Option<Style>,
}

/// Render a collapsed panel header: `▸ TITLE (count) [hotkey]`
pub fn render_collapsed_header(
    frame: &mut Frame,
    area: Rect,
    styles: &Styles,
    header: CollapsedHeader<'_>,
) { todo!() }

/// Render an expanded panel block with `▾ TITLE (count)` title.
///
/// Returns the inner `Rect` for content rendering.
pub fn render_panel_block(
    frame: &mut Frame,
    area: Rect,
    title: &str,
    count: usize,
    focused: bool,
    styles: &Styles,
) -> Rect { todo!() }
