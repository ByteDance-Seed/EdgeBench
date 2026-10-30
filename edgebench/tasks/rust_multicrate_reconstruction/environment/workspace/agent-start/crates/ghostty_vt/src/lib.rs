//! Safe Rust wrapper for libghostty-vt terminal emulation
//!
//! This crate provides a safe, ergonomic API for Ghostty's terminal emulation
//! library. It handles memory management and provides Rust-native types.
//!
//! # Example
//!
//! ```no_run
//! use ghostty_vt::Terminal;
//!
//! let mut term = Terminal::new(24, 80).expect("Failed to create terminal");
//!
//! // Process PTY output
//! term.feed(b"\x1b[1;31mHello\x1b[0m World").expect("Feed failed");
//!
//! // Get cursor position (1-indexed)
//! let (col, row) = term.cursor_position();
//!
//! // Get viewport content
//! let content = term.dump_viewport().expect("Dump failed");
//! ```

use ghostty_vt_sys as sys;
use std::ptr::NonNull;
use thiserror::Error;

/// Errors that can occur during terminal operations
#[derive(Debug, Error)]
pub enum Error {
    #[error("Failed to create terminal")]
    CreateFailed,

    #[error("Failed to feed data to terminal: code {0}")]
    FeedFailed(i32),

    #[error("Failed to resize terminal: code {0}")]
    ResizeFailed(i32),

    #[error("Failed to scroll terminal: code {0}")]
    ScrollFailed(i32),

    #[error("Failed to dump viewport")]
    DumpFailed,

    #[error("Failed to set palette: code {0}")]
    PaletteFailed(i32),
}

/// Result type for terminal operations
pub type Result<T> = std::result::Result<T, Error>;

/// RGB color value
#[derive(Debug, Clone, Copy, Default, PartialEq, Eq)]
pub struct Rgb {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

/// Cell style information
#[derive(Debug, Clone, Copy, Default)]
pub struct CellStyle {
    pub fg: Rgb,
    pub bg: Rgb,
    pub inverse: bool,
    pub bold: bool,
    pub italic: bool,
    pub underline: bool,
    pub faint: bool,
    pub invisible: bool,
    pub strikethrough: bool,
}

impl From<sys::GhosttyVtCellStyle> for CellStyle {
    fn from(s: sys::GhosttyVtCellStyle) -> Self {
        Self {
            fg: Rgb {
                r: s.fg_r,
                g: s.fg_g,
                b: s.fg_b,
            },
            bg: Rgb {
                r: s.bg_r,
                g: s.bg_g,
                b: s.bg_b,
            },
            inverse: s.flags & sys::GHOSTTY_VT_STYLE_INVERSE != 0,
            bold: s.flags & sys::GHOSTTY_VT_STYLE_BOLD != 0,
            italic: s.flags & sys::GHOSTTY_VT_STYLE_ITALIC != 0,
            underline: s.flags & sys::GHOSTTY_VT_STYLE_UNDERLINE != 0,
            faint: s.flags & sys::GHOSTTY_VT_STYLE_FAINT != 0,
            invisible: s.flags & sys::GHOSTTY_VT_STYLE_INVISIBLE != 0,
            strikethrough: s.flags & sys::GHOSTTY_VT_STYLE_STRIKETHROUGH != 0,
        }
    }
}

/// Style run for efficient rendering
#[derive(Debug, Clone)]
pub struct StyleRun {
    pub start_col: u16,
    pub end_col: u16,
    pub style: CellStyle,
}

impl From<sys::GhosttyVtStyleRun> for StyleRun {
    fn from(r: sys::GhosttyVtStyleRun) -> Self {
        Self {
            start_col: r.start_col,
            end_col: r.end_col,
            style: CellStyle {
                fg: Rgb {
                    r: r.fg_r,
                    g: r.fg_g,
                    b: r.fg_b,
                },
                bg: Rgb {
                    r: r.bg_r,
                    g: r.bg_g,
                    b: r.bg_b,
                },
                inverse: r.flags & sys::GHOSTTY_VT_STYLE_INVERSE != 0,
                bold: r.flags & sys::GHOSTTY_VT_STYLE_BOLD != 0,
                italic: r.flags & sys::GHOSTTY_VT_STYLE_ITALIC != 0,
                underline: r.flags & sys::GHOSTTY_VT_STYLE_UNDERLINE != 0,
                faint: r.flags & sys::GHOSTTY_VT_STYLE_FAINT != 0,
                invisible: r.flags & sys::GHOSTTY_VT_STYLE_INVISIBLE != 0,
                strikethrough: r.flags & sys::GHOSTTY_VT_STYLE_STRIKETHROUGH != 0,
            },
        }
    }
}

/// Scrollback buffer information
#[derive(Debug, Clone, Copy, Default)]
pub struct ScrollbackInfo {
    /// Lines scrolled back from bottom (0 = at bottom, showing latest output)
    pub viewport_offset: u32,
    /// Total lines in scrollback buffer
    pub total_scrollback: u32,
    /// Number of visible rows in viewport
    pub viewport_rows: u16,
}

/// Key modifiers for input encoding
#[derive(Debug, Clone, Copy, Default)]
pub struct KeyModifiers {
    pub shift: bool,
    pub ctrl: bool,
    pub alt: bool,
    pub super_key: bool,
}

impl KeyModifiers {
    pub fn none() -> Self {
        Self::default()
    }

