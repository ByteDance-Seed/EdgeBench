//! Text selection support for the factory TUI
//!
//! Provides selection tracking and highlighting for terminal panes.

use ratatui::style::Modifier;
use ratatui::text::{Line, Span};

/// Represents a text selection in a pane.
///
/// Coordinates are relative to the pane's inner area (after borders).
/// Row 0 is the top of the visible viewport at the time the selection was made.
/// The `scroll_offset` field records the pane's viewport offset when the
/// selection was created, so rendering and text extraction can adjust for
/// subsequent scrolling.
#[derive(Debug, Clone, Default)]
pub struct Selection {
    /// The pane this selection belongs to
    pub pane_name: String,
    /// Starting position (row, col) - where mouse was pressed
    pub start: (u16, u16),
    /// Ending position (row, col) - current mouse position
    pub end: (u16, u16),
    /// Whether the selection is currently active (being dragged)
    pub is_active: bool,
    /// The pane's viewport scroll offset when the selection was created.
    /// Used to adjust selection coordinates when the pane scrolls.
    pub scroll_offset: u32,
}

impl Selection {
    /// Create a new selection starting at the given position
    pub fn new(pane_name: String, row: u16, col: u16) -> Self { todo!() }

    /// Update the end position of the selection
    pub fn update_end(&mut self, row: u16, col: u16) { todo!() }

    /// Finalize the selection (mouse released)
    pub fn finalize(&mut self) { todo!() }

    /// Get normalized selection bounds (start <= end)
    ///
    /// Returns (start_row, start_col, end_row, end_col) where start is always
    /// before or equal to end in reading order.
    pub fn normalized(&self) -> (u16, u16, u16, u16) { todo!() }

    /// Check if a cell at (row, col) is within the selection
    pub fn contains(&self, row: u16, col: u16) -> bool { todo!() }

    /// Check if the selection is empty (start == end)
    pub fn is_empty(&self) -> bool { todo!() }

    /// Clear the selection
    pub fn clear(&mut self) { todo!() }
}

/// Apply selection highlighting to a line.
///
/// Takes a line and selection info, returns a new line with selected
/// characters highlighted using reversed colors.
///
/// `scroll_delta` is `current_scroll_offset - selection.scroll_offset` (as i32).
/// It shifts the selection rows so highlighting follows the text when the
/// pane is scrolled after the selection was made.
pub fn apply_selection_to_line(
    line: Line<'static>,
    row: u16,
    selection: &Selection,
    scroll_delta: i32,
) -> Line<'static> { todo!() }

#[cfg(test)]
mod tests {
    use crate::ui::factory::selection::*;

    #[test]
    fn test_selection_contains_single_line() {
        let sel = Selection {
            pane_name: "test".to_string(),
            start: (5, 10),
            end: (5, 20),
            is_active: false,
            scroll_offset: 0,
        };

        assert!(sel.contains(5, 10)); // Start
        assert!(sel.contains(5, 15)); // Middle
        assert!(sel.contains(5, 20)); // End
        assert!(!sel.contains(5, 9)); // Before
        assert!(!sel.contains(5, 21)); // After
        assert!(!sel.contains(4, 15)); // Wrong row
    }


    #[test]
    fn test_selection_normalized_reverse() {
        // Selection dragged backwards
        let sel = Selection {
            pane_name: "test".to_string(),
            start: (10, 20),
            end: (5, 10),
            is_active: false,
            scroll_offset: 0,
        };

        let (sr, sc, er, ec) = sel.normalized();
        assert_eq!((sr, sc, er, ec), (5, 10, 10, 20));
    }

    #[test]
    fn test_apply_selection_to_line() {
        let line = Line::from(vec![Span::raw("Hello World")]);
        let sel = Selection {
            pane_name: "test".to_string(),
            start: (0, 0),
            end: (0, 4),
            is_active: false,
            scroll_offset: 0,
        };

        let highlighted = apply_selection_to_line(line, 0, &sel, 0);
        assert_eq!(highlighted.spans.len(), 2); // "Hello" highlighted, " World" not
    }

}
