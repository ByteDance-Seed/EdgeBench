//! Syntax highlighting for diff lines using syntect.
//!
//! Converts source code lines into styled [`ratatui::text::Span`]s with
//! proper syntax colors. Supports composing syntax highlighting with
//! inline diff span boundaries for overlay rendering.

use std::path::Path;

use ratatui::style::{Color, Modifier, Style};
use ratatui::text::Span;
use syntect::easy::HighlightLines;
use syntect::highlighting::{FontStyle, ThemeSet};
use syntect::parsing::{SyntaxReference, SyntaxSet};

/// Syntax highlighter backed by syntect.
///
/// Wraps a [`SyntaxSet`] and a theme, providing methods to convert source
/// lines into ratatui [`Span`]s with appropriate foreground colors.
///
/// # Language detection
///
/// Language is detected from the filename extension using syntect's built-in
/// mapping. If the extension is unknown, lines are returned as unstyled plain
/// text.
pub struct SyntaxHighlighter {
    syntax_set: SyntaxSet,
    theme: syntect::highlighting::Theme,
}

impl SyntaxHighlighter {
    /// Create a highlighter with the default syntax set and `base16-ocean.dark`
    /// theme.
    pub fn new() -> Self { todo!() }

    /// Create a highlighter with a specific theme name.
    ///
    /// Falls back to `base16-ocean.dark` if the theme name is not found in the
    /// default theme set.
    pub fn with_theme(theme_name: &str) -> Self { todo!() }

    /// Highlight a single line of source code, returning styled spans.
    ///
    /// The language is detected from `filename` using extension lookup with
    /// fallback mappings for languages not in syntect's default bundle
    /// (TypeScript, TOML, Elixir, etc.). If the language cannot be determined,
    /// the line is returned as a single unstyled span.
    pub fn highlight_line(&self, line: &str, filename: &str) -> Vec<Span<'static>> { todo!() }

    /// Highlight multiple lines with persistent parse state across lines.
    ///
    /// This produces more accurate results than calling [`highlight_line`]
    /// individually because the parser carries state (e.g. multi-line strings,
    /// block comments) across lines.
    ///
    /// [`highlight_line`]: Self::highlight_line
    pub fn highlight_lines(&self, lines: &[&str], filename: &str) -> Vec<Vec<Span<'static>>> { todo!() }

    /// Access the underlying syntax set (useful for language detection checks).
    pub fn syntax_set(&self) -> &SyntaxSet { todo!() }

    /// Find the best syntax for a filename, with fallback mappings for
    /// languages not in syntect's default bundle.
    fn find_syntax(&self, filename: &str) -> &SyntaxReference { todo!() }
}

impl Default for SyntaxHighlighter {
    fn default() -> Self { todo!() }
}

/// Convert syntect highlight regions to ratatui spans.
fn syntect_regions_to_spans(
    regions: &[(syntect::highlighting::Style, &str)],
) -> Vec<Span<'static>> { todo!() }

/// An inline diff range within a line, marking a changed region.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct InlineDiffSpan {
    /// Byte offset where the changed region starts.
    pub start: usize,
    /// Byte offset where the changed region ends (exclusive).
    pub end: usize,
}

