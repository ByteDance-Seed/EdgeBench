//! Formatter — styled output abstraction for CLI rendering
//!
//! The Formatter is the core output primitive for all CAS CLI display. It:
//! - Auto-detects TTY vs piped output
//! - Respects the NO_COLOR environment variable
//! - Queries terminal width via crossterm
//! - Routes through ActiveTheme for consistent styling

use std::io::{self, IsTerminal, Write};

use crossterm::Command;
use crossterm::style::{
    Attribute, Color as CrosstermColor, ResetColor, SetAttribute, SetForegroundColor,
};
use ratatui::style::Color as RatatuiColor;

use crate::ui::theme::{ActiveTheme, Icons};

/// Output mode controlling style behavior
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum OutputMode {
    /// Full color and styling (TTY, no NO_COLOR)
    Styled,
    /// Plain text only (piped, NO_COLOR set, or explicitly requested)
    Plain,
}

impl OutputMode {
    /// Detect the appropriate output mode for stdout.
    pub fn detect() -> Self { todo!() }
}

/// Write a crossterm Command as ANSI bytes to any `dyn Write`.
///
/// This avoids the `crossterm::execute!` macro which requires `Sized`.
pub fn emit(w: &mut dyn Write, cmd: &impl Command) -> io::Result<()> { todo!() }

/// Styled output formatter backed by a theme and terminal detection.
///
/// The Formatter writes directly to a `Write` sink — typically stdout.
/// In styled mode it emits crossterm escape sequences; in plain mode it
/// emits raw text with no ANSI codes.
pub struct Formatter<'w> {
    writer: &'w mut dyn Write,
    mode: OutputMode,
    theme: ActiveTheme,
    width: u16,
}

impl<'w> Formatter<'w> {
    /// Create a Formatter for stdout with auto-detected mode and theme.
    pub fn stdout(writer: &'w mut dyn Write, theme: ActiveTheme) -> Self { todo!() }

    /// Create a styled Formatter (force styled mode).
    pub fn styled(writer: &'w mut dyn Write, theme: ActiveTheme) -> Self { todo!() }

    /// Create a plain-text Formatter (no ANSI codes, default theme).
    pub fn plain(writer: &'w mut dyn Write) -> Self { todo!() }

    /// Create a Formatter with explicit configuration.
    pub fn new(
        writer: &'w mut dyn Write,
        mode: OutputMode,
        theme: ActiveTheme,
        width: u16,
    ) -> Self { todo!() }

    // ========================================================================
    // Accessors
    // ========================================================================

    /// Current output mode.
    pub fn mode(&self) -> OutputMode { todo!() }

    /// Whether output is styled (TTY with color support).
    pub fn is_styled(&self) -> bool { todo!() }

    /// Terminal width in columns.
    pub fn width(&self) -> u16 { todo!() }

    /// Reference to the active theme.
    pub fn theme(&self) -> &ActiveTheme { todo!() }

    // ========================================================================
    // Primitive write helpers
    // ========================================================================

    /// Write text with a specific ratatui color.
    pub fn write_colored(&mut self, text: &str, color: RatatuiColor) -> io::Result<()> { todo!() }

    /// Write text with a crossterm color directly.
    pub fn write_crossterm_colored(&mut self, text: &str, color: CrosstermColor) -> io::Result<()> { todo!() }

    /// Write bold text with a specific color.
    pub fn write_bold_colored(&mut self, text: &str, color: RatatuiColor) -> io::Result<()> { todo!() }

    /// Write text with the primary text color.
    pub fn write_primary(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Write text with the secondary text color.
    pub fn write_secondary(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Write text with the muted text color.
    pub fn write_muted(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Write text with the accent color.
    pub fn write_accent(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Write bold text with the primary color.
    pub fn write_bold(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Write plain text with no styling.
    pub fn write_raw(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Write a newline.
    pub fn newline(&mut self) -> io::Result<()> { todo!() }

    /// Flush the underlying writer.
    pub fn flush(&mut self) -> io::Result<()> { todo!() }

    // ========================================================================
    // Semantic convenience methods
    // ========================================================================

    /// Print a section heading with accent color and bold.
    ///
    /// Output: `═══ HEADING ═══` (styled) or `--- HEADING ---` (plain)
    pub fn heading(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Print a sub-heading with the primary text color and bold.
    pub fn subheading(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Print a status line: `label  value`
    ///
    /// The label is secondary color; the value is primary text.
    pub fn status(&mut self, label: &str, value: &str) -> io::Result<()> { todo!() }

    /// Print a success status: `✓ message`
    pub fn success(&mut self, message: &str) -> io::Result<()> { todo!() }

    /// Print a warning: `⚠ message`
    pub fn warning(&mut self, message: &str) -> io::Result<()> { todo!() }

    /// Print an error: `✗ message`
    pub fn error(&mut self, message: &str) -> io::Result<()> { todo!() }

    /// Print an info message: `ℹ message`
    pub fn info(&mut self, message: &str) -> io::Result<()> { todo!() }

    /// Print a labeled field: `label: value`
    pub fn field(&mut self, label: &str, value: &str) -> io::Result<()> { todo!() }

    /// Print a labeled field with the value in accent color.
    pub fn field_accent(&mut self, label: &str, value: &str) -> io::Result<()> { todo!() }

    /// Print a bulleted list item: `• text`
    pub fn bullet(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Print a horizontal separator spanning the terminal width.
    pub fn separator(&mut self) -> io::Result<()> { todo!() }

    /// Print an indented block of text with a vertical bar prefix.
    pub fn indent_block(&mut self, text: &str) -> io::Result<()> { todo!() }

    /// Print a key-hint: `[key] description`
    pub fn key_hint(&mut self, key: &str, description: &str) -> io::Result<()> { todo!() }

    /// Print a progress indicator: `[████░░░░] 50%`
    pub fn progress(&mut self, current: usize, total: usize) -> io::Result<()> { todo!() }
}

// ============================================================================
// Utility functions
// ============================================================================

/// Query terminal width, defaulting to 80 columns.
pub fn terminal_width() -> u16 { todo!() }

/// Convert a ratatui Color to a crossterm Color.
///
/// Both use identical RGB representation under the hood, but they are
/// separate enum types.
pub fn to_crossterm_color(color: RatatuiColor) -> CrosstermColor { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_output_mode_detect_respects_no_color() {
        let mode = OutputMode::detect();
        // In test (non-TTY), should be Plain
        assert_eq!(mode, OutputMode::Plain);
    }

    #[test]
    fn test_plain_formatter_no_ansi() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.write_primary("hello").unwrap();
            fmt.newline().unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "hello\n");
        assert!(!output.contains("\x1b["));
    }

    #[test]
    fn test_styled_formatter_emits_ansi() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            fmt.write_primary("styled").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("\x1b["));
        assert!(output.contains("styled"));
    }



    #[test]
    fn test_success_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.success("done").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "[OK] done\n");
    }

    #[test]
    fn test_warning_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.warning("careful").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "[WARN] careful\n");
    }



    #[test]
    fn test_field_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.field("Status", "Open").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "Status: Open\n");
    }


    #[test]
    fn test_separator_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.separator().unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output.trim_end(), "-".repeat(80));
    }

