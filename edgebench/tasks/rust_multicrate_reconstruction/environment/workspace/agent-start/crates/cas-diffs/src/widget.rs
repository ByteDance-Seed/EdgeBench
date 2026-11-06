//! Ratatui widgets for rendering diffs in the terminal.
//!
//! Provides [`DiffWidget`] as the top-level [`StatefulWidget`] for rendering
//! a [`FileDiffMetadata`] in unified or split layout. Uses the diff iterator,
//! syntax highlighter, and inline diff modules to produce fully styled output.

use std::collections::HashMap;

use ratatui::buffer::Buffer;
use ratatui::layout::Rect;
use ratatui::style::{Color, Modifier, Style};
use ratatui::text::{Line, Span};
use ratatui::widgets::{StatefulWidget, Widget};

use crate::highlight::SyntaxHighlighter;
use crate::inline_diff::{InlineSpan, compute_inline_diff};
use crate::iter::{
    DiffLineEvent, DiffStyle, HunkExpansionRegion, IterateOverDiffProps, iterate_over_diff,
};
use crate::{ChangeType, FileDiffMetadata, LineDiffType};

// --- Colors ---

const DELETION_BG: Color = Color::Rgb(60, 20, 20);
const ADDITION_BG: Color = Color::Rgb(20, 60, 20);
const DELETION_INLINE_BG: Color = Color::Rgb(120, 30, 30);
const ADDITION_INLINE_BG: Color = Color::Rgb(30, 120, 30);
const CONTEXT_FG: Color = Color::DarkGray;
const GUTTER_FG: Color = Color::DarkGray;
const SEPARATOR_FG: Color = Color::Cyan;
const HEADER_FG: Color = Color::White;
const STATS_ADD_FG: Color = Color::Green;
const STATS_DEL_FG: Color = Color::Red;

// --- DiffViewState ---

/// Scrolling and navigation state for a diff view.
#[derive(Debug, Clone, Default)]
pub struct DiffViewState {
    /// Current scroll offset in lines.
    pub scroll_offset: usize,
    /// Currently selected hunk index (for hunk-to-hunk navigation).
    pub selected_hunk: Option<usize>,
    /// Viewport height in lines (updated during render).
    pub viewport_height: usize,
}

impl DiffViewState {
    /// Scroll up by `n` lines.
    pub fn scroll_up(&mut self, n: usize) { todo!() }

    /// Scroll down by `n` lines, clamped to `max_lines`.
    pub fn scroll_down(&mut self, n: usize, max_lines: usize) { todo!() }

    /// Scroll up by one page (viewport height).
    pub fn page_up(&mut self) { todo!() }

    /// Scroll down by one page, clamped to `max_lines`.
    pub fn page_down(&mut self, max_lines: usize) { todo!() }

    /// Jump to the next hunk.
    pub fn next_hunk(&mut self, diff: &FileDiffMetadata, style: DiffStyle) { todo!() }

    /// Jump to the previous hunk.
    pub fn prev_hunk(&mut self, diff: &FileDiffMetadata, style: DiffStyle) { todo!() }
}

// --- FileHeader ---

/// Widget that renders a file diff header.
///
/// ```text
/// ── src/main.rs (Modified) ── +15 / -8 ──
/// ```
pub struct FileHeader<'a> {
    diff: &'a FileDiffMetadata,
}

impl<'a> FileHeader<'a> {
    pub fn new(diff: &'a FileDiffMetadata) -> Self { todo!() }

    fn change_type_label(&self) -> &'static str { todo!() }

    fn compute_stats(&self) -> (usize, usize) { todo!() }
}

impl Widget for FileHeader<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) { todo!() }
}

// --- HunkSeparator ---

/// Widget that renders a hunk separator with collapsed line indicator.
///
/// ```text
/// @@ -10,5 +12,7 @@ fn process_data
///   ··· 15 lines hidden ···
/// ```
pub struct HunkSeparator<'a> {
    /// The hunk specs string (e.g. `@@ -10,5 +12,7 @@`).
    pub specs: Option<&'a str>,
    /// The hunk context (function name after @@).
    pub context: Option<&'a str>,
    /// Number of collapsed (hidden) lines.
    pub collapsed_lines: usize,
}

