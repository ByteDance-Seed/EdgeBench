//! Error types for claude_rs.

use thiserror::Error;

/// Result type alias using [`Error`].
pub type Result<T> = std::result::Result<T, Error>;

/// Errors that can occur when using claude_rs.
#[derive(Error, Debug)]
pub enum Error {
    /// Failed to spawn or communicate with the Claude CLI process.
    #[error("CLI error: {0}")]
    Cli(String),

    /// Failed to parse JSON from CLI output.
    #[error("Parse error: {0}")]
    Parse(#[from] serde_json::Error),

    /// I/O error during CLI communication.
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    /// The Claude CLI executable was not found.
    #[error("Claude CLI not found. Install it or set the executable path.")]
    ExecutableNotFound,

    /// Tool validation failed.
    #[error("Tool validation error: {0}")]
    ToolValidation(String),

    /// Tool execution failed.
    #[error("Tool execution error: {0}")]
    ToolExecution(String),

    /// Hook execution failed.
    #[error("Hook error: {0}")]
    Hook(String),

    /// Query was interrupted.
    #[error("Query interrupted")]
    Interrupted,

    /// Query timed out.
    #[error("Timeout: {0}")]
    Timeout(String),

    /// Maximum turns exceeded.
    #[error("Max turns exceeded")]
    MaxTurnsExceeded,

    /// Budget exceeded.
    #[error("Budget exceeded: ${0:.2} USD")]
    BudgetExceeded(f64),

    /// Permission denied.
    #[error("Permission denied: {0}")]
    PermissionDenied(String),

    /// MCP protocol error.
    #[error("MCP error: {0}")]
    Mcp(String),

    /// Session not found.
    #[error("Session not found: {0}")]
    SessionNotFound(String),

    /// Stream ended unexpectedly.
    #[error("Stream ended unexpectedly")]
    StreamEnded,

    /// Invalid option or configuration.
    #[error("Invalid option: {0}")]
    InvalidOption(String),

    /// Query returned an error result.
    #[error("Query error: {0}")]
    QueryError(String),

    /// Runtime control error.
    #[error("Runtime error: {0}")]
    Runtime(String),
}

impl Error {
    /// Create a CLI error.
    pub fn cli(msg: impl Into<String>) -> Self {
        Error::Cli(msg.into())
    }

    /// Create a tool validation error.
    pub fn tool_validation(msg: impl Into<String>) -> Self {
        Error::ToolValidation(msg.into())
    }

    /// Create a tool execution error.
    pub fn tool_execution(msg: impl Into<String>) -> Self {
        Error::ToolExecution(msg.into())
    }

    /// Create a hook error.
    pub fn hook(msg: impl Into<String>) -> Self {
        Error::Hook(msg.into())
    }

    /// Create an MCP error.
    pub fn mcp(msg: impl Into<String>) -> Self {
        Error::Mcp(msg.into())
    }

    /// Create a permission denied error.
    pub fn permission_denied(msg: impl Into<String>) -> Self {
        Error::PermissionDenied(msg.into())
    }

    /// Create an invalid option error.
    pub fn invalid_option(msg: impl Into<String>) -> Self {
        Error::InvalidOption(msg.into())
    }

    /// Create a query error.
    pub fn query_error(msg: impl Into<String>) -> Self {
        Error::QueryError(msg.into())
    }
}
