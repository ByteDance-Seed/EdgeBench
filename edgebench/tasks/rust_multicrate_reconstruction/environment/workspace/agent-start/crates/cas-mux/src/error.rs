//! Error types for cas-mux

use thiserror::Error;

/// Result type alias
pub type Result<T> = std::result::Result<T, Error>;

/// Multiplexer errors
#[derive(Error, Debug)]
pub enum Error {
    /// PTY operation failed
    #[error("PTY error: {0}")]
    Pty(String),

    /// Pane not found
    #[error("Pane not found: {0}")]
    PaneNotFound(String),

    /// IO error
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),

    /// Terminal error
    #[error("Terminal error: {0}")]
    Terminal(String),

    /// Channel send error
    #[error("Channel closed")]
    ChannelClosed,

    /// Recording error
    #[error("Recording error: {0}")]
    Recording(String),
}

impl From<cas_pty::Error> for Error {
    fn from(err: cas_pty::Error) -> Self { todo!() }
}

impl Error {
    pub fn pty(msg: impl Into<String>) -> Self { todo!() }

    pub fn terminal(msg: impl Into<String>) -> Self { todo!() }

    pub fn pane_not_found(id: impl Into<String>) -> Self { todo!() }

    pub fn recording(msg: impl Into<String>) -> Self { todo!() }
}
