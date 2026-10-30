//! VT sequence parser using the `vte` crate
//!
//! Parses terminal escape sequences and updates the screen buffer accordingly.

use crate::screen::buffer::{Attr, ScreenBuffer};
use crate::screen::cell::Color;
use vte::{Params, Parser, Perform};

/// Parser that processes VT sequences and updates a screen buffer
pub struct VtParser {
    parser: Parser,
    buffer: ScreenBuffer,
}

impl VtParser {
    /// Create a new parser with the given terminal size
    pub fn new(cols: u16, rows: u16) -> Self { todo!() }

    /// Create a parser from an existing buffer
    pub fn with_buffer(buffer: ScreenBuffer) -> Self { todo!() }

    /// Process bytes through the parser
    pub fn process(&mut self, bytes: &[u8]) { todo!() }

    /// Get a reference to the screen buffer
    pub fn buffer(&self) -> &ScreenBuffer { todo!() }

    /// Get a mutable reference to the screen buffer
    pub fn buffer_mut(&mut self) -> &mut ScreenBuffer { todo!() }

    /// Take ownership of the buffer
    pub fn into_buffer(self) -> ScreenBuffer { todo!() }

    /// Reset the parser and clear the buffer
    pub fn reset(&mut self) { todo!() }
}

/// Performer that applies VT sequences to the buffer
struct BufferPerformer<'a> {
    buffer: &'a mut ScreenBuffer,
}

impl<'a> Perform for BufferPerformer<'a> {
    fn print(&mut self, c: char) { todo!() }

    fn execute(&mut self, byte: u8) { todo!() }

    fn hook(&mut self, _params: &Params, _intermediates: &[u8], _ignore: bool, _action: char) { todo!() }

    fn put(&mut self, _byte: u8) { todo!() }

    fn unhook(&mut self) { todo!() }

    fn osc_dispatch(&mut self, _params: &[&[u8]], _bell_terminated: bool) { todo!() }

    fn csi_dispatch(
        &mut self,
        params: &Params,
        _intermediates: &[u8],
        _ignore: bool,
        action: char,
    ) { todo!() }

    fn esc_dispatch(&mut self, _intermediates: &[u8], _ignore: bool, byte: u8) { todo!() }
}

impl<'a> BufferPerformer<'a> {
    /// Handle SGR (Select Graphic Rendition) sequences
    fn handle_sgr(&mut self, params: &[u16]) { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::screen::parser::*;

    #[test]
    fn test_simple_text() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"Hello, World!");
        assert_eq!(parser.buffer().row_text(0), "Hello, World!");
    }


    #[test]
    fn test_cursor_movement() {
        let mut parser = VtParser::new(80, 24);
        // Move to row 5, col 10 (1-indexed in escape sequence)
        parser.process(b"\x1b[6;11H");
        assert_eq!(parser.buffer().cursor().row, 5);
        assert_eq!(parser.buffer().cursor().col, 10);
    }



    #[test]
    fn test_clear_line() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"Hello World");
        parser.process(b"\x1b[6G"); // Move to column 6
        parser.process(b"\x1b[K"); // Clear to end of line
        assert_eq!(parser.buffer().row_text(0), "Hello");
    }

    #[test]
    fn test_sgr_colors() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"\x1b[31mRed\x1b[0m"); // Red text, then reset
        let cell = parser.buffer().get_cell(0, 0).unwrap();
        assert_eq!(cell.fg, Color::Indexed(1));
        assert_eq!(cell.grapheme, "R");
    }

    #[test]
    fn test_sgr_bold() {
        let mut parser = VtParser::new(80, 24);
        parser.process(b"\x1b[1mBold\x1b[0m");
        let cell = parser.buffer().get_cell(0, 0).unwrap();
        assert!(cell.attrs.bold);
    }




    #[test]
    fn test_scroll_up() {
        let mut parser = VtParser::new(80, 3);
        parser.process(b"Line1\r\nLine2\r\nLine3");
        parser.process(b"\x1b[S"); // Scroll up 1
        assert_eq!(parser.buffer().row_text(0), "Line2");
        assert_eq!(parser.buffer().row_text(1), "Line3");
        assert_eq!(parser.buffer().row_text(2), "");
    }

}
