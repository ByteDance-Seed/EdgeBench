//! Low-level FFI bindings to libghostty-vt
//!
//! This crate provides raw C bindings to libghostty-vt, the terminal emulation
//! library extracted from the Ghostty terminal emulator.
//!
//! For a safe Rust API, use the `ghostty_vt` crate instead.

#![allow(non_upper_case_globals)]
#![allow(non_camel_case_types)]
#![allow(non_snake_case)]

use std::os::raw::c_int;

/// Opaque handle to a terminal instance
pub type GhosttyVtTerminal = std::ffi::c_void;

/// RGB color value
#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct ghostty_vt_rgb_t {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

/// Byte buffer returned by ghostty_vt functions
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct ghostty_vt_bytes_t {
    pub ptr: *const u8,
    pub len: usize,
}

impl ghostty_vt_bytes_t {
    pub fn is_null(&self) -> bool {
        self.ptr.is_null()
    }
}

/// Cell style information (8 bytes, packed)
#[repr(C)]
#[derive(Debug, Clone, Copy, Default)]
pub struct GhosttyVtCellStyle {
    pub fg_r: u8,
    pub fg_g: u8,
    pub fg_b: u8,
    pub bg_r: u8,
    pub bg_g: u8,
    pub bg_b: u8,
    pub flags: u8,
    pub reserved: u8,
}

/// Style run for efficient rendering (12 bytes)
#[repr(C)]
#[derive(Debug, Clone, Copy)]
pub struct GhosttyVtStyleRun {
    pub start_col: u16,
    pub end_col: u16,
    pub fg_r: u8,
    pub fg_g: u8,
    pub fg_b: u8,
    pub bg_r: u8,
    pub bg_g: u8,
    pub bg_b: u8,
    pub flags: u8,
    pub reserved: u8,
}

/// Cell style flags
pub const GHOSTTY_VT_STYLE_INVERSE: u8 = 0x01;
pub const GHOSTTY_VT_STYLE_BOLD: u8 = 0x02;
pub const GHOSTTY_VT_STYLE_ITALIC: u8 = 0x04;
pub const GHOSTTY_VT_STYLE_UNDERLINE: u8 = 0x08;
pub const GHOSTTY_VT_STYLE_FAINT: u8 = 0x10;
pub const GHOSTTY_VT_STYLE_INVISIBLE: u8 = 0x20;
pub const GHOSTTY_VT_STYLE_STRIKETHROUGH: u8 = 0x40;

/// Key modifier flags
pub const GHOSTTY_VT_MOD_SHIFT: u16 = 0x0001;
pub const GHOSTTY_VT_MOD_CTRL: u16 = 0x0002;
pub const GHOSTTY_VT_MOD_ALT: u16 = 0x0004;
pub const GHOSTTY_VT_MOD_SUPER: u16 = 0x0008;