    fn to_raw(self) -> u16 {
        let mut flags = 0u16;
        if self.shift {
            flags |= sys::GHOSTTY_VT_MOD_SHIFT;
        }
        if self.ctrl {
            flags |= sys::GHOSTTY_VT_MOD_CTRL;
        }
        if self.alt {
            flags |= sys::GHOSTTY_VT_MOD_ALT;
        }
        if self.super_key {
            flags |= sys::GHOSTTY_VT_MOD_SUPER;
        }
        flags
    }
}

/// A terminal emulator instance
///
/// Wraps the libghostty-vt terminal providing safe access to terminal
/// emulation functionality.
pub struct Terminal {
    ptr: NonNull<sys::GhosttyVtTerminal>,
}

// Terminal is Send because the underlying C API is thread-safe
unsafe impl Send for Terminal {}

impl Terminal {
    /// Create a new terminal with the given dimensions
    ///
    /// # Arguments
    /// * `rows` - Number of rows
    /// * `cols` - Number of columns
    pub fn new(rows: u16, cols: u16) -> Result<Self> {
        let ptr = unsafe { sys::ghostty_vt_terminal_new(cols, rows) };
        NonNull::new(ptr)
            .map(|ptr| Self { ptr })
            .ok_or(Error::CreateFailed)
    }

    /// Feed data to the terminal (process PTY output)
    ///
    /// This is the main entry point for processing terminal data. Pass the
    /// raw bytes received from the PTY.
    pub fn feed(&mut self, data: &[u8]) -> Result<()> {
        let result =
            unsafe { sys::ghostty_vt_terminal_feed(self.ptr.as_ptr(), data.as_ptr(), data.len()) };
        if result == 0 {
            Ok(())
        } else {
            Err(Error::FeedFailed(result))
        }
    }

    /// Resize the terminal
    pub fn resize(&mut self, rows: u16, cols: u16) -> Result<()> {
        let result = unsafe { sys::ghostty_vt_terminal_resize(self.ptr.as_ptr(), cols, rows) };
        if result == 0 {
            Ok(())
        } else {
            Err(Error::ResizeFailed(result))
        }
    }

    /// Get the current cursor position (col, row) - both 1-indexed
    pub fn cursor_position(&self) -> (u16, u16) {
        let mut col = 0u16;
        let mut row = 0u16;
        unsafe {
            sys::ghostty_vt_terminal_cursor_position(self.ptr.as_ptr(), &mut col, &mut row);
        }
        (col, row)
    }

    /// Set default foreground and background colors
    pub fn set_default_colors(&mut self, fg: Rgb, bg: Rgb) {
        unsafe {
            sys::ghostty_vt_terminal_set_default_colors(
                self.ptr.as_ptr(),
                fg.r,
                fg.g,
                fg.b,
                bg.r,
                bg.g,
                bg.b,
            );
        }
    }

    /// Set the terminal color palette (256 entries).
    pub fn set_palette(&mut self, colors: &[Rgb]) -> Result<()> {
        if colors.len() != 256 {
            return Err(Error::PaletteFailed(2));
        }
        let result = unsafe {
            sys::ghostty_vt_terminal_set_palette(
                self.ptr.as_ptr(),
                colors.as_ptr() as *const sys::ghostty_vt_rgb_t,
                colors.len(),
            )
        };
        if result == 0 {
            Ok(())
        } else {
            Err(Error::PaletteFailed(result))
        }
    }