impl<'a> HunkSeparator<'a> {
    pub fn new(collapsed_lines: usize) -> Self { todo!() }

    pub fn with_specs(mut self, specs: &'a str) -> Self { todo!() }

    pub fn with_context(mut self, context: &'a str) -> Self { todo!() }
}

impl Widget for HunkSeparator<'_> {
    fn render(self, area: Rect, buf: &mut Buffer) { todo!() }
}

// --- DiffWidget ---

/// Top-level widget for rendering a file diff.
///
/// Implements [`StatefulWidget`] with [`DiffViewState`] to support scrolling
/// and hunk navigation. Renders either unified or split view.
pub struct DiffWidget<'a> {
    diff: &'a FileDiffMetadata,
    style: DiffStyle,
    highlighter: Option<&'a SyntaxHighlighter>,
    inline_diff_mode: LineDiffType,
    show_line_numbers: bool,
    show_file_header: bool,
    expanded_hunks: Option<&'a HashMap<usize, HunkExpansionRegion>>,
    expand_all: bool,
}

impl<'a> DiffWidget<'a> {
    pub fn new(diff: &'a FileDiffMetadata, style: DiffStyle) -> Self { todo!() }

    pub fn highlighter(mut self, hl: &'a SyntaxHighlighter) -> Self { todo!() }

    pub fn inline_diff_mode(mut self, mode: LineDiffType) -> Self { todo!() }

    pub fn show_line_numbers(mut self, show: bool) -> Self { todo!() }

    pub fn show_file_header(mut self, show: bool) -> Self { todo!() }

    pub fn expanded_hunks(mut self, map: &'a HashMap<usize, HunkExpansionRegion>) -> Self { todo!() }

    pub fn expand_all(mut self, expand: bool) -> Self { todo!() }
}

impl StatefulWidget for DiffWidget<'_> {
    type State = DiffViewState;

    fn render(self, area: Rect, buf: &mut Buffer, state: &mut Self::State) { todo!() }
}

impl DiffWidget<'_> {
    fn render_unified(
        &self,
        x: u16,
        start_y: u16,
        width: u16,
        height: usize,
        buf: &mut Buffer,
        state: &DiffViewState,
    ) { todo!() }

    fn render_split(
        &self,
        x: u16,
        start_y: u16,
        width: u16,
        height: usize,
        buf: &mut Buffer,
        state: &DiffViewState,
    ) { todo!() }

    /// Highlight a line using the syntax highlighter (if available) or return plain.
    fn highlight_line(&self, text: &str) -> Vec<Span<'static>> { todo!() }

    /// Render a changed line with optional inline diff highlighting.
    fn render_change_line(
        &self,
        line_text: &str,
        is_deletion: bool,
        deletion_line: Option<&crate::iter::DiffLineMetadata>,
        addition_line: Option<&crate::iter::DiffLineMetadata>,
        bg: Color,
        inline_bg: Color,
    ) -> Vec<Span<'static>> { todo!() }
}

/// Convert InlineSpans to ratatui Spans with appropriate styling.
fn render_inline_spans(
    spans: &[InlineSpan],
    base_bg: Color,
    highlight_bg: Color,
) -> Vec<Span<'static>> { todo!() }

#[cfg(test)]
mod tests {
    use super::*;
    use crate::*;
    use ratatui::buffer::Buffer;
    use ratatui::layout::Rect;

