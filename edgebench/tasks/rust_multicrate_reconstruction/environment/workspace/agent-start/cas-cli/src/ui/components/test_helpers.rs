//! Test helpers for component snapshot testing
//!
//! Provides `TestFormatter` — a test-only wrapper around `Formatter` that
//! renders components to an in-memory buffer, making it easy to capture
//! output for snapshot assertions.
//!
//! # Examples
//!
//! ```ignore
//! let mut tf = TestFormatter::dark();
//! tf.fmt().heading("Tasks").unwrap();
//! insta::assert_snapshot!(tf.output());
//! ```

use super::formatter::{Formatter, OutputMode};
use crate::ui::theme::{ActiveTheme, ThemeMode};

/// Test-only formatter that captures output to an in-memory buffer.
///
/// Wraps `Formatter` with convenience constructors for common test
/// configurations (dark/light theme, plain/styled mode, custom widths).
pub struct TestFormatter {
    buffer: Vec<u8>,
    theme: ActiveTheme,
    mode: OutputMode,
    width: u16,
}

impl TestFormatter {
    /// Create a TestFormatter with explicit configuration.
    pub fn new(mode: OutputMode, theme: ActiveTheme, width: u16) -> Self { todo!() }

    /// Dark theme, styled mode, 80 columns.
    pub fn dark() -> Self { todo!() }

    /// Light theme, styled mode, 80 columns.
    pub fn light() -> Self { todo!() }

    /// High contrast theme, styled mode, 80 columns.
    pub fn high_contrast() -> Self { todo!() }

    /// Plain mode (no ANSI codes), default theme, custom width.
    pub fn plain(width: u16) -> Self { todo!() }

    /// Styled mode with a specific theme and custom width.
    pub fn styled(width: u16) -> Self { todo!() }

    /// Create with a specific theme mode and width.
    pub fn with_theme(mode: ThemeMode, width: u16) -> Self { todo!() }

    /// Get a `Formatter` backed by this test buffer.
    ///
    /// Call this to render components, then use `output()` or
    /// `output_plain()` to inspect the result.
    pub fn fmt(&mut self) -> Formatter<'_> { todo!() }

    /// Get the raw rendered output (may contain ANSI escape sequences).
    pub fn output(&self) -> String { todo!() }

    /// Get the rendered output with all ANSI escape codes stripped.
    pub fn output_plain(&self) -> String { todo!() }

    /// Reset the buffer for reuse.
    pub fn reset(&mut self) { todo!() }

    /// Current terminal width setting.
    pub fn width(&self) -> u16 { todo!() }

    /// Current output mode.
    pub fn mode(&self) -> OutputMode { todo!() }

    /// Current theme mode.
    pub fn theme_mode(&self) -> ThemeMode { todo!() }
}

/// Strip ANSI escape sequences from a string.
///
/// Handles CSI sequences (`ESC[...X`), OSC sequences (`ESC]...ST`),
/// and simple escape sequences (`ESC X`).
pub fn strip_ansi_codes(s: &str) -> String { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_strip_ansi_codes_no_escapes() {
        assert_eq!(strip_ansi_codes("hello world"), "hello world");
    }

    #[test]
    fn test_strip_ansi_codes_csi() {
        // ESC[38;2;255;0;0m = set foreground RGB color
        assert_eq!(
            strip_ansi_codes("\x1b[38;2;255;0;0mred text\x1b[0m"),
            "red text"
        );
    }

    #[test]
    fn test_strip_ansi_codes_bold() {
        assert_eq!(strip_ansi_codes("\x1b[1mbold\x1b[0m"), "bold");
    }

    #[test]
    fn test_strip_ansi_codes_mixed() {
        let input = "\x1b[38;2;100;100;255m\x1b[1m═══ Title ═══\x1b[0m\n";
        assert_eq!(strip_ansi_codes(input), "═══ Title ═══\n");
    }



    #[test]
    fn test_test_formatter_plain() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().heading("Test").unwrap();
        let output = tf.output();
        assert_eq!(output, "--- Test ---\n");
        // Plain output should have no ANSI codes
        assert!(!output.contains('\x1b'));
    }

    #[test]
    fn test_test_formatter_output_plain_strips_ansi() {
        let mut tf = TestFormatter::dark();
        tf.fmt().heading("Test").unwrap();
        let plain = tf.output_plain();
        assert!(!plain.contains('\x1b'));
        assert!(plain.contains("Test"));
    }

    #[test]
    fn test_test_formatter_reset() {
        let mut tf = TestFormatter::plain(80);
        tf.fmt().heading("First").unwrap();
        assert!(!tf.output().is_empty());
        tf.reset();
        assert!(tf.output().is_empty());
    }

    #[test]
    fn test_test_formatter_accessors() {
        let tf = TestFormatter::plain(40);
        assert_eq!(tf.width(), 40);
        assert_eq!(tf.mode(), OutputMode::Plain);
        assert_eq!(tf.theme_mode(), ThemeMode::Dark); // default theme

        let tf = TestFormatter::light();
        assert_eq!(tf.theme_mode(), ThemeMode::Light);
        assert_eq!(tf.mode(), OutputMode::Styled);
    }

    #[test]
    fn test_test_formatter_with_theme() {
        let tf = TestFormatter::with_theme(ThemeMode::HighContrast, 120);
        assert_eq!(tf.theme_mode(), ThemeMode::HighContrast);
        assert_eq!(tf.width(), 120);
    }
}
