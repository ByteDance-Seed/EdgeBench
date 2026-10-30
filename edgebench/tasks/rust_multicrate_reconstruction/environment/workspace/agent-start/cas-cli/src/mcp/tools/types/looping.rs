use rmcp::schemars::JsonSchema;
use serde::Deserialize;

#[derive(Debug, Deserialize, JsonSchema)]
pub struct LoopStartRequest {
    /// The prompt to repeat each iteration
    #[schemars(description = "The prompt/task to repeat each iteration until completion")]
    pub prompt: String,

    /// Completion promise text
    #[schemars(
        description = "Text that signals completion when wrapped in <promise>TEXT</promise>"
    )]
    #[serde(default)]
    pub completion_promise: Option<String>,

    /// Maximum iterations (0 = unlimited)
    #[schemars(description = "Maximum iterations before stopping (0 = unlimited, default: 0)")]
    #[serde(default)]
    pub max_iterations: u32,

    /// Optional task ID to link for progress tracking
    #[schemars(
        description = "Optional task ID to link - iteration progress will be added as notes"
    )]
    #[serde(default)]
    pub task_id: Option<String>,

    /// Session ID (required for loop to work)
    #[schemars(description = "Session ID to attach the loop to (from hook context)")]
    pub session_id: String,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct LoopCancelRequest {
    /// Session ID to cancel loop for
    #[schemars(description = "Session ID to cancel the active loop for")]
    pub session_id: String,

    /// Reason for cancellation
    #[schemars(description = "Reason for cancelling the loop")]
    #[serde(default)]
    pub reason: Option<String>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct LoopStatusRequest {
    /// Session ID to check loop status for
    #[schemars(description = "Session ID to check loop status for")]
    pub session_id: String,
}
