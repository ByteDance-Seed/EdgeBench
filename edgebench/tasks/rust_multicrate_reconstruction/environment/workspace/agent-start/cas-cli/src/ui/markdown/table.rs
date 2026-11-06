//! Table rendering with Unicode box drawing

use pulldown_cmark::Alignment;
use ratatui::text::{Line, Span};

use crate::ui::theme::ActiveTheme;

/// Builder for markdown tables
pub struct TableBuilder {
    alignments: Vec<Alignment>,
    headers: Vec<String>,
    rows: Vec<Vec<String>>,
    current_row: Vec<String>,
    current_cell: String,
}

impl TableBuilder {
    pub fn new(alignments: Vec<Alignment>) -> Self { todo!() }

    pub fn add_cell_text(&mut self, text: &str) { todo!() }

    pub fn end_cell(&mut self) { todo!() }

    pub fn start_row(&mut self) { todo!() }

    pub fn end_row(&mut self, is_header: bool) { todo!() }

    pub fn render(self, theme: &ActiveTheme) -> Vec<Line<'static>> { todo!() }

    fn render_border_line(
        &self,
        col_widths: &[usize],
        left: char,
        mid: char,
        right: char,
        style: ratatui::style::Style,
    ) -> Line<'static> { todo!() }

    fn render_data_row(
        &self,
        cells: &[String],
        col_widths: &[usize],
        alignments: &[Alignment],
        cell_style: ratatui::style::Style,
        border_style: ratatui::style::Style,
    ) -> Line<'static> { todo!() }
}

fn pad_cell(text: &str, width: usize, alignment: Alignment) -> String { todo!() }