    /// Dump the viewport content as a UTF-8 string
    pub fn dump_viewport(&self) -> Result<String> {
        let bytes = unsafe { sys::ghostty_vt_terminal_dump_viewport(self.ptr.as_ptr()) };

        if bytes.is_null() {
            return Err(Error::DumpFailed);
        }

        let slice = unsafe { std::slice::from_raw_parts(bytes.ptr, bytes.len) };
        let result = String::from_utf8_lossy(slice).into_owned();

        unsafe {
            sys::ghostty_vt_bytes_free(bytes);
        }

        Ok(result)
    }

    /// Dump a single viewport row as UTF-8
    pub fn dump_viewport_row(&self, row: u16) -> Result<String> {
        let bytes = unsafe { sys::ghostty_vt_terminal_dump_viewport_row(self.ptr.as_ptr(), row) };

        if bytes.is_null() {
            return Err(Error::DumpFailed);
        }

        let slice = unsafe { std::slice::from_raw_parts(bytes.ptr, bytes.len) };
        let result = String::from_utf8_lossy(slice).into_owned();

        unsafe {
            sys::ghostty_vt_bytes_free(bytes);
        }

        Ok(result)
    }

    /// Get cell styles for a viewport row
    pub fn row_cell_styles(&self, row: u16) -> Result<Vec<CellStyle>> {
        let bytes = unsafe {
            sys::ghostty_vt_terminal_dump_viewport_row_cell_styles(self.ptr.as_ptr(), row)
        };

        if bytes.is_null() {
            return Err(Error::DumpFailed);
        }

        let count = bytes.len / std::mem::size_of::<sys::GhosttyVtCellStyle>();
        let styles = unsafe {
            std::slice::from_raw_parts(bytes.ptr as *const sys::GhosttyVtCellStyle, count)
        };
        let result: Vec<CellStyle> = styles.iter().map(|s| (*s).into()).collect();

        unsafe {
            sys::ghostty_vt_bytes_free(bytes);
        }

        Ok(result)
    }

    /// Get style runs for a viewport row (more efficient for rendering)
    pub fn row_style_runs(&self, row: u16) -> Result<Vec<StyleRun>> {
        let bytes = unsafe {
            sys::ghostty_vt_terminal_dump_viewport_row_style_runs(self.ptr.as_ptr(), row)
        };

        if bytes.is_null() {
            return Err(Error::DumpFailed);
        }

        let count = bytes.len / std::mem::size_of::<sys::GhosttyVtStyleRun>();
        let runs = unsafe {
            std::slice::from_raw_parts(bytes.ptr as *const sys::GhosttyVtStyleRun, count)
        };
        let result: Vec<StyleRun> = runs.iter().map(|r| (*r).into()).collect();

        unsafe {
            sys::ghostty_vt_bytes_free(bytes);
        }

        Ok(result)
    }

    /// Get rows that have changed since last call
    ///
    /// Returns the indices of dirty rows and clears the dirty flags.
    pub fn take_dirty_rows(&mut self, total_rows: u16) -> Vec<u16> {
        let bytes = unsafe {
            sys::ghostty_vt_terminal_take_dirty_viewport_rows(self.ptr.as_ptr(), total_rows)
        };

        if bytes.is_null() {
            return Vec::new();
        }

        // Rows are packed as u16 little-endian
        let count = bytes.len / 2;
        let mut result = Vec::with_capacity(count);

        let data = unsafe { std::slice::from_raw_parts(bytes.ptr, bytes.len) };
        for i in 0..count {
            let row = u16::from_le_bytes([data[i * 2], data[i * 2 + 1]]);
            result.push(row);
        }

        unsafe {
            sys::ghostty_vt_bytes_free(bytes);
        }

        result
    }

    /// Scroll the viewport by delta lines
    ///
    /// Positive delta scrolls down, negative scrolls up.
    pub fn scroll(&mut self, delta: i32) -> Result<()> {
        let result = unsafe { sys::ghostty_vt_terminal_scroll_viewport(self.ptr.as_ptr(), delta) };
        if result == 0 {
            Ok(())
        } else {
            Err(Error::ScrollFailed(result))
        }
    }

