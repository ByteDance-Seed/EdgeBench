//! Managed session for multi-turn conversations.

use crate::error::{Error, Result};
use crate::message::{Message, ResultMessage};
use crate::options::QueryOptions;
use crate::query::{Query, start_query};

use std::time::Duration;
use tokio::time::timeout;

/// A managed session for multi-turn conversations.
///
/// Sessions provide a higher-level API than raw queries, with
/// automatic message accumulation and convenient await helpers.
pub struct Session {
    query: Query,
    responses: Vec<Message>,
}

impl Session {
    /// Create a new session.
    pub fn new(options: QueryOptions) -> Result<Self> {
        let query = start_query(options)?;
        Ok(Self {
            query,
            responses: Vec::new(),
        })
    }

    /// Resume an existing session.
    pub fn resume(session_id: &str, options: QueryOptions) -> Result<Self> {
        let query = crate::query::resume_session(session_id, options)?;
        Ok(Self {
            query,
            responses: Vec::new(),
        })
    }

    /// Send a message to the session.
    pub async fn send(&mut self, message: &str) -> Result<()> {
        self.query.send_message(message).await
    }

    /// Signal end of input.
    pub fn finish(&mut self) -> Result<()> {
        self.query.finish_input()
    }

    /// Interrupt the session.
    pub fn interrupt(&mut self) -> Result<()> {
        self.query.interrupt()
    }

    /// Wait for the next response message.
    ///
    /// Returns the next message of any type.
    pub async fn await_response(&mut self, timeout_duration: Option<Duration>) -> Result<Message> {
        let timeout_duration = timeout_duration.unwrap_or(Duration::from_secs(300));

        match timeout(timeout_duration, self.query.recv()).await {
            Ok(Some(result)) => {
                let msg = result?;
                self.responses.push(msg.clone());
                Ok(msg)
            }
            Ok(None) => Err(Error::StreamEnded),
            Err(_) => Err(Error::Timeout("Waiting for response".to_string())),
        }
    }

    /// Wait for the final result message.
    ///
    /// Skips intermediate messages and returns only when a Result message is received.
    pub async fn await_result(
        &mut self,
        timeout_duration: Option<Duration>,
    ) -> Result<ResultMessage> {
        let timeout_duration = timeout_duration.unwrap_or(Duration::from_secs(300));
        let deadline = tokio::time::Instant::now() + timeout_duration;

        loop {
            let remaining = deadline.saturating_duration_since(tokio::time::Instant::now());
            if remaining.is_zero() {
                return Err(Error::Timeout("Waiting for result".to_string()));
            }

            match timeout(remaining, self.query.recv()).await {
                Ok(Some(result)) => {
                    let msg = result?;
                    self.responses.push(msg.clone());

                    if let Message::Result(r) = msg {
                        return Ok(r);
                    }
                }
                Ok(None) => return Err(Error::StreamEnded),
                Err(_) => return Err(Error::Timeout("Waiting for result".to_string())),
            }
        }
    }

    /// Get all accumulated responses.
    pub fn responses(&self) -> &[Message] {
        &self.responses
    }

    /// Get the session ID from the first message.
    pub fn session_id(&self) -> Option<&str> {
        self.responses.first().and_then(|m| m.session_id())
    }

    /// Close the session.
    pub fn close(self) -> Result<()> {
        self.query.close()
    }
}
