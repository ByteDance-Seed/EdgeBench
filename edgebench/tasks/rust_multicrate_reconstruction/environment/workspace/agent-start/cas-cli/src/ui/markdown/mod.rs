//! Markdown rendering for Terminal UI
//!
//! Converts markdown content to styled ratatui Lines using pulldown-cmark
//! for parsing and custom conversion to Line/Span structures.

mod renderer;
mod table;

use ratatui::text::Line;

use crate::ui::theme::ActiveTheme;
use renderer::MarkdownRenderer;

/// Render markdown content to styled ratatui Lines (full-width mode).
///
/// Supports:
/// - Headers (# ## ###)
/// - Bold (**text**) and italic (*text*)
/// - Inline code (`code`) and code blocks (```)
/// - Ordered and unordered lists with nesting
/// - Tables with box drawing
/// - Blockquotes (> text)
/// - Horizontal rules (---)
/// - Links ([text](url))
pub fn render_markdown(content: &str, theme: &ActiveTheme) -> Vec<Line<'static>> { todo!() }

#[cfg(test)]
mod tests;
