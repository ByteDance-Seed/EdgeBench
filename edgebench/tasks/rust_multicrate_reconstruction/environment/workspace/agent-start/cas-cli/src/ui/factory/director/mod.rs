//! Sidecar panels - displays CAS tasks, agents, changes, and activity
//!
//! This module provides native ratatui widgets for the factory TUI sidecar.
//! The panels are rendered directly without a containing block wrapper,
//! each section has its own header via the compact widget functions.

pub(crate) mod activity;
pub mod agent_helpers;
pub(crate) mod changes;
mod data;
mod events;
mod factory_radar;
pub mod mission_epic;
pub mod mission_workers;
pub mod panel;
mod prompts;
mod reminders;
pub(crate) mod tasks;

pub use data::{AgentSummary, DirectorData, TaskSummary};
pub use events::{DirectorEvent, DirectorEventDetector};
pub use panel::PanelRegistry;
pub use prompts::{Prompt, generate_prompt, with_response_instructions};
// PanelAreas, SidecarFocus, SidecarState, ViewMode, DiffLine, DiffLineType, render, render_with_state are already public in this module

use ratatui::Frame;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::widgets::ListState;

use crate::ui::theme::ActiveTheme;
use crate::ui::widgets::TreeItemType;

/// Which sidecar panel has focus
#[derive(Debug, Clone, Copy, PartialEq, Default)]
pub enum SidecarFocus {
    #[default]
    None,
    Factory,
    Tasks,
    Reminders,
    Changes,
    Activity,
}

/// View mode for the sidecar panel
#[derive(Debug, Clone, PartialEq, Default)]
pub enum ViewMode {
    /// Overview showing all panels
    #[default]
    Overview,
    /// Full task detail view
    TaskDetail(String),
    /// Full activity log view
    ActivityLog,
    /// File diff view (source_path, file_path)
    FileDiff(std::path::PathBuf, String),
}

/// Type of diff line for coloring
#[derive(Debug, Clone, Copy, PartialEq)]
pub enum DiffLineType {
    Context,
    Added,
    Removed,
    HunkHeader,
    FileHeader,
}

/// A processed diff line with line numbers
#[derive(Debug, Clone)]
pub struct DiffLine {
    pub old_line: Option<usize>,
    pub new_line: Option<usize>,
    pub content: String,
    pub line_type: DiffLineType,
}

impl SidecarFocus {
    /// Cycle to the next panel
    pub fn next(self) -> Self { todo!() }

    /// Cycle to the previous panel
    pub fn prev(self) -> Self { todo!() }

    /// Cycle to the next panel, skipping Reminders if there are none
    pub fn next_with_reminders(self, has_reminders: bool) -> Self { todo!() }

    /// Cycle to the previous panel, skipping Reminders if there are none
    pub fn prev_with_reminders(self, has_reminders: bool) -> Self { todo!() }
}

/// Mutable state for sidecar rendering
pub struct SidecarState<'a> {
    pub focus: SidecarFocus,
    pub tasks_state: &'a mut ListState,
    pub agents_state: &'a mut ListState,
    pub reminders_state: &'a mut ListState,
    pub changes_state: &'a mut ListState,
    pub activity_state: &'a mut ListState,
    /// Optional agent filter (filter tasks/activity by this agent name)
    pub agent_filter: Option<&'a str>,
    /// Section collapse flags
    pub factory_collapsed: bool,
    pub tasks_collapsed: bool,
    pub reminders_collapsed: bool,
    pub changes_collapsed: bool,
    pub activity_collapsed: bool,
    /// Collapsed epic IDs
    pub collapsed_epics: &'a std::collections::HashSet<String>,
    /// Collapsed directory paths in changes panel
    pub collapsed_dirs: &'a std::collections::HashSet<String>,
    /// Output: tree item types from changes panel (for scroll bounds)
    pub changes_item_types: &'a mut Vec<TreeItemType>,
}

/// Panel areas for click detection
#[derive(Debug, Clone, Copy, Default)]
pub struct PanelAreas {
    pub factory: Rect,
    pub tasks: Rect,
    pub reminders: Rect,
    pub changes: Rect,
    pub activity: Rect,
}

/// Render the sidecar panels with optional navigation state
///
/// Returns the panel areas for click detection.
pub fn render_with_state(
    frame: &mut Frame,
    area: Rect,
    data: &DirectorData,
    theme: &ActiveTheme,
    supervisor_name: &str,
    mut state: Option<&mut SidecarState>,
) -> PanelAreas { todo!() }
