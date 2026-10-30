//! JSON stream parser for Claude CLI output.
//!
//! The CLI outputs newline-delimited JSON messages. This parser handles
//! buffering incomplete lines and parsing complete JSON objects into
//! typed message structs.

use crate::message::Message;

/// Parser for newline-delimited JSON from the Claude CLI.
///
/// The parser maintains a buffer for incomplete lines and yields
/// complete messages as they become available.
#[derive(Debug, Default)]
pub struct Parser {
    buffer: String,
}

impl Parser {
    /// Create a new parser.
    pub fn new() -> Self {
        Self {
            buffer: String::new(),
        }
    }

    /// Feed data into the parser and return any complete messages.
    ///
    /// This method handles incomplete lines by buffering them until
    /// a complete line is available.
    pub fn feed(&mut self, data: &str) -> Vec<Message> {
        self.buffer.push_str(data);
        self.extract_messages()
    }

    /// Parse a single line (assumes line already ends with newline or is complete).
    pub fn parse_line(&mut self, line: &str) -> Vec<Message> {
        self.feed(line)
    }

    /// Extract all complete messages from the buffer.
    fn extract_messages(&mut self) -> Vec<Message> {
        let mut messages = Vec::new();

        while let Some(newline_pos) = self.buffer.find('\n') {
            let line: String = self.buffer.drain(..=newline_pos).collect();
            let trimmed = line.trim();

            if trimmed.is_empty() {
                continue;
            }

            // Try to parse as JSON
            match serde_json::from_str::<Message>(trimmed) {
                Ok(msg) => messages.push(msg),
                Err(e) => {
                    // Log parse errors in debug mode
                    tracing::debug!("Failed to parse message: {} - line: {}", e, trimmed);
                }
            }
        }

        messages
    }

    /// Get any remaining data in the buffer.
    pub fn remaining(&self) -> &str {
        &self.buffer
    }

    /// Clear the buffer.
    pub fn clear(&mut self) {
        self.buffer.clear();
    }
}

#[cfg(test)]
mod tests {
    use crate::cli::parser::*;

    #[test]
    fn test_parser_empty() {
        let mut parser = Parser::new();
        let messages = parser.feed("");
        assert!(messages.is_empty());
    }

    #[test]
    fn test_parser_incomplete_line() {
        let mut parser = Parser::new();
        let messages = parser.feed(r#"{"type": "system""#);
        assert!(messages.is_empty());
        assert_eq!(parser.remaining(), r#"{"type": "system""#);
    }

    #[test]
    fn test_parser_complete_line() {
        let mut parser = Parser::new();
        let json = r#"{"type": "system", "subtype": "init", "session_id": "abc123"}"#;
        let messages = parser.feed(&format!("{json}\n"));
        assert_eq!(messages.len(), 1);
        assert!(matches!(messages[0], Message::System(_)));
    }

    #[test]
    fn test_parser_multiple_lines() {
        let mut parser = Parser::new();
        let input = concat!(
            r#"{"type": "system", "subtype": "init", "session_id": "abc"}"#,
            "\n",
            r#"{"type": "result", "subtype": "success", "session_id": "abc"}"#,
            "\n"
        );
        let messages = parser.feed(input);
        assert_eq!(messages.len(), 2);
    }

    #[test]
    fn test_parser_partial_then_complete() {
        let mut parser = Parser::new();

        // First chunk - incomplete
        let messages1 = parser.feed(r#"{"type": "system", "#);
        assert!(messages1.is_empty());

        // Second chunk - completes the line
        let messages2 = parser.feed(r#""subtype": "init", "session_id": "abc"}"#);
        assert!(messages2.is_empty()); // Still no newline

        // Third chunk - adds newline
        let messages3 = parser.feed("\n");
        assert_eq!(messages3.len(), 1);
    }

    #[test]
    fn test_parser_ignores_empty_lines() {
        let mut parser = Parser::new();
        let messages = parser.feed("\n\n\n");
        assert!(messages.is_empty());
    }

    #[test]
    fn test_parser_handles_invalid_json() {
        let mut parser = Parser::new();
        let messages = parser.feed("not json\n");
        assert!(messages.is_empty()); // Invalid JSON is skipped
    }
}
