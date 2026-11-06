//! Activity log widget for sidecar and factory TUI

use std::collections::{HashMap, HashSet};

use ratatui::Frame;
use ratatui::layout::Rect;
use ratatui::style::{Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{Block, BorderType, Borders, List, ListItem, ListState};

use cas_types::Event;

use crate::ui::theme::{ActiveTheme, get_agent_color};

use crate::ui::widgets::utils::{event_type_color, format_relative, truncate};

/// Configuration for activity list rendering
#[derive(Debug, Default)]
pub struct ActivityConfig {
    /// Map from agent ID to agent name (for color lookup)
    pub agent_id_to_name: HashMap<String, String>,
    /// IDs of currently active agents
    pub active_agent_ids: HashSet<String>,
    /// Maximum number of events to show
    pub max_events: usize,
}

impl ActivityConfig {
    pub fn new() -> Self { todo!() }

    pub fn with_agent_maps(
        agent_id_to_name: HashMap<String, String>,
        active_agent_ids: HashSet<String>,
    ) -> Self { todo!() }
}

/// Render a stateless activity list (for factory director)
pub fn render_activity_list(
    frame: &mut Frame,
    area: Rect,
    events: &[Event],
    theme: &ActiveTheme,
    config: &ActivityConfig,
    title: Option<&str>,
) { todo!() }

/// Render a stateful activity list (for sidecar with selection)
pub fn render_activity_list_with_state(
    frame: &mut Frame,
    area: Rect,
    events: &[Event],
    theme: &ActiveTheme,
    config: &ActivityConfig,
    state: &mut ListState,
    block: Block,
) { todo!() }

/// Build activity list items
fn build_activity_items(
    events: &[Event],
    theme: &ActiveTheme,
    config: &ActivityConfig,
    width: u16,
    max_items: usize,
) -> Vec<ListItem<'static>> { todo!() }

/// Render compact activity list for factory director
pub fn render_compact_activity_list(
    frame: &mut Frame,
    area: Rect,
    events: &[Event],
    agent_id_to_name: &HashMap<String, String>,
    theme: &ActiveTheme,
    focused: bool,
) { todo!() }
