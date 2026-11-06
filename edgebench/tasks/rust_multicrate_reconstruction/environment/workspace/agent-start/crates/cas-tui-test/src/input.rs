//! Input DSL - Builder for composing input sequences
//!
//! Provides an ergonomic way to build sequences of terminal input
//! including text, key presses, and delays.

use crate::pty_runner::{Key, PtyRunner, PtyRunnerError};
use std::time::Duration;

/// A single input action in a sequence
#[derive(Debug, Clone)]
pub enum InputAction {
    /// Send text string
    Text(String),
    /// Send a special key
    Key(Key),
    /// Send raw bytes
    Bytes(Vec<u8>),
    /// Wait for a duration
    Wait(Duration),
}

/// Builder for input sequences
#[derive(Debug, Clone, Default)]
pub struct InputSequence {
    actions: Vec<InputAction>,
}

impl InputSequence {
    /// Create a new empty input sequence
    pub fn new() -> Self { todo!() }

    /// Add text to the sequence
    pub fn text(mut self, s: impl Into<String>) -> Self { todo!() }

    /// Add a line of text followed by Enter
    pub fn line(mut self, s: impl Into<String>) -> Self { todo!() }

    /// Add a key press
    pub fn key(mut self, key: Key) -> Self { todo!() }

    /// Add Enter key
    pub fn enter(self) -> Self { todo!() }

    /// Add Tab key
    pub fn tab(self) -> Self { todo!() }

    /// Add Escape key
    pub fn escape(self) -> Self { todo!() }

    /// Add Ctrl+C
    pub fn ctrl_c(self) -> Self { todo!() }

    /// Add Ctrl+D
    pub fn ctrl_d(self) -> Self { todo!() }

    /// Add Up arrow
    pub fn up(self) -> Self { todo!() }

    /// Add Down arrow
    pub fn down(self) -> Self { todo!() }

    /// Add Left arrow
    pub fn left(self) -> Self { todo!() }

    /// Add Right arrow
    pub fn right(self) -> Self { todo!() }

    /// Add raw bytes
    pub fn bytes(mut self, b: impl Into<Vec<u8>>) -> Self { todo!() }

    /// Add a wait/delay
    pub fn wait(mut self, duration: Duration) -> Self { todo!() }

    /// Add a wait in milliseconds
    pub fn wait_ms(self, ms: u64) -> Self { todo!() }

    /// Get the actions in this sequence
    pub fn actions(&self) -> &[InputAction] { todo!() }

    /// Execute this input sequence on a PTY runner
    pub fn execute(&self, runner: &mut PtyRunner) -> Result<(), PtyRunnerError> { todo!() }
}

/// Convenience function to create an input sequence
pub fn input() -> InputSequence { todo!() }

#[cfg(test)]
mod tests {
    use crate::input::*;


    #[test]
    fn test_line_helper() {
        let seq = input().line("command");
        assert_eq!(seq.actions().len(), 2);
        assert!(matches!(&seq.actions()[0], InputAction::Text(s) if s == "command"));
        assert!(matches!(&seq.actions()[1], InputAction::Key(Key::Enter)));
    }

    #[test]
    fn test_arrow_keys() {
        let seq = input().up().down().left().right();
        assert_eq!(seq.actions().len(), 4);
        assert!(matches!(&seq.actions()[0], InputAction::Key(Key::Up)));
        assert!(matches!(&seq.actions()[1], InputAction::Key(Key::Down)));
        assert!(matches!(&seq.actions()[2], InputAction::Key(Key::Left)));
        assert!(matches!(&seq.actions()[3], InputAction::Key(Key::Right)));
    }

}