    /// Scroll viewport to top
    pub fn scroll_to_top(&mut self) -> Result<()> {
        let result = unsafe { sys::ghostty_vt_terminal_scroll_viewport_top(self.ptr.as_ptr()) };
        if result == 0 {
            Ok(())
        } else {
            Err(Error::ScrollFailed(result))
        }
    }

    /// Scroll viewport to bottom
    pub fn scroll_to_bottom(&mut self) -> Result<()> {
        let result = unsafe { sys::ghostty_vt_terminal_scroll_viewport_bottom(self.ptr.as_ptr()) };
        if result == 0 {
            Ok(())
        } else {
            Err(Error::ScrollFailed(result))
        }
    }

    /// Get and reset the scroll delta since last call
    pub fn take_scroll_delta(&mut self) -> i32 {
        unsafe { sys::ghostty_vt_terminal_take_viewport_scroll_delta(self.ptr.as_ptr()) }
    }

    /// Get scrollback buffer information
    ///
    /// Returns information about the current scrollback state including:
    /// - viewport_offset: lines scrolled back from bottom (0 = at bottom)
    /// - total_scrollback: total lines available in scrollback
    /// - viewport_rows: number of visible rows
    pub fn scrollback_info(&self) -> ScrollbackInfo {
        let mut viewport_offset = 0u32;
        let mut total_scrollback = 0u32;
        let mut viewport_rows = 0u16;

        unsafe {
            sys::ghostty_vt_terminal_scrollback_info(
                self.ptr.as_ptr(),
                &mut viewport_offset,
                &mut total_scrollback,
                &mut viewport_rows,
            );
        }

        ScrollbackInfo {
            viewport_offset,
            total_scrollback,
            viewport_rows,
        }
    }

    /// Dump a screen row by absolute position
    ///
    /// Unlike `dump_viewport_row` which takes a viewport-relative row,
    /// this takes an absolute screen position where 0 is the oldest row
    /// in the scrollback buffer.
    ///
    /// # Arguments
    /// * `screen_row` - Absolute row position (0 = oldest in scrollback)
    pub fn dump_screen_row(&self, screen_row: u32) -> Result<String> {
        let bytes =
            unsafe { sys::ghostty_vt_terminal_dump_screen_row(self.ptr.as_ptr(), screen_row) };

        if bytes.is_null() {
            return Err(Error::DumpFailed);
        }

        let slice = unsafe { std::slice::from_raw_parts(bytes.ptr, bytes.len) };
        let result = String::from_utf8_lossy(slice).into_owned();

        unsafe {
            sys::ghostty_vt_bytes_free(bytes);
        }

        Ok(result)
    }

    /// Get style runs for a screen row by absolute position
    ///
    /// Unlike `row_style_runs` which takes a viewport-relative row,
    /// this takes an absolute screen position where 0 is the oldest row
    /// in the scrollback buffer.
    ///
    /// # Arguments
    /// * `screen_row` - Absolute row position (0 = oldest in scrollback)
    pub fn screen_row_style_runs(&self, screen_row: u32) -> Result<Vec<StyleRun>> {
        let bytes = unsafe {
            sys::ghostty_vt_terminal_screen_row_style_runs(self.ptr.as_ptr(), screen_row)
        };

        if bytes.is_null() {
            return Err(Error::DumpFailed);
        }

        let count = bytes.len / std::mem::size_of::<sys::GhosttyVtStyleRun>();
        let runs = unsafe {
            std::slice::from_raw_parts(bytes.ptr as *const sys::GhosttyVtStyleRun, count)
        };
        let result: Vec<StyleRun> = runs.iter().map(|r| (*r).into()).collect();

        unsafe {
            sys::ghostty_vt_bytes_free(bytes);
        }

        Ok(result)
    }

