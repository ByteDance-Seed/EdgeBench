//! Panel component — bordered box with title for grouping content
//!
//! An inline equivalent of ratatui's Block, using Unicode box-drawing
//! characters for styled output and ASCII for plain mode.
//!
//! ```ignore
//! Panel::new("Task Details")
//!     .content(KeyValue::new().entry("ID", "cas-1").entry("Status", "Open"))
//!     .render(&mut fmt)?;
//!
//! // Styled:
//! // ╭─ Task Details ──────────────────╮
//! // │ ID:     cas-1                   │
//! // │ Status: Open                    │
//! // ╰─────────────────────────────────╯
//! //
//! // Plain:
//! // +- Task Details -----------------+
//! // | ID:     cas-1                  |
//! // | Status: Open                   |
//! // +--------------------------------+
//! ```

use std::io;

use super::formatter::{Formatter, OutputMode};
use super::traits::Renderable;

/// A bordered panel that wraps other Renderable content.
pub struct Panel {
    title: String,
    children: Vec<Box<dyn Renderable>>,
}

impl Panel {
    /// Create a panel with a title.
    pub fn new(title: impl Into<String>) -> Self { todo!() }

    /// Add a renderable child component inside the panel.
    pub fn content(mut self, child: impl Renderable + 'static) -> Self { todo!() }

    /// Render the panel's inner content to a buffer, then wrap with borders.
    ///
    /// This two-pass approach lets us measure content width before drawing borders.
    fn render_inner(&self) -> Vec<String> { todo!() }
}

impl Renderable for Panel {
    fn render(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::ui::theme::ActiveTheme;

    /// Simple renderable for testing panel content.
    struct TextBlock(String);

    impl Renderable for TextBlock {
        fn render(&self, fmt: &mut Formatter) -> io::Result<()> {
            fmt.write_primary(&self.0)?;
            fmt.newline()
        }
    }

    fn render_plain(panel: &Panel) -> String {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            panel.render(&mut fmt).unwrap();
        }
        String::from_utf8(buf).unwrap()
    }

    fn render_plain_width(panel: &Panel, width: u16) -> String {
        let mut buf = Vec::new();
        {
            let mut fmt =
                Formatter::new(&mut buf, OutputMode::Plain, ActiveTheme::default(), width);
            panel.render(&mut fmt).unwrap();
        }
        String::from_utf8(buf).unwrap()
    }

    #[test]
    fn test_panel_with_title_plain() {
        let panel = Panel::new("Details").content(TextBlock("Hello World".to_string()));
        let output = render_plain(&panel);

        assert!(output.contains("Details"));
        assert!(output.contains("Hello World"));
        // Should have borders
        assert!(output.contains("+"));
        assert!(output.contains("|"));
    }


    #[test]
    fn test_panel_multiline_content_plain() {
        let panel = Panel::new("Multi")
            .content(TextBlock("Line one".to_string()))
            .content(TextBlock("Line two".to_string()));

        let output = render_plain(&panel);
        assert!(output.contains("Line one"));
        assert!(output.contains("Line two"));
    }

    #[test]
    fn test_panel_no_title_plain() {
        let panel = Panel::new("").content(TextBlock("content".to_string()));
        let output = render_plain(&panel);

        assert!(output.contains("content"));
        // Should still have top/bottom borders
        let lines: Vec<&str> = output.lines().collect();
        assert!(lines.len() >= 3);
    }

    #[test]
    fn test_panel_width_aware() {
        let panel = Panel::new("Test").content(TextBlock("Short".to_string()));
        let output = render_plain_width(&panel, 30);

        for line in output.lines() {
            assert!(
                line.chars().count() <= 30,
                "Line too wide ({} chars): {:?}",
                line.chars().count(),
                line
            );
        }
    }


    #[test]
    fn test_panel_styled_has_ansi() {
        let theme = ActiveTheme::default_dark();
        let panel = Panel::new("Styled").content(TextBlock("content".to_string()));

        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            panel.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("\x1b["));
        assert!(output.contains("Styled"));
        assert!(output.contains("content"));
    }

    #[test]
    fn test_panel_plain_uses_ascii_borders() {
        let panel = Panel::new("Test").content(TextBlock("x".to_string()));
        let output = render_plain(&panel);

        // ASCII mode should use + and | and -
        assert!(output.contains("+"));
        assert!(output.contains("|"));
        assert!(output.contains("-"));
        // Should NOT contain unicode box chars
        assert!(!output.contains("\u{256D}"));
        assert!(!output.contains("\u{2502}"));
    }

    #[test]
    fn test_panel_truncates_long_content() {
        let long_text = "A".repeat(200);
        let panel = Panel::new("Narrow").content(TextBlock(long_text));
        let output = render_plain_width(&panel, 40);

        for line in output.lines() {
            assert!(line.chars().count() <= 40, "Line too wide: {:?}", line);
        }
    }

    #[test]
    fn test_panel_top_border_contains_title() {
        let panel = Panel::new("My Panel");
        let output = render_plain(&panel);
        let first_line = output.lines().next().unwrap();
        assert!(first_line.contains("My Panel"));
        assert!(first_line.starts_with("+"));
        assert!(first_line.ends_with("+"));
    }

    #[test]
    fn test_panel_bottom_border() {
        let panel = Panel::new("Bottom").content(TextBlock("x".to_string()));
        let output = render_plain(&panel);
        let last_line = output.lines().last().unwrap();
        assert!(last_line.starts_with("+"));
        assert!(last_line.ends_with("+"));
        assert!(last_line.contains("-"));
    }
}
