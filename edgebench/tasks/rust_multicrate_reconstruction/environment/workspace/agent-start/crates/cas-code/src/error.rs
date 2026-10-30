//! Error types for code analysis.

use thiserror::Error;

/// Errors that can occur during code analysis.
#[derive(Error, Debug)]
pub enum CodeError {
    /// Parse error (invalid input)
    #[error("parse error: {0}")]
    Parse(String),

    /// Tree-sitter parsing failed
    #[error("tree-sitter error: {0}")]
    TreeSitter(String),

    /// File I/O error
    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    /// Language not supported
    #[error("unsupported language: {0}")]
    UnsupportedLanguage(String),

    /// Symbol not found
    #[error("symbol not found: {0}")]
    NotFound(String),

    /// Invalid configuration
    #[error("config error: {0}")]
    Config(String),
}

/// Result type for code operations.
pub type Result<T> = std::result::Result<T, CodeError>;
