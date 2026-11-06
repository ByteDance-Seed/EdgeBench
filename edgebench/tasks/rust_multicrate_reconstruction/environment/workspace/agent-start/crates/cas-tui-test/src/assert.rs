//! Assertion DSL - Test assertions for terminal output
//!
//! Provides assertions for:
//! - Text content (contains, exact, at position)
//! - Regex patterns
//! - Region-based assertions
//! - Cursor position (when available from ANSI parsing)

use crate::screen::{ScreenBuffer, VtParser};
use regex::Regex;
use thiserror::Error;

/// Errors from assertion failures
#[derive(Debug, Error)]
pub enum AssertError {
    #[error("Text not found: expected '{expected}' in output")]
    TextNotFound { expected: String },

    #[error("Text mismatch at row {row}: expected '{expected}', found '{found}'")]
    TextMismatch {
        row: usize,
        expected: String,
        found: String,
    },

    #[error("Pattern not matched: '{pattern}' not found in output")]
    PatternNotMatched { pattern: String },

    #[error("Region mismatch at ({row}, {col}): expected '{expected}', found '{found}'")]
    RegionMismatch {
        row: usize,
        col: usize,
        expected: String,
        found: String,
    },

    #[error("Row {row} out of bounds (max {max})")]
    RowOutOfBounds { row: usize, max: usize },

    #[error("Column {col} out of bounds at row {row} (max {max})")]
    ColOutOfBounds { col: usize, row: usize, max: usize },

    #[error("Invalid regex: {0}")]
    InvalidRegex(#[from] regex::Error),
}

/// Result type for assertions
pub type AssertResult = Result<(), AssertError>;

/// Screen representation for assertions
/// Splits output into lines for positional assertions
#[derive(Debug, Clone)]
pub struct Screen {
    lines: Vec<String>,
    raw: String,
    buffer: ScreenBuffer,
}

impl Screen {
    /// Create a screen from raw output
    pub fn from_output(output: &str) -> Self { todo!() }

    /// Create a screen from raw output with explicit terminal size
    pub fn from_output_with_size(output: &str, cols: u16, rows: u16) -> Self { todo!() }

    /// Get the raw output with ANSI codes
    pub fn raw(&self) -> &str { todo!() }

    /// Get cleaned lines
    pub fn lines(&self) -> &[String] { todo!() }

    /// Get number of lines
    pub fn height(&self) -> usize { todo!() }

    /// Get a specific line (0-indexed)
    pub fn line(&self, row: usize) -> Option<&str> { todo!() }

    /// Get text at a specific position
    pub fn text_at(&self, row: usize, col: usize, len: usize) -> Option<String> { todo!() }

    /// Assert that output contains text
    pub fn assert_contains(&self, text: &str) -> AssertResult { todo!() }

    /// Assert that output does not contain text
    pub fn assert_not_contains(&self, text: &str) -> AssertResult { todo!() }

    /// Assert that a specific row contains text
    pub fn assert_row_contains(&self, row: usize, text: &str) -> AssertResult { todo!() }

    /// Assert exact text at position
    pub fn assert_text_at(&self, row: usize, col: usize, expected: &str) -> AssertResult { todo!() }

    /// Assert a regex pattern matches somewhere in output
    pub fn assert_matches(&self, pattern: &str) -> AssertResult { todo!() }

    /// Assert a regex pattern matches on a specific row
    pub fn assert_row_matches(&self, row: usize, pattern: &str) -> AssertResult { todo!() }

    /// Assert a region of the screen matches expected content
    pub fn assert_region(
        &self,
        start_row: usize,
        start_col: usize,
        width: usize,
        height: usize,
        expected: &[&str],
    ) -> AssertResult { todo!() }

    /// Get the full text content as a single string
    pub fn text(&self) -> String { todo!() }

    fn region_text(&self, row: usize, col: usize, width: usize) -> Option<String> { todo!() }
}

/// Strip ANSI escape codes from a string
pub fn strip_ansi_codes(s: &str) -> String { todo!() }

/// Convenience function to create a Screen from output string
pub fn screen(output: &str) -> Screen { todo!() }

/// Convenience function to create a Screen with explicit terminal size
pub fn screen_with_size(output: &str, cols: u16, rows: u16) -> Screen { todo!() }

fn normalize_newlines(s: &str) -> String { todo!() }

fn display_width(s: &str) -> usize { todo!() }

fn char_display_width(c: char) -> usize { todo!() }

#[cfg(test)]
mod tests {
    use crate::assert::*;

    #[test]
    fn test_strip_ansi_codes() {
        let input = "\x1b[31mred\x1b[0m text";
        assert_eq!(strip_ansi_codes(input), "red text");

        let input2 = "\x1b[1;32mbold green\x1b[0m";
        assert_eq!(strip_ansi_codes(input2), "bold green");
    }

    #[test]
    fn test_screen_from_output() {
        let output = "line1\nline2\nline3";
        let screen = screen_with_size(output, 80, 3);

        assert_eq!(screen.height(), 3);
        assert_eq!(screen.line(0), Some("line1"));
        assert_eq!(screen.line(1), Some("line2"));
        assert_eq!(screen.line(2), Some("line3"));
        assert_eq!(screen.line(3), None);
    }

    #[test]
    fn test_assert_contains() {
        let screen = screen("hello world\nfoo bar");

        assert!(screen.assert_contains("hello").is_ok());
        assert!(screen.assert_contains("world").is_ok());
        assert!(screen.assert_contains("foo").is_ok());
        assert!(screen.assert_contains("missing").is_err());
    }

    #[test]
    fn test_assert_not_contains() {
        let screen = screen("hello world");

        assert!(screen.assert_not_contains("missing").is_ok());
        assert!(screen.assert_not_contains("hello").is_err());
    }



    #[test]
    fn test_assert_matches() {
        let screen = screen("value: 42\ncount: 100");

        assert!(screen.assert_matches(r"value:\s+\d+").is_ok());
        assert!(screen.assert_matches(r"count:\s+\d{3}").is_ok());
        assert!(screen.assert_matches(r"missing:\s+\d+").is_err());
    }

    #[test]
    fn test_assert_row_matches() {
        let screen = screen("item: 123\nitem: 456");

        assert!(screen.assert_row_matches(0, r"item:\s+123").is_ok());
        assert!(screen.assert_row_matches(1, r"item:\s+\d+").is_ok());
        assert!(screen.assert_row_matches(0, r"item:\s+456").is_err());
    }


    #[test]
    fn test_text_at() {
        let screen = screen_with_size("hello world", 80, 1);
        assert_eq!(screen.text_at(0, 0, 5), Some("hello".to_string()));
        assert_eq!(screen.text_at(0, 6, 5), Some("world".to_string()));
        assert_eq!(screen.text_at(1, 0, 5), None);
    }

    #[test]
    fn test_vt_cursor_overwrite() {
        let output = "12345\x1b[1GAB";
        let screen = screen(output);
        assert!(screen.assert_text_at(0, 0, "AB").is_ok());
        assert!(screen.assert_contains("AB345").is_ok());
    }
}
