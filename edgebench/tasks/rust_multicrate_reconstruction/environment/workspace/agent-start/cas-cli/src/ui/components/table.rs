//! Table component — themed, terminal-aware table rendering
//!
//! Replaces comfy-table with a component that integrates with the Formatter
//! and theme system. Supports column alignment, width constraints, border
//! styles, and auto-truncation for narrow terminals.
//!
//! ```ignore
//! Table::new()
//!     .columns(&["ID", "Title", "Status"])
//!     .rows(vec![
//!         vec!["cas-1", "Fix bug", "Open"],
//!         vec!["cas-2", "Add feature", "Closed"],
//!     ])
//!     .border(Border::Unicode)
//!     .render(&mut fmt)?;
//! ```

use std::io;

use super::formatter::Formatter;
use super::traits::Renderable;

/// Column alignment within a table cell.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Align {
    #[default]
    Left,
    Right,
    Center,
}

/// Width constraint for a column.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Width {
    /// Automatically size to content (with optional min/max).
    #[default]
    Auto,
    /// Fixed width in characters.
    Fixed(u16),
    /// Minimum width (expands if space available).
    Min(u16),
    /// Maximum width (truncates if exceeded).
    Max(u16),
    /// Both min and max bounds.
    MinMax(u16, u16),
}

/// Column definition.
#[derive(Debug, Clone)]
pub struct Column {
    pub title: String,
    pub align: Align,
    pub width: Width,
}

impl Column {
    pub fn new(title: impl Into<String>) -> Self { todo!() }

    pub fn align(mut self, align: Align) -> Self { todo!() }

    pub fn width(mut self, width: Width) -> Self { todo!() }
}

/// Border style for table rendering.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum Border {
    /// No borders at all.
    None,
    /// ASCII borders using +, -, |.
    Ascii,
    /// Unicode box-drawing characters.
    #[default]
    Unicode,
}

/// A themed, terminal-aware table component.
///
/// Implements `Renderable` for integration with the Formatter system.
#[derive(Debug, Clone)]
pub struct Table {
    cols: Vec<Column>,
    rows: Vec<Vec<String>>,
    border: Border,
    indent: u16,
}

impl Default for Table {
    fn default() -> Self { todo!() }
}

impl Table {
    pub fn new() -> Self { todo!() }

    /// Set column definitions from simple string titles.
    ///
    /// Creates columns with default alignment (Left) and auto width.
    pub fn columns(mut self, titles: &[&str]) -> Self { todo!() }

    /// Set column definitions from `Column` structs for full control.
    pub fn columns_detailed(mut self, cols: Vec<Column>) -> Self { todo!() }

    /// Add rows of data. Each inner Vec must match the column count.
    pub fn rows(mut self, rows: Vec<Vec<impl Into<String>>>) -> Self { todo!() }

    /// Set the border style.
    pub fn border(mut self, border: Border) -> Self { todo!() }

    /// Set left indent (number of spaces before each line).
    pub fn indent(mut self, spaces: u16) -> Self { todo!() }

    /// Compute column widths based on content and constraints.
    ///
    /// Returns a Vec of widths in characters for each column.
    fn compute_widths(&self, available: u16) -> Vec<u16> { todo!() }

    /// Calculate border overhead in characters for a given number of columns.
    fn border_overhead(&self, num_cols: usize) -> u16 { todo!() }

    /// Format a cell value to a given width with alignment.
    fn format_cell(value: &str, width: u16, align: Align) -> String { todo!() }

    /// Render the horizontal border line (top, middle, or bottom).
    fn render_border_line(
        &self,
        fmt: &mut Formatter,
        widths: &[u16],
        position: BorderPosition,
    ) -> io::Result<()> { todo!() }

    /// Render a data row.
    fn render_row(
        &self,
        fmt: &mut Formatter,
        cells: &[String],
        widths: &[u16],
        is_header: bool,
    ) -> io::Result<()> { todo!() }
}