    fn test_diff() -> FileDiffMetadata {
        FileDiffMetadata {
            name: "src/main.rs".into(),
            prev_name: None,
            change_type: ChangeType::Change,
            hunks: vec![Hunk {
                collapsed_before: 0,
                addition_start: 1,
                addition_count: 4,
                addition_lines: 1,
                addition_line_index: 0,
                deletion_start: 1,
                deletion_count: 4,
                deletion_lines: 1,
                deletion_line_index: 0,
                hunk_content: vec![
                    HunkContent::Context(ContextContent {
                        lines: 1,
                        addition_line_index: 0,
                        deletion_line_index: 0,
                    }),
                    HunkContent::Change(ChangeContent {
                        deletions: 1,
                        deletion_line_index: 1,
                        additions: 1,
                        addition_line_index: 1,
                    }),
                    HunkContent::Context(ContextContent {
                        lines: 2,
                        addition_line_index: 2,
                        deletion_line_index: 2,
                    }),
                ],
                hunk_context: None,
                hunk_specs: Some("@@ -1,4 +1,4 @@".into()),
                split_line_start: 0,
                split_line_count: 4,
                unified_line_start: 0,
                unified_line_count: 5,
                no_eof_cr_deletions: false,
                no_eof_cr_additions: false,
            }],
            split_line_count: 4,
            unified_line_count: 5,
            is_partial: true,
            deletion_lines: vec![
                "fn main() {".into(),
                "    let x = 1;".into(),
                "    println!(\"hello\");".into(),
                "}".into(),
            ],
            addition_lines: vec![
                "fn main() {".into(),
                "    let x = 2;".into(),
                "    println!(\"hello\");".into(),
                "}".into(),
            ],
        }
    }


    #[test]
    fn hunk_separator_renders() {
        let area = Rect::new(0, 0, 80, 1);
        let mut buf = Buffer::empty(area);
        HunkSeparator::new(15)
            .with_specs("@@ -10,5 +12,7 @@")
            .with_context("fn process_data")
            .render(area, &mut buf);

        let content: String = buf
            .content()
            .iter()
            .map(|c| c.symbol().chars().next().unwrap_or(' '))
            .collect();
        assert!(content.contains("@@ -10,5 +12,7 @@"));
        assert!(content.contains("15 lines hidden"));
    }

    #[test]
    fn unified_diff_renders_to_buffer() {
        let diff = test_diff();
        // 1 header + 5 unified lines
        let area = Rect::new(0, 0, 60, 7);
        let mut buf = Buffer::empty(area);
        let mut state = DiffViewState::default();

        DiffWidget::new(&diff, DiffStyle::Unified)
            .show_line_numbers(true)
            .show_file_header(true)
            .render(area, &mut buf, &mut state);

        // Verify viewport_height was set
        assert_eq!(state.viewport_height, 6); // 7 - 1 header

        // Check that something was rendered (non-empty buffer)
        let has_content = buf.content().iter().any(|c| c.symbol() != " ");
        assert!(has_content, "buffer should have content");
    }

    #[test]
    fn split_diff_divides_area() {
        let diff = test_diff();
        let area = Rect::new(0, 0, 80, 6);
        let mut buf = Buffer::empty(area);
        let mut state = DiffViewState::default();

        DiffWidget::new(&diff, DiffStyle::Split)
            .show_line_numbers(true)
            .show_file_header(true)
            .render(area, &mut buf, &mut state);

        // Check the divider character exists at the midpoint
        let mid = 39; // half_width - 1 = 40 - 1
        let has_divider = (1..6).any(|row| {
            let cell = &buf[(mid, row)];
            cell.symbol() == "│"
        });
        assert!(has_divider, "split view should have vertical divider");
    }


    #[test]
    fn hunk_navigation() {
        let diff = test_diff();
        let mut state = DiffViewState::default();

        state.next_hunk(&diff, DiffStyle::Unified);
        assert_eq!(state.selected_hunk, Some(0));
        assert_eq!(state.scroll_offset, 0);

        // Only 1 hunk, so next should not advance
        state.next_hunk(&diff, DiffStyle::Unified);
        assert_eq!(state.selected_hunk, Some(0));

        // Prev from 0 should not go below
        state.prev_hunk(&diff, DiffStyle::Unified);
        assert_eq!(state.selected_hunk, Some(0));
    }

    #[test]
    fn page_navigation() {
        let mut state = DiffViewState {
            scroll_offset: 50,
            selected_hunk: None,
            viewport_height: 20,
        };

        state.page_up();
        assert_eq!(state.scroll_offset, 30);

        state.page_down(100);
        assert_eq!(state.scroll_offset, 50);
    }


    #[test]
    fn zero_area_renders_without_panic() {
        let diff = test_diff();
        let area = Rect::new(0, 0, 0, 0);
        let mut buf = Buffer::empty(area);
        let mut state = DiffViewState::default();

        DiffWidget::new(&diff, DiffStyle::Unified).render(area, &mut buf, &mut state);
    }
}
