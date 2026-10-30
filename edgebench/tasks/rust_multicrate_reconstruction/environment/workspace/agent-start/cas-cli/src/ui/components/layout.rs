//! Layout compositors — Column, Row, and Divider
//!
//! These components compose other Renderable components into structured layouts.
//! They are the compositional glue that makes the component system feel like
//! bubbletea/lipgloss.
//!
//! ```ignore
//! Column::new()
//!     .child(Header::h1("CAS Doctor"))
//!     .child(Divider::new())
//!     .child(Row::new()
//!         .child(Column::new().child(Header::h2("Store")).child(kv_store))
//!         .child(Column::new().child(Header::h2("Search")).child(kv_search)))
//!     .child(Divider::new())
//!     .child(StatusLine::success("All checks passed"))
//!     .render(&mut fmt)?;
//! ```

use std::io;

use super::formatter::Formatter;
use super::traits::Renderable;

// ============================================================================
// Column — vertical stack of components
// ============================================================================

/// Vertical stack of components with optional spacing between children.
///
/// Each child is rendered sequentially with configurable blank lines between them.
///
/// ```ignore
/// Column::new()
///     .spacing(1)
///     .child(header)
///     .child(table)
///     .child(status)
///     .render(&mut fmt)?;
/// ```
pub struct Column {
    children: Vec<Box<dyn Renderable>>,
    spacing: u16,
}

impl Column {
    /// Create a new empty column layout.
    pub fn new() -> Self { todo!() }

    /// Set the number of blank lines between children (default: 0).
    pub fn spacing(mut self, lines: u16) -> Self { todo!() }

