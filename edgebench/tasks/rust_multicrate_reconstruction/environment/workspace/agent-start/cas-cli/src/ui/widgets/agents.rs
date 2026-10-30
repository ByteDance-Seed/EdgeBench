//! Agent list widget for sidecar and factory TUI

use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, BorderType, Borders, List, ListItem, ListState};

use cas_types::{AgentStatus, AgentType};
use chrono::{DateTime, Utc};

use crate::ui::theme::{ActiveTheme, Icons, get_agent_color};

use crate::ui::widgets::utils::{format_relative, truncate_to_width};

/// Display info for an agent
#[derive(Debug, Clone)]
pub struct AgentDisplayInfo {
    pub id: String,
    pub short_id: String,
    pub name: String,
    pub agent_type: AgentType,
    pub status: AgentStatus,
    /// Current task ID (if any)
    pub current_task_id: Option<String>,
    /// Current task title (if any)
    pub current_task_title: Option<String>,
    /// Latest activity (description, timestamp)
    pub latest_activity: Option<(String, DateTime<Utc>)>,
    /// Last heartbeat timestamp (for showing staleness)
    pub last_heartbeat: Option<DateTime<Utc>>,
}

/// Configuration for agent list rendering
#[derive(Debug, Default)]
pub struct AgentConfig {
    /// Whether to show the type badge (P/S/W/C)
    pub show_type_badge: bool,
    /// Whether to show current task under agent
    pub show_current_task: bool,
}

impl AgentConfig {
    pub fn new() -> Self { todo!() }

    pub fn compact() -> Self { todo!() }
}

/// Render a stateless agent list (for factory director)
pub fn render_agent_list(
    frame: &mut Frame,
    area: Rect,
    agents: &[AgentDisplayInfo],
    theme: &ActiveTheme,
    config: &AgentConfig,
    title: Option<&str>,
) { todo!() }

/// Render a stateful agent list (for sidecar with selection)
pub fn render_agent_list_with_state(
    frame: &mut Frame,
    area: Rect,
    agents: &[AgentDisplayInfo],
    theme: &ActiveTheme,
    config: &AgentConfig,
    state: &mut ListState,
    block: Block,
) { todo!() }

/// Build agent list items
fn build_agent_items(
    agents: &[AgentDisplayInfo],
    theme: &ActiveTheme,
    config: &AgentConfig,
    width: u16,
) -> Vec<ListItem<'static>> { todo!() }

/// Build a single agent item (may be multiple lines if showing task)
fn build_agent_item(
    agent: &AgentDisplayInfo,
    theme: &ActiveTheme,
    config: &AgentConfig,
    width: u16,
) -> ListItem<'static> { todo!() }

/// Render compact agent list for factory director (simplified single-line version)
pub fn render_compact_agent_list(
    frame: &mut Frame,
    area: Rect,
    agents: &[AgentDisplayInfo],
    theme: &ActiveTheme,
    focused: bool,
) { todo!() }