    #[test]
    fn test_indent_block_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.indent_block("line 1\nline 2").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "  | line 1\n  | line 2\n");
    }

    #[test]
    fn test_key_hint_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.key_hint("q", "Quit").unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "[q] Quit\n");
    }

    #[test]
    fn test_progress_plain() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.progress(5, 10).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "[##########..........] 50%\n");
    }


    #[test]
    fn test_progress_complete() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.progress(10, 10).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("100%"));
        assert!(output.contains("####################"));
    }

    #[test]
    fn test_to_crossterm_color_rgb() {
        let color = to_crossterm_color(RatatuiColor::Rgb(128, 64, 32));
        assert_eq!(
            color,
            CrosstermColor::Rgb {
                r: 128,
                g: 64,
                b: 32
            }
        );
    }


    #[test]
    fn test_to_crossterm_color_named() {
        assert_eq!(
            to_crossterm_color(RatatuiColor::Black),
            CrosstermColor::Black
        );
        assert_eq!(
            to_crossterm_color(RatatuiColor::White),
            CrosstermColor::White
        );
        assert_eq!(
            to_crossterm_color(RatatuiColor::Red),
            CrosstermColor::DarkRed
        );
        assert_eq!(
            to_crossterm_color(RatatuiColor::LightRed),
            CrosstermColor::Red
        );
    }


    #[test]
    fn test_formatter_accessors() {
        let mut buf = Vec::new();
        let fmt = Formatter::plain(&mut buf);

        assert_eq!(fmt.mode(), OutputMode::Plain);
        assert!(!fmt.is_styled());
        assert_eq!(fmt.width(), 80);
    }



    #[test]
    fn test_combined_output() {
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            fmt.heading("Report").unwrap();
            fmt.field("Name", "Test").unwrap();
            fmt.success("All checks passed").unwrap();
            fmt.bullet("Item one").unwrap();
            fmt.bullet("Item two").unwrap();
            fmt.separator().unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("--- Report ---"));
        assert!(output.contains("Name: Test"));
        assert!(output.contains("[OK] All checks passed"));
        assert!(output.contains("  - Item one"));
        assert!(output.contains("  - Item two"));
    }

    #[test]
    fn test_styled_bold_colored() {
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            fmt.write_bold_colored("bold text", RatatuiColor::Rgb(255, 0, 0))
                .unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("bold text"));
        assert!(output.contains("\x1b["));
    }

    #[test]
    fn test_emit_fn() {
        let mut buf = Vec::new();
        emit(
            &mut buf,
            &SetForegroundColor(CrosstermColor::Rgb { r: 255, g: 0, b: 0 }),
        )
        .unwrap();
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("\x1b["));
    }
}
