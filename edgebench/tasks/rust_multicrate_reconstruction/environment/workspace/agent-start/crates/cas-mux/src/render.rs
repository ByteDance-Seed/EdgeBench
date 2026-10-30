//! Rendering for the multiplexer using ratatui
//!
//! Handles rendering multiple panes to the terminal.

use crate::mux::Mux;
use crate::pane::Pane;
use ratatui::Frame;
use ratatui::layout::{Constraint, Direction, Layout, Rect};
use ratatui::style::{Color, Style};
use ratatui::text::Text;
use ratatui::widgets::{Block, Borders, Paragraph};

/// Layout direction for panes
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LayoutDirection {
    #[default]
    Horizontal,
    Vertical,
}

/// Renderer for the multiplexer
#[derive(Default)]
pub struct Renderer {
    /// Layout direction
    direction: LayoutDirection,
    /// Whether to show borders
    border: bool,
}

impl Renderer {
    /// Create a new renderer
    pub fn new() -> Self { todo!() }

    /// Set layout direction
    pub fn set_direction(&mut self, direction: LayoutDirection) { todo!() }

    /// Enable/disable borders
    pub fn set_border(&mut self, border: bool) { todo!() }

    /// Calculate layout constraints for panes
    fn calculate_constraints(&self, pane_count: usize) -> Vec<Constraint> { todo!() }

    /// Render all panes from the multiplexer
    pub fn render(&self, frame: &mut Frame, mux: &Mux) { todo!() }

    /// Render a single pane
    fn render_pane(&self, frame: &mut Frame, pane: &Pane, area: Rect) { todo!() }

    /// Render a single pane to a specific area (for custom layouts)
    pub fn render_pane_to(&self, frame: &mut Frame, pane: &Pane, area: Rect) { todo!() }
}

/// Parse a hex color string (#RRGGBB or RRGGBB) to a ratatui Color
fn parse_hex_color(hex: &str) -> Option<Color> { todo!() }

#[cfg(test)]
mod tests {
    use crate::render::*;

    #[test]
    fn test_calculate_constraints_horizontal() {
        let renderer = Renderer::new();
        let constraints = renderer.calculate_constraints(2);
        assert_eq!(constraints.len(), 2);
    }

    #[test]
    fn test_calculate_constraints_empty() {
        let renderer = Renderer::new();
        let constraints = renderer.calculate_constraints(0);
        assert!(constraints.is_empty());
    }

    #[test]
    fn test_parse_hex_color() {
        assert!(matches!(
            parse_hex_color("#FF0000"),
            Some(Color::Rgb(255, 0, 0))
        ));
        assert!(matches!(
            parse_hex_color("00FF00"),
            Some(Color::Rgb(0, 255, 0))
        ));
        assert!(parse_hex_color("#FFF").is_none()); // Too short
    }

    #[test]
    fn test_layout_direction_default() {
        let renderer = Renderer::new();
        assert_eq!(renderer.direction, LayoutDirection::Horizontal);
    }
}