/// Position of a border line in the table.
#[derive(Debug, Clone, Copy)]
enum BorderPosition {
    Top,
    Middle,
    Bottom,
}

impl Renderable for Table {
    fn render(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn render_plain(table: &Table) -> String {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            table.render(&mut fmt).unwrap();
        }
        String::from_utf8(buf).unwrap()
    }

    fn render_plain_width(table: &Table, width: u16) -> String {
        use crate::ui::theme::ActiveTheme;
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::new(
                &mut buf,
                super::super::formatter::OutputMode::Plain,
                ActiveTheme::default(),
                width,
            );
            table.render(&mut fmt).unwrap();
        }
        String::from_utf8(buf).unwrap()
    }

    #[test]
    fn test_basic_table_unicode() {
        let table = Table::new()
            .columns(&["ID", "Title", "Status"])
            .rows(vec![
                vec!["cas-1", "Fix bug", "Open"],
                vec!["cas-2", "Add feature", "Closed"],
            ])
            .border(Border::Unicode);

        let output = render_plain(&table);
        // Should contain headers and data
        assert!(output.contains("ID"));
        assert!(output.contains("Title"));
        assert!(output.contains("Status"));
        assert!(output.contains("cas-1"));
        assert!(output.contains("Fix bug"));
        assert!(output.contains("Open"));
        assert!(output.contains("cas-2"));
        assert!(output.contains("Add feature"));
        assert!(output.contains("Closed"));
    }

    #[test]
    fn test_basic_table_ascii() {
        let table = Table::new()
            .columns(&["Name", "Value"])
            .rows(vec![vec!["alpha", "1"], vec!["beta", "2"]])
            .border(Border::Ascii);

        let output = render_plain(&table);
        assert!(output.contains("+"));
        assert!(output.contains("|"));
        assert!(output.contains("-"));
        assert!(output.contains("alpha"));
        assert!(output.contains("beta"));
    }

    #[test]
    fn test_table_no_border() {
        let table = Table::new()
            .columns(&["A", "B"])
            .rows(vec![vec!["x", "y"]])
            .border(Border::None);

        let output = render_plain(&table);
        assert!(!output.contains("|"));
        assert!(!output.contains("+"));
        assert!(output.contains("A"));
        assert!(output.contains("B"));
        assert!(output.contains("x"));
        assert!(output.contains("y"));
    }


    #[test]
    fn test_no_columns() {
        let table = Table::new().border(Border::Unicode);
        let output = render_plain(&table);
        assert!(output.is_empty());
    }

    #[test]
    fn test_column_alignment() {
        let table = Table::new()
            .columns_detailed(vec![
                Column::new("Left")
                    .align(Align::Left)
                    .width(Width::Fixed(10)),
                Column::new("Right")
                    .align(Align::Right)
                    .width(Width::Fixed(10)),
                Column::new("Center")
                    .align(Align::Center)
                    .width(Width::Fixed(10)),
            ])
            .rows(vec![vec!["abc", "abc", "abc"]])
            .border(Border::None);

        let output = render_plain(&table);
        let lines: Vec<&str> = output.lines().collect();
        // Header line
        assert!(lines[0].contains("Left"));
        assert!(lines[0].contains("Right"));
        assert!(lines[0].contains("Center"));

        // Data line — check alignment
        let data_line = lines[1];
        // Left-aligned: "abc" followed by spaces
        assert!(data_line.contains("abc       "));
        // Right-aligned: spaces followed by "abc"
        assert!(data_line.contains("       abc"));
    }

    #[test]
    fn test_format_cell_left() {
        assert_eq!(Table::format_cell("hi", 5, Align::Left), "hi   ");
    }

    #[test]
    fn test_format_cell_right() {
        assert_eq!(Table::format_cell("hi", 5, Align::Right), "   hi");
    }


    #[test]
    fn test_format_cell_truncation() {
        let result = Table::format_cell("hello world", 5, Align::Left);
        assert_eq!(result.chars().count(), 5);
        assert!(result.ends_with('\u{2026}')); // ends with …
        assert!(result.starts_with("hell"));
    }

    #[test]
    fn test_format_cell_exact_fit() {
        assert_eq!(Table::format_cell("abc", 3, Align::Left), "abc");
    }

    #[test]
    fn test_format_cell_width_one_truncation() {
        let result = Table::format_cell("hello", 1, Align::Left);
        assert_eq!(result, "h");
    }


    #[test]
    fn test_auto_truncation_narrow_terminal() {
        let table = Table::new()
            .columns(&["Name", "Description"])
            .rows(vec![vec![
                "short",
                "This is a very long description that should get truncated",
            ]])
            .border(Border::Unicode);

        // Render with a narrow width
        let output = render_plain_width(&table, 40);
        // Every line should be <= 40 chars
        for line in output.lines() {
            assert!(
                line.chars().count() <= 42, // allow small rounding
                "Line too wide ({} chars): {:?}",
                line.chars().count(),
                line
            );
        }
    }

    #[test]
    fn test_indent() {
        let table = Table::new()
            .columns(&["X"])
            .rows(vec![vec!["val"]])
            .border(Border::Ascii)
            .indent(4);

        let output = render_plain(&table);
        for line in output.lines() {
            assert!(
                line.starts_with("    "),
                "Line should be indented: {:?}",
                line
            );
        }
    }

    #[test]
    fn test_minmax_width() {
        let table = Table::new()
            .columns_detailed(vec![Column::new("Col").width(Width::MinMax(3, 8))])
            .rows(vec![vec!["ab"]]);

        let widths = table.compute_widths(80);
        assert!(widths[0] >= 3 && widths[0] <= 8);
    }

    #[test]
    fn test_missing_cells_in_row() {
        let table = Table::new()
            .columns(&["A", "B", "C"])
            .rows(vec![vec!["only_one".to_string()]])
            .border(Border::Unicode);

        // Should not panic with fewer cells than columns
        let output = render_plain(&table);
        assert!(output.contains("only_one"));
    }

    #[test]
    fn test_single_column_table() {
        let table = Table::new()
            .columns(&["Items"])
            .rows(vec![vec!["one"], vec!["two"], vec!["three"]])
            .border(Border::Unicode);

        let output = render_plain(&table);
        assert!(output.contains("Items"));
        assert!(output.contains("one"));
        assert!(output.contains("two"));
        assert!(output.contains("three"));
    }

    #[test]
    fn test_border_overhead_none() {
        let table = Table::new().border(Border::None);
        assert_eq!(table.border_overhead(1), 0);
        assert_eq!(table.border_overhead(2), 2);
        assert_eq!(table.border_overhead(3), 4);
    }

    #[test]
    fn test_border_overhead_unicode() {
        let table = Table::new().border(Border::Unicode);
        // "| col |" = 2 + 2 = 4
        assert_eq!(table.border_overhead(1), 4);
        // "| col | col |" = 2 + 3 + 2 = 7
        assert_eq!(table.border_overhead(2), 7);
        // "| col | col | col |" = 2 + 3 + 3 + 2 = 10
        assert_eq!(table.border_overhead(3), 10);
    }

    #[test]
    fn test_styled_output_contains_ansi() {
        use crate::ui::theme::ActiveTheme;
        let theme = ActiveTheme::default_dark();
        let table = Table::new()
            .columns(&["ID", "Name"])
            .rows(vec![vec!["1", "test"]])
            .border(Border::Unicode);

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            table.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        // Styled output should contain ANSI escape codes
        assert!(output.contains("\x1b["));
        assert!(output.contains("ID"));
        assert!(output.contains("test"));
    }

    #[test]
    fn test_default_border_is_unicode() {
        let table = Table::new();
        assert_eq!(table.border, Border::Unicode);
    }

}
