//! Error types for cas-pty

use thiserror::Error;

/// Result type alias
pub type Result<T> = std::result::Result<T, Error>;

/// PTY errors
#[derive(Error, Debug)]
pub enum Error {
    /// PTY operation failed
    #[error("PTY error: {0}")]
    Pty(String),

    /// IO error
    #[error("IO error: {0}")]
    Io(#[from] std::io::Error),
}

impl Error {
    pub fn pty(msg: impl Into<String>) -> Self { todo!() }
}
