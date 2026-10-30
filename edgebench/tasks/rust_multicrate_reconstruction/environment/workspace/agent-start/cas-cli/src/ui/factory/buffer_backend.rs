//! Buffer-based ratatui backend for PTY forwarding
//!
//! This backend captures terminal output to a buffer instead of writing
//! directly to a terminal. The buffer contents can then be sent to clients.

use crossterm::{
    Command,
    cursor::{Hide, MoveTo, Show},
    style::{
        Attribute, Color as CrosstermColor, Print, SetAttribute, SetBackgroundColor,
        SetForegroundColor,
    },
    terminal::{Clear, ClearType},
};
use ratatui::backend::ClearType as RatatuiClearType;
use ratatui::backend::{Backend, WindowSize};
use ratatui::buffer::Cell;
use ratatui::layout::{Position, Size};
use ratatui::style::{Color, Modifier};
use std::io;

/// A ratatui backend that writes to a buffer
pub struct BufferBackend {
    /// Output buffer
    buffer: Vec<u8>,
    /// Terminal size
    width: u16,
    height: u16,
}

impl BufferBackend {
    /// Create a new buffer backend with the given size
    pub fn new(width: u16, height: u16) -> Self { todo!() }

    /// Take the buffered output, leaving an empty buffer
    pub fn take_buffer(&mut self) -> Vec<u8> { todo!() }

    /// Resize the backend
    pub fn resize(&mut self, width: u16, height: u16) { todo!() }

    /// Write a crossterm command to the buffer
    fn write_command(&mut self, cmd: impl Command) -> io::Result<()> { todo!() }

    /// Convert ratatui color to crossterm color
    fn to_crossterm_color(color: Color) -> CrosstermColor { todo!() }
}

impl Backend for BufferBackend {
    type Error = io::Error;

    fn draw<'a, I>(&mut self, content: I) -> Result<(), Self::Error>
    where
        I: Iterator<Item = (u16, u16, &'a Cell)>,
    { todo!() }

    fn hide_cursor(&mut self) -> Result<(), Self::Error> { todo!() }

    fn show_cursor(&mut self) -> Result<(), Self::Error> { todo!() }

    fn get_cursor_position(&mut self) -> Result<Position, Self::Error> { todo!() }

    fn set_cursor_position<P: Into<Position>>(&mut self, position: P) -> Result<(), Self::Error> { todo!() }

    fn clear(&mut self) -> Result<(), Self::Error> { todo!() }

    fn clear_region(&mut self, clear_type: RatatuiClearType) -> Result<(), Self::Error> { todo!() }

    fn size(&self) -> Result<Size, Self::Error> { todo!() }

    fn flush(&mut self) -> Result<(), Self::Error> { todo!() }

    fn window_size(&mut self) -> Result<WindowSize, Self::Error> { todo!() }
}
