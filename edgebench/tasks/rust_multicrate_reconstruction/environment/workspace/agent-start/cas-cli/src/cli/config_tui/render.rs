use ratatui::{
    prelude::*,
    widgets::{Block, Borders, Clear, List, ListItem, Paragraph, Wrap},
};

use crate::cli::config_tui::{ConfigTuiApp, ViewMode};

impl ConfigTuiApp {
    pub(crate) fn render_header(&self, frame: &mut Frame, area: Rect) { todo!() }

    pub(crate) fn render_body(&mut self, frame: &mut Frame, area: Rect) { todo!() }

    fn render_section_list(&mut self, frame: &mut Frame, area: Rect) { todo!() }

    fn render_section_edit(&mut self, frame: &mut Frame, area: Rect) { todo!() }

    fn render_diff_view(&self, frame: &mut Frame, area: Rect) { todo!() }

    pub(crate) fn render_footer(&self, frame: &mut Frame, area: Rect) { todo!() }

    pub(crate) fn render_help_overlay(&self, frame: &mut Frame, area: Rect) { todo!() }

    pub(crate) fn render_reset_confirm(&self, frame: &mut Frame, area: Rect) { todo!() }

    pub(crate) fn render_value_edit(&self, frame: &mut Frame, area: Rect) { todo!() }
}