    /// Add a child component to the column.
    pub fn child(mut self, child: impl Renderable + 'static) -> Self { todo!() }

    /// Number of children in this column.
    pub fn len(&self) -> usize { todo!() }

    /// Whether the column has no children.
    pub fn is_empty(&self) -> bool { todo!() }
}

impl Default for Column {
    fn default() -> Self { todo!() }
}

impl Renderable for Column {
    fn render(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

// ============================================================================
// Row — horizontal side-by-side layout
// ============================================================================

/// Horizontal layout that renders children side-by-side.
///
/// Splits the terminal width evenly between children, rendering each into
/// a buffer and then compositing them horizontally with a configurable gap.
///
/// ```ignore
/// Row::new()
///     .gap(3)
///     .child(left_panel)
///     .child(right_panel)
///     .render(&mut fmt)?;
/// ```
pub struct Row {
    children: Vec<Box<dyn Renderable>>,
    gap: u16,
}

impl Row {
    /// Create a new empty row layout.
    pub fn new() -> Self { todo!() }

    /// Set the gap (in characters) between columns (default: 2).
    pub fn gap(mut self, chars: u16) -> Self { todo!() }

    /// Add a child component to the row.
    pub fn child(mut self, child: impl Renderable + 'static) -> Self { todo!() }

    /// Number of children in this row.
    pub fn len(&self) -> usize { todo!() }

    /// Whether the row has no children.
    pub fn is_empty(&self) -> bool { todo!() }
}

impl Default for Row {
    fn default() -> Self { todo!() }
}

impl Renderable for Row {
    fn render(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

/// Calculate the visible character length of a string, ignoring ANSI CSI/SGR
/// escape sequences (e.g. `\x1b[38;2;r;g;bm`). Does not handle OSC or other
/// non-CSI sequences.
fn strip_ansi_visible_len(s: &str) -> usize { todo!() }

// ============================================================================
// Divider — horizontal separator
// ============================================================================

/// Style of the divider line.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum DividerStyle {
    /// Light single line: ─
    #[default]
    Light,
    /// Double line: ═
    Double,
    /// Dotted line: ┄
    Dotted,
}

/// Horizontal rule / separator line.
///
/// Renders a width-aware divider using box-drawing characters in styled mode,
/// or dashes in plain mode.
///
/// ```ignore
/// Divider::new().render(&mut fmt)?;
/// Divider::double().render(&mut fmt)?;
/// Divider::dotted().render(&mut fmt)?;
/// ```
pub struct Divider {
    style: DividerStyle,
    width: Option<u16>,
}

impl Divider {
    /// Create a new light-style divider spanning the full terminal width.
    pub fn new() -> Self { todo!() }

    /// Create a double-line divider.
    pub fn double() -> Self { todo!() }

    /// Create a dotted divider.
    pub fn dotted() -> Self { todo!() }

    /// Set the divider style.
    pub fn with_style(mut self, style: DividerStyle) -> Self { todo!() }

    /// Set a fixed width (instead of using terminal width).
    pub fn with_width(mut self, width: u16) -> Self { todo!() }
}

impl Default for Divider {
    fn default() -> Self { todo!() }
}

impl Renderable for Divider {
    fn render(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ui::components::formatter::Formatter;
    use crate::ui::theme::ActiveTheme;

    // Helper: a simple Renderable for testing
    struct TextBlock {
        text: String,
    }

    impl TextBlock {
        fn new(text: &str) -> Self {
            Self {
                text: text.to_string(),
            }
        }
    }

    impl Renderable for TextBlock {
        fn render(&self, fmt: &mut Formatter) -> io::Result<()> {
            for line in self.text.lines() {
                fmt.write_primary(line)?;
                fmt.newline()?;
            }
            Ok(())
        }
    }

    // ========================================================================
    // Column tests
    // ========================================================================


    #[test]
    fn test_column_single_child() {
        let col = Column::new().child(TextBlock::new("Hello"));

        assert_eq!(col.len(), 1);
        assert!(!col.is_empty());

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            col.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "Hello\n");
    }


    #[test]
    fn test_column_with_spacing() {
        let col = Column::new()
            .spacing(1)
            .child(TextBlock::new("Section A"))
            .child(TextBlock::new("Section B"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            col.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "Section A\n\nSection B\n");
    }

    #[test]
    fn test_column_with_larger_spacing() {
        let col = Column::new()
            .spacing(2)
            .child(TextBlock::new("A"))
            .child(TextBlock::new("B"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            col.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "A\n\n\nB\n");
    }

    #[test]
    fn test_column_multiline_children() {
        let col = Column::new()
            .spacing(1)
            .child(TextBlock::new("Line 1a\nLine 1b"))
            .child(TextBlock::new("Line 2a\nLine 2b"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            col.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "Line 1a\nLine 1b\n\nLine 2a\nLine 2b\n");
    }

    #[test]
    fn test_column_no_trailing_spacing() {
        let col = Column::new().spacing(1).child(TextBlock::new("Only child"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            col.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        // No trailing blank line after last child
        assert_eq!(output, "Only child\n");
    }

    #[test]
    fn test_column_default() {
        let col = Column::default();
        assert!(col.is_empty());
        assert_eq!(col.spacing, 0);
    }

    // ========================================================================
    // Row tests
    // ========================================================================


    #[test]
    fn test_row_single_child() {
        let row = Row::new().child(TextBlock::new("Solo"));

        assert_eq!(row.len(), 1);

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            row.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Solo"));
    }

    #[test]
    fn test_row_two_children_side_by_side() {
        let row = Row::new()
            .gap(2)
            .child(TextBlock::new("Left"))
            .child(TextBlock::new("Right"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::new(
                &mut buf,
                super::super::formatter::OutputMode::Plain,
                ActiveTheme::default(),
                80,
            );
            row.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        // Both should appear on the same line
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines.len(), 1);
        assert!(lines[0].contains("Left"));
        assert!(lines[0].contains("Right"));
    }

    #[test]
    fn test_row_unequal_height_children() {
        let row = Row::new()
            .gap(2)
            .child(TextBlock::new("Short"))
            .child(TextBlock::new("Line1\nLine2\nLine3"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::new(
                &mut buf,
                super::super::formatter::OutputMode::Plain,
                ActiveTheme::default(),
                80,
            );
            row.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        let lines: Vec<&str> = output.lines().collect();
        // Should have 3 lines (max height of children)
        assert_eq!(lines.len(), 3);
        // First line should contain "Short" and "Line1"
        assert!(lines[0].contains("Short"));
        assert!(lines[0].contains("Line1"));
    }

    #[test]
    fn test_row_three_children() {
        let row = Row::new()
            .gap(1)
            .child(TextBlock::new("A"))
            .child(TextBlock::new("B"))
            .child(TextBlock::new("C"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::new(
                &mut buf,
                super::super::formatter::OutputMode::Plain,
                ActiveTheme::default(),
                60,
            );
            row.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines.len(), 1);
        assert!(lines[0].contains("A"));
        assert!(lines[0].contains("B"));
        assert!(lines[0].contains("C"));
    }


    // ========================================================================
    // Divider tests
    // ========================================================================

    #[test]
    fn test_divider_plain_light() {
        let div = Divider::new();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            div.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output.trim_end(), "-".repeat(80));
    }




    #[test]
    fn test_divider_styled_double() {
        let theme = ActiveTheme::default_dark();
        let div = Divider::double();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            div.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("\u{2550}")); // ═
    }



    #[test]
    fn test_divider_with_style() {
        let div = Divider::new().with_style(DividerStyle::Double);
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            div.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output.trim_end(), "=".repeat(80));
    }


    // ========================================================================
    // strip_ansi_visible_len tests
    // ========================================================================

    #[test]
    fn test_strip_ansi_plain_text() {
        assert_eq!(strip_ansi_visible_len("hello"), 5);
    }


    #[test]
    fn test_strip_ansi_empty() {
        assert_eq!(strip_ansi_visible_len(""), 0);
    }

    #[test]
    fn test_strip_ansi_only_escapes() {
        assert_eq!(strip_ansi_visible_len("\x1b[0m\x1b[1m"), 0);
    }

    // ========================================================================
    // Composition tests (Column + Row + Divider together)
    // ========================================================================

    #[test]
    fn test_column_with_divider() {
        let layout = Column::new()
            .child(TextBlock::new("Header"))
            .child(Divider::new().with_width(20))
            .child(TextBlock::new("Content"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            layout.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Header"));
        assert!(output.contains("--------------------"));
        assert!(output.contains("Content"));
    }

    #[test]
    fn test_nested_column_in_row() {
        let layout = Row::new()
            .gap(2)
            .child(
                Column::new()
                    .child(TextBlock::new("Left A"))
                    .child(TextBlock::new("Left B")),
            )
            .child(
                Column::new()
                    .child(TextBlock::new("Right A"))
                    .child(TextBlock::new("Right B")),
            );

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::new(
                &mut buf,
                super::super::formatter::OutputMode::Plain,
                ActiveTheme::default(),
                80,
            );
            layout.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        let lines: Vec<&str> = output.lines().collect();
        assert_eq!(lines.len(), 2);
        assert!(lines[0].contains("Left A"));
        assert!(lines[0].contains("Right A"));
        assert!(lines[1].contains("Left B"));
        assert!(lines[1].contains("Right B"));
    }

    #[test]
    fn test_full_composition() {
        let layout = Column::new()
            .spacing(0)
            .child(TextBlock::new("Title"))
            .child(Divider::new().with_width(30))
            .child(
                Row::new()
                    .gap(2)
                    .child(TextBlock::new("Col1"))
                    .child(TextBlock::new("Col2")),
            )
            .child(Divider::new().with_width(30))
            .child(TextBlock::new("Footer"));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::new(
                &mut buf,
                super::super::formatter::OutputMode::Plain,
                ActiveTheme::default(),
                60,
            );
            layout.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Title"));
        assert!(output.contains("------------------------------"));
        assert!(output.contains("Col1"));
        assert!(output.contains("Col2"));
        assert!(output.contains("Footer"));
    }
}