/// Split syntax-highlighted spans at inline diff boundaries, applying an
/// overlay style to changed regions.
///
/// This composites syntax highlighting (foreground colors from the language
/// grammar) with diff highlighting (background color for changed portions).
/// Spans that overlap a diff region are split so the overlay applies only to
/// the changed bytes.
///
/// # Arguments
///
/// * `spans` - Syntax-highlighted spans from [`SyntaxHighlighter::highlight_line`].
/// * `diff_ranges` - Byte ranges within the line that were changed.
/// * `overlay` - Style to merge onto spans within diff ranges (typically a
///   background color).
pub fn split_at_diff_boundaries(
    spans: &[Span<'static>],
    diff_ranges: &[InlineDiffSpan],
    overlay: Style,
) -> Vec<Span<'static>> { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn highlight_rust_produces_styled_spans() {
        let hl = SyntaxHighlighter::new();
        let spans = hl.highlight_line("fn main() {", "test.rs");
        assert!(!spans.is_empty(), "should produce at least one span");
        // `fn` keyword should get a non-default color
        let has_color = spans.iter().any(|s| s.style.fg.is_some());
        assert!(has_color, "Rust syntax should produce colored spans");
    }

    #[test]
    fn highlight_unknown_language_returns_plain() {
        let hl = SyntaxHighlighter::new();
        let spans = hl.highlight_line("some random text", "file.xyznotreal");
        assert!(!spans.is_empty());
        // Should still produce spans (plain text syntax)
        let full: String = spans.iter().map(|s| s.content.as_ref()).collect();
        assert!(full.contains("some random text"));
    }

    #[test]
    fn highlight_lines_carries_state() {
        let hl = SyntaxHighlighter::new();
        let lines = vec!["/*", " * inside comment", " */", "fn main() {}"];
        let result = hl.highlight_lines(&lines, "test.rs");
        assert_eq!(result.len(), 4);
        // Each line should produce at least one span
        for (i, spans) in result.iter().enumerate() {
            assert!(!spans.is_empty(), "line {i} should have spans");
        }
    }

    #[test]
    fn highlight_various_languages() {
        let hl = SyntaxHighlighter::new();
        let cases = [
            ("const x: number = 42;", "test.ts"),
            ("def hello():", "test.py"),
            ("package main", "test.go"),
            ("[dependencies]", "Cargo.toml"),
            ("key: value", "test.yaml"),
            ("{\"key\": \"value\"}", "test.json"),
            ("# Heading", "test.md"),
            ("#!/bin/bash", "test.sh"),
            ("defmodule Foo do", "test.ex"),
            ("let x = 42;", "test.js"),
            ("const App = () => <div />;", "test.tsx"),
            ("[package]", "test.toml"),
        ];
        for (line, filename) in &cases {
            let spans = hl.highlight_line(line, filename);
            assert!(!spans.is_empty(), "{filename}: should produce spans");
            let has_color = spans.iter().any(|s| s.style.fg.is_some());
            assert!(
                has_color,
                "{filename}: should produce colored spans, got: {spans:?}"
            );
        }
    }

    #[test]
    fn fallback_mapping_covers_missing_extensions() {
        let hl = SyntaxHighlighter::new();
        // These extensions are not in syntect's defaults but should get
        // syntax highlighting via our fallback mapping
        let fallback_cases = [
            ("ts", "js"),       // TypeScript -> JavaScript
            ("tsx", "js"),      // TSX -> JavaScript
            ("ex", "rb"),       // Elixir -> Ruby
            ("toml", "yaml"),   // TOML -> YAML
            ("svelte", "html"), // Svelte -> HTML
        ];
        for (missing_ext, fallback_ext) in &fallback_cases {
            let syn = hl.find_syntax(&format!("test.{missing_ext}"));
            let fallback_syn = hl
                .syntax_set
                .find_syntax_by_extension(fallback_ext)
                .unwrap();
            assert_eq!(
                syn.name, fallback_syn.name,
                ".{missing_ext} should map to {fallback_ext} syntax"
            );
        }
    }

    #[test]
    fn split_at_diff_boundaries_no_ranges() {
        let spans = vec![Span::raw("hello world")];
        let result = split_at_diff_boundaries(&spans, &[], Style::default());
        assert_eq!(result.len(), 1);
        assert_eq!(result[0].content.as_ref(), "hello world");
    }

    #[test]
    fn split_at_diff_boundaries_single_range() {
        let spans = vec![Span::raw("hello world")];
        let overlay = Style::default().bg(Color::Red);
        let ranges = vec![InlineDiffSpan { start: 6, end: 11 }];
        let result = split_at_diff_boundaries(&spans, &ranges, overlay);

        assert_eq!(result.len(), 2);
        assert_eq!(result[0].content.as_ref(), "hello ");
        assert!(result[0].style.bg.is_none());
        assert_eq!(result[1].content.as_ref(), "world");
        assert_eq!(result[1].style.bg, Some(Color::Red));
    }

    #[test]
    fn split_at_diff_boundaries_middle_range() {
        let spans = vec![Span::raw("abcdefgh")];
        let overlay = Style::default().bg(Color::Yellow);
        let ranges = vec![InlineDiffSpan { start: 2, end: 5 }];
        let result = split_at_diff_boundaries(&spans, &ranges, overlay);

        assert_eq!(result.len(), 3);
        assert_eq!(result[0].content.as_ref(), "ab");
        assert!(result[0].style.bg.is_none());
        assert_eq!(result[1].content.as_ref(), "cde");
        assert_eq!(result[1].style.bg, Some(Color::Yellow));
        assert_eq!(result[2].content.as_ref(), "fgh");
        assert!(result[2].style.bg.is_none());
    }

    #[test]
    fn split_preserves_syntax_foreground() {
        let styled_span = Span::styled(
            "keyword".to_owned(),
            Style::default()
                .fg(Color::Blue)
                .add_modifier(Modifier::BOLD),
        );
        let overlay = Style::default().bg(Color::Red);
        let ranges = vec![InlineDiffSpan { start: 0, end: 7 }];
        let result = split_at_diff_boundaries(&[styled_span], &ranges, overlay);

        assert_eq!(result.len(), 1);
        assert_eq!(result[0].style.fg, Some(Color::Blue));
        assert_eq!(result[0].style.bg, Some(Color::Red));
        assert!(result[0].style.add_modifier.contains(Modifier::BOLD));
    }

    #[test]
    fn split_across_multiple_spans() {
        let spans = vec![
            Span::styled("fn ".to_owned(), Style::default().fg(Color::Blue)),
            Span::styled("main".to_owned(), Style::default().fg(Color::Green)),
            Span::styled("()".to_owned(), Style::default().fg(Color::White)),
        ];
        // Diff range covers "n ma" (bytes 1..5, spanning two spans)
        let overlay = Style::default().bg(Color::Red);
        let ranges = vec![InlineDiffSpan { start: 1, end: 5 }];
        let result = split_at_diff_boundaries(&spans, &ranges, overlay);

        // "f" | "n " (diff) | "ma" (diff) | "in" | "()"
        assert_eq!(result.len(), 5);
        assert_eq!(result[0].content.as_ref(), "f");
        assert!(result[0].style.bg.is_none());
        assert_eq!(result[1].content.as_ref(), "n ");
        assert_eq!(result[1].style.bg, Some(Color::Red));
        assert_eq!(result[1].style.fg, Some(Color::Blue)); // preserves syntax color
        assert_eq!(result[2].content.as_ref(), "ma");
        assert_eq!(result[2].style.bg, Some(Color::Red));
        assert_eq!(result[2].style.fg, Some(Color::Green));
        assert_eq!(result[3].content.as_ref(), "in");
        assert!(result[3].style.bg.is_none());
        assert_eq!(result[4].content.as_ref(), "()");
        assert!(result[4].style.bg.is_none());
    }

    #[test]
    fn with_theme_fallback() {
        let hl = SyntaxHighlighter::with_theme("nonexistent-theme");
        let spans = hl.highlight_line("fn main() {}", "test.rs");
        assert!(!spans.is_empty(), "should still work with fallback theme");
    }
}