unsafe extern "C" {
    /// Create a new terminal instance
    ///
    /// # Arguments
    /// * `cols` - Number of columns
    /// * `rows` - Number of rows
    ///
    /// # Returns
    /// Pointer to terminal instance, or null on failure
    pub fn ghostty_vt_terminal_new(cols: u16, rows: u16) -> *mut GhosttyVtTerminal;

    /// Free a terminal instance
    pub fn ghostty_vt_terminal_free(terminal: *mut GhosttyVtTerminal);

    /// Set default foreground and background colors
    pub fn ghostty_vt_terminal_set_default_colors(
        terminal: *mut GhosttyVtTerminal,
        fg_r: u8,
        fg_g: u8,
        fg_b: u8,
        bg_r: u8,
        bg_g: u8,
        bg_b: u8,
    );

    /// Set the terminal palette (256 colors).
    pub fn ghostty_vt_terminal_set_palette(
        terminal: *mut GhosttyVtTerminal,
        colors: *const ghostty_vt_rgb_t,
        len: usize,
    ) -> c_int;

    /// Feed data to the terminal (process PTY output)
    ///
    /// # Returns
    /// 0 on success, non-zero on error
    pub fn ghostty_vt_terminal_feed(
        terminal: *mut GhosttyVtTerminal,
        bytes: *const u8,
        len: usize,
    ) -> c_int;

    /// Resize the terminal
    pub fn ghostty_vt_terminal_resize(
        terminal: *mut GhosttyVtTerminal,
        cols: u16,
        rows: u16,
    ) -> c_int;

    /// Scroll viewport by delta lines
    pub fn ghostty_vt_terminal_scroll_viewport(
        terminal: *mut GhosttyVtTerminal,
        delta_lines: i32,
    ) -> c_int;

    /// Scroll viewport to top
    pub fn ghostty_vt_terminal_scroll_viewport_top(terminal: *mut GhosttyVtTerminal) -> c_int;

    /// Scroll viewport to bottom
    pub fn ghostty_vt_terminal_scroll_viewport_bottom(terminal: *mut GhosttyVtTerminal) -> c_int;

    /// Get cursor position (1-indexed)
    ///
    /// # Returns
    /// true if position was retrieved, false otherwise
    pub fn ghostty_vt_terminal_cursor_position(
        terminal: *mut GhosttyVtTerminal,
        col_out: *mut u16,
        row_out: *mut u16,
    ) -> bool;

    /// Dump viewport content as UTF-8
    pub fn ghostty_vt_terminal_dump_viewport(
        terminal: *mut GhosttyVtTerminal,
    ) -> ghostty_vt_bytes_t;

    /// Dump a single viewport row as UTF-8
    pub fn ghostty_vt_terminal_dump_viewport_row(
        terminal: *mut GhosttyVtTerminal,
        row: u16,
    ) -> ghostty_vt_bytes_t;

    /// Get cell styles for a viewport row
    pub fn ghostty_vt_terminal_dump_viewport_row_cell_styles(
        terminal: *mut GhosttyVtTerminal,
        row: u16,
    ) -> ghostty_vt_bytes_t;

    /// Get style runs for a viewport row
    pub fn ghostty_vt_terminal_dump_viewport_row_style_runs(
        terminal: *mut GhosttyVtTerminal,
        row: u16,
    ) -> ghostty_vt_bytes_t;

    /// Get rows that have changed since last call
    ///
    /// Returns array of u16 row indices packed as bytes.
    pub fn ghostty_vt_terminal_take_dirty_viewport_rows(
        terminal: *mut GhosttyVtTerminal,
        rows: u16,
    ) -> ghostty_vt_bytes_t;

    /// Get and reset viewport scroll delta
    pub fn ghostty_vt_terminal_take_viewport_scroll_delta(terminal: *mut GhosttyVtTerminal) -> i32;

    /// Get hyperlink URI at position (1-indexed)
    pub fn ghostty_vt_terminal_hyperlink_at(
        terminal: *mut GhosttyVtTerminal,
        col: u16,
        row: u16,
    ) -> ghostty_vt_bytes_t;

    /// Encode a named key with modifiers
    pub fn ghostty_vt_encode_key_named(
        name_ptr: *const u8,
        name_len: usize,
        modifiers: u16,
    ) -> ghostty_vt_bytes_t;

    /// Free a byte buffer returned by ghostty_vt functions
    pub fn ghostty_vt_bytes_free(bytes: ghostty_vt_bytes_t);

    // ===== Scrollback Functions =====

    /// Get scrollback information
    ///
    /// # Arguments
    /// * `terminal` - Terminal instance
    /// * `viewport_offset` - Output: lines scrolled back from bottom (0 = at bottom)
    /// * `total_scrollback` - Output: total lines in scrollback buffer
    /// * `viewport_rows` - Output: number of visible rows
    ///
    /// # Returns
    /// true if successful, false otherwise
    pub fn ghostty_vt_terminal_scrollback_info(
        terminal: *mut GhosttyVtTerminal,
        viewport_offset: *mut u32,
        total_scrollback: *mut u32,
        viewport_rows: *mut u16,
    ) -> bool;

    /// Dump a screen row by absolute position
    ///
    /// # Arguments
    /// * `terminal` - Terminal instance
    /// * `screen_row` - Absolute row position (0 = oldest row in scrollback)
    ///
    /// # Returns
    /// UTF-8 encoded row content, or null bytes on error
    pub fn ghostty_vt_terminal_dump_screen_row(
        terminal: *mut GhosttyVtTerminal,
        screen_row: u32,
    ) -> ghostty_vt_bytes_t;

    /// Get style runs for a screen row by absolute position
    ///
    /// # Arguments
    /// * `terminal` - Terminal instance
    /// * `screen_row` - Absolute row position (0 = oldest row in scrollback)
    ///
    /// # Returns
    /// Array of GhosttyVtStyleRun packed as bytes, or null bytes on error
    pub fn ghostty_vt_terminal_screen_row_style_runs(
        terminal: *mut GhosttyVtTerminal,
        screen_row: u32,
    ) -> ghostty_vt_bytes_t;
}
