//! Task list widget for sidecar and factory TUI

use std::collections::{HashMap, HashSet};

use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, Borders, List, ListItem, ListState};

use cas_types::{Priority, TaskStatus, TaskType};

use crate::ui::theme::{ActiveTheme, Icons, get_agent_color};

use crate::ui::widgets::utils::{priority_color, truncate, truncate_to_width};

/// Display info for a task item
#[derive(Debug, Clone)]
pub struct TaskDisplayInfo {
    pub id: String,
    pub title: String,
    pub priority: Priority,
    pub status: TaskStatus,
    pub task_type: TaskType,
    pub assignee: Option<String>,
}

/// Configuration for task list rendering
#[derive(Debug, Default)]
pub struct TaskConfig {
    /// Map from agent ID to agent name (for color lookup)
    pub agent_id_to_name: HashMap<String, String>,
    /// IDs of currently active agents
    pub active_agent_ids: HashSet<String>,
    /// Whether to show indentation for subtasks
    pub show_indent: bool,
    /// Whether to show priority badge
    pub show_priority: bool,
    /// Whether this panel is focused
    pub focused: bool,
}

impl TaskConfig {
    pub fn new() -> Self { todo!() }

    pub fn with_agent_maps(
        agent_id_to_name: HashMap<String, String>,
        active_agent_ids: HashSet<String>,
    ) -> Self { todo!() }
}

/// Render a stateless task list (for factory director)
pub fn render_task_list(
    frame: &mut Frame,
    area: Rect,
    tasks: &[TaskDisplayInfo],
    theme: &ActiveTheme,
    config: &TaskConfig,
    title: Option<&str>,
) { todo!() }

/// Render a stateful task list (for sidecar with selection)
pub fn render_task_list_with_state(
    frame: &mut Frame,
    area: Rect,
    tasks: &[TaskDisplayInfo],
    theme: &ActiveTheme,
    config: &TaskConfig,
    state: &mut ListState,
    block: Block,
) { todo!() }

/// Build task list items
fn build_task_items(
    tasks: &[TaskDisplayInfo],
    theme: &ActiveTheme,
    config: &TaskConfig,
    width: u16,
) -> Vec<ListItem<'static>> { todo!() }

/// Build a single task item
pub fn build_task_item(
    task: &TaskDisplayInfo,
    theme: &ActiveTheme,
    config: &TaskConfig,
    width: u16,
    indented: bool,
) -> ListItem<'static> { todo!() }

/// Render compact task list for factory director (simplified version)
pub fn render_compact_task_list(
    frame: &mut Frame,
    area: Rect,
    in_progress: &[TaskDisplayInfo],
    ready: &[TaskDisplayInfo],
    theme: &ActiveTheme,
    config: &TaskConfig,
) { todo!() }