    /// Get hyperlink URI at position (1-indexed)
    pub fn hyperlink_at(&self, col: u16, row: u16) -> Option<String> {
        let bytes = unsafe { sys::ghostty_vt_terminal_hyperlink_at(self.ptr.as_ptr(), col, row) };

        if bytes.is_null() {
            return None;
        }

        let slice = unsafe { std::slice::from_raw_parts(bytes.ptr, bytes.len) };
        let result = String::from_utf8_lossy(slice).into_owned();

        unsafe {
            sys::ghostty_vt_bytes_free(bytes);
        }

        Some(result)
    }
}

impl Drop for Terminal {
    fn drop(&mut self) {
        unsafe {
            sys::ghostty_vt_terminal_free(self.ptr.as_ptr());
        }
    }
}

/// Encode a named key (arrows, function keys, etc.) to escape sequence
///
/// # Arguments
/// * `key` - Key name (e.g., "up", "down", "f1")
/// * `modifiers` - Modifier flags
///
/// # Returns
/// The escape sequence as bytes, or None if the key is not recognized.
pub fn encode_key(key: &str, modifiers: KeyModifiers) -> Option<Vec<u8>> {
    let bytes =
        unsafe { sys::ghostty_vt_encode_key_named(key.as_ptr(), key.len(), modifiers.to_raw()) };

    if bytes.is_null() {
        return None;
    }

    let slice = unsafe { std::slice::from_raw_parts(bytes.ptr, bytes.len) };
    let result = slice.to_vec();

    unsafe {
        sys::ghostty_vt_bytes_free(bytes);
    }

    Some(result)
}

#[cfg(test)]
mod tests {
    use crate::*;

    #[test]
    fn test_terminal_create() {
        let term = Terminal::new(24, 80);
        assert!(term.is_ok());
    }

    #[test]
    fn test_cursor_position() {
        let term = Terminal::new(24, 80).unwrap();
        let (col, row) = term.cursor_position();
        // Initial position is (1, 1) since it's 1-indexed
        assert_eq!(col, 1);
        assert_eq!(row, 1);
    }

    #[test]
    fn test_feed_and_dump() {
        let mut term = Terminal::new(24, 80).unwrap();
        term.feed(b"Hello, World!").unwrap();
        let content = term.dump_viewport().unwrap();
        assert!(content.contains("Hello, World!"));
    }

    #[test]
    fn test_ansi_colors() {
        let mut term = Terminal::new(24, 80).unwrap();
        // Red foreground, then text
        term.feed(b"\x1b[31mRed\x1b[0m Normal").unwrap();
        let content = term.dump_viewport().unwrap();
        assert!(content.contains("Red"));
        assert!(content.contains("Normal"));
    }

    #[test]
    fn test_key_modifiers() {
        let mods = KeyModifiers {
            shift: true,
            ctrl: true,
            alt: false,
            super_key: false,
        };
        let raw = mods.to_raw();
        assert_eq!(raw, sys::GHOSTTY_VT_MOD_SHIFT | sys::GHOSTTY_VT_MOD_CTRL);
    }

    #[test]
    fn test_encode_arrow_key() {
        let seq = encode_key("up", KeyModifiers::none());
        assert!(seq.is_some());
        let seq = seq.unwrap();
        // Arrow up should produce escape sequence
        assert!(!seq.is_empty());
        assert_eq!(seq[0], 0x1b); // ESC
    }

    #[test]
    fn test_scrollback_info() {
        let term = Terminal::new(24, 80).unwrap();
        let info = term.scrollback_info();
        // Initial state: at bottom, viewport_rows should match terminal size
        assert_eq!(info.viewport_offset, 0);
        assert_eq!(info.viewport_rows, 24);
        // total_scrollback should be at least viewport_rows
        assert!(info.total_scrollback >= info.viewport_rows as u32);
    }

    #[test]
    fn test_dump_screen_row() {
        let mut term = Terminal::new(24, 80).unwrap();
        term.feed(b"Hello on row").unwrap();

        // Get scrollback info to find which row to dump
        let info = term.scrollback_info();
        // The first viewport row should be at (total - viewport_rows)
        let first_viewport_row = info
            .total_scrollback
            .saturating_sub(info.viewport_rows as u32);

        let content = term.dump_screen_row(first_viewport_row);
        assert!(content.is_ok());
        let text = content.unwrap();
        assert!(text.contains("Hello on row"));
    }

    #[test]
    fn test_screen_row_style_runs() {
        let mut term = Terminal::new(24, 80).unwrap();
        // Red foreground text
        term.feed(b"\x1b[31mRed\x1b[0m Normal").unwrap();

        let info = term.scrollback_info();
        let first_viewport_row = info
            .total_scrollback
            .saturating_sub(info.viewport_rows as u32);

        let runs = term.screen_row_style_runs(first_viewport_row);
        assert!(runs.is_ok());
        let runs = runs.unwrap();
        // Should have at least one style run
        assert!(!runs.is_empty());
    }
}
