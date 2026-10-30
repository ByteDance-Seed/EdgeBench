//! Loop state type definitions
//!
//! Loops implement iterative execution where Claude repeatedly works on a task
//! until completion is detected or max iterations reached.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;

/// Status of a loop
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum LoopStatus {
    /// Loop is active and running
    #[default]
    Active,
    /// Loop completed successfully (promise detected)
    Completed,
    /// Loop cancelled by user
    Cancelled,
    /// Loop hit max iterations
    MaxIterations,
    /// Loop failed with error
    Failed,
}

impl fmt::Display for LoopStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for LoopStatus {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// An iteration loop for repeated task execution
///
/// Loops intercept session exits and feed the same prompt back
/// to Claude until completion is detected or max iterations reached.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Loop {
    /// Unique identifier (e.g., loop-a1b2)
    pub id: String,

    /// Session ID this loop is attached to
    pub session_id: String,

    /// The prompt to repeat each iteration
    pub prompt: String,

    /// Optional completion promise text (e.g., "DONE")
    /// When Claude outputs <promise>DONE</promise>, loop stops
    #[serde(default)]
    pub completion_promise: Option<String>,

    /// Current iteration count (starts at 1)
    pub iteration: u32,

    /// Maximum iterations (0 = unlimited)
    pub max_iterations: u32,

    /// Loop status
    #[serde(default)]
    pub status: LoopStatus,

    /// Optional linked task ID for tracking
    #[serde(default)]
    pub task_id: Option<String>,

    /// When the loop started
    pub started_at: DateTime<Utc>,

    /// When the loop ended (if ended)
    #[serde(default)]
    pub ended_at: Option<DateTime<Utc>>,

    /// Reason for ending (if ended)
    #[serde(default)]
    pub end_reason: Option<String>,

    /// Working directory
    pub cwd: String,
}

impl Loop {
    /// Create a new loop
    pub fn new(id: String, session_id: String, prompt: String, cwd: String) -> Self { todo!() }

    /// Create a new loop with options
    pub fn with_options(
        id: String,
        session_id: String,
        prompt: String,
        cwd: String,
        completion_promise: Option<String>,
        max_iterations: u32,
        task_id: Option<String>,
    ) -> Self { todo!() }

    /// Check if the loop is active
    pub fn is_active(&self) -> bool { todo!() }

    /// Check if max iterations reached
    pub fn is_max_reached(&self) -> bool { todo!() }

    /// Increment iteration counter
    pub fn increment(&mut self) { todo!() }

    /// Complete the loop with a reason
    pub fn complete(&mut self, reason: &str) { todo!() }

    /// Cancel the loop
    pub fn cancel(&mut self, reason: Option<&str>) { todo!() }

    /// Mark loop as failed
    pub fn fail(&mut self, reason: &str) { todo!() }

    /// Mark loop as hitting max iterations
    pub fn max_iterations_reached(&mut self) { todo!() }

    /// Check if output contains the completion promise
    pub fn check_completion(&self, output: &str) -> bool { todo!() }

    /// Get duration in seconds (if ended)
    pub fn duration_secs(&self) -> Option<i64> { todo!() }
}

impl Default for Loop {
    fn default() -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::loop_state::*;

    #[test]
    fn test_loop_new() {
        let loop_state = Loop::new(
            "loop-a1b2".to_string(),
            "session-123".to_string(),
            "Build a todo app".to_string(),
            "/project".to_string(),
        );

        assert_eq!(loop_state.id, "loop-a1b2");
        assert_eq!(loop_state.iteration, 1);
        assert!(loop_state.is_active());
        assert!(!loop_state.is_max_reached());
    }

    #[test]
    fn test_loop_with_options() {
        let loop_state = Loop::with_options(
            "loop-a1b2".to_string(),
            "session-123".to_string(),
            "Build a todo app".to_string(),
            "/project".to_string(),
            Some("DONE".to_string()),
            10,
            Some("cas-1234".to_string()),
        );

        assert_eq!(loop_state.max_iterations, 10);
        assert_eq!(loop_state.completion_promise, Some("DONE".to_string()));
        assert_eq!(loop_state.task_id, Some("cas-1234".to_string()));
    }

    #[test]
    fn test_check_completion() {
        let loop_state = Loop::with_options(
            "loop-a1b2".to_string(),
            "session-123".to_string(),
            "Build a todo app".to_string(),
            "/project".to_string(),
            Some("DONE".to_string()),
            0,
            None,
        );

        assert!(loop_state.check_completion("The task is <promise>DONE</promise>"));
        assert!(!loop_state.check_completion("The task is done"));
        assert!(!loop_state.check_completion("<promise>NOT_DONE</promise>"));
    }

    #[test]
    fn test_max_iterations() {
        let mut loop_state = Loop::with_options(
            "loop-a1b2".to_string(),
            "session-123".to_string(),
            "Build a todo app".to_string(),
            "/project".to_string(),
            None,
            3,
            None,
        );

        assert!(!loop_state.is_max_reached());
        loop_state.increment();
        assert!(!loop_state.is_max_reached());
        loop_state.increment();
        assert!(loop_state.is_max_reached()); // iteration=3, max=3
    }



    #[test]
    fn test_cancel_loop() {
        let mut loop_state = Loop::new(
            "loop-a1b2".to_string(),
            "session-123".to_string(),
            "prompt".to_string(),
            "/project".to_string(),
        );

        loop_state.cancel(Some("User requested"));
        assert_eq!(loop_state.status, LoopStatus::Cancelled);
        assert!(loop_state.ended_at.is_some());
    }

}
