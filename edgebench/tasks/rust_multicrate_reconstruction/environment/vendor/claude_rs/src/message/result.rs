//! Result message type.

use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;

/// Final result message.
///
/// Sent when a query completes, containing usage statistics,
/// cost information, and the final result.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ResultMessage {
    /// Result subtype (success, error_max_turns, etc.)
    pub subtype: Option<String>,

    /// Unique message identifier
    pub uuid: Option<String>,

    /// Session identifier
    pub session_id: Option<String>,

    /// Total duration in milliseconds
    pub duration_ms: Option<u64>,

    /// API call duration in milliseconds
    pub duration_api_ms: Option<u64>,

    /// Whether this is an error result
    pub is_error: Option<bool>,

    /// Number of conversation turns
    pub num_turns: Option<u32>,

    /// Final result text
    pub result: Option<String>,

    /// Total cost in USD
    pub total_cost_usd: Option<f64>,

    /// Token usage statistics
    pub usage: Option<Usage>,

    /// Per-model usage breakdown
    pub model_usage: Option<HashMap<String, ModelUsage>>,

    /// Permission denials that occurred
    pub permission_denials: Option<Vec<PermissionDenial>>,

    /// Structured output if requested
    pub structured_output: Option<Value>,

    /// Error details if any
    pub errors: Option<Vec<ErrorDetail>>,
}

impl ResultMessage {
    /// Check if this is a successful result.
    pub fn is_success(&self) -> bool {
        self.subtype.as_deref() == Some("success") && !self.is_error.unwrap_or(false)
    }

    /// Check if max turns was exceeded.
    pub fn is_max_turns(&self) -> bool {
        self.subtype.as_deref() == Some("error_max_turns")
    }

    /// Check if budget was exceeded.
    pub fn is_budget_exceeded(&self) -> bool {
        self.subtype.as_deref() == Some("error_max_budget_usd")
    }

    /// Check if there was an execution error.
    pub fn is_execution_error(&self) -> bool {
        self.subtype.as_deref() == Some("error_during_execution")
    }

    /// Get the result text or empty string.
    pub fn text(&self) -> &str {
        self.result.as_deref().unwrap_or("")
    }

    /// Get total input tokens.
    pub fn input_tokens(&self) -> u64 {
        self.usage.as_ref().map(|u| u.input_tokens).unwrap_or(0)
    }

    /// Get total output tokens.
    pub fn output_tokens(&self) -> u64 {
        self.usage.as_ref().map(|u| u.output_tokens).unwrap_or(0)
    }
}

/// Token usage statistics.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Usage {
    /// Input tokens used
    #[serde(default)]
    pub input_tokens: u64,

    /// Output tokens used
    #[serde(default)]
    pub output_tokens: u64,

    /// Cache creation input tokens
    #[serde(default)]
    pub cache_creation_input_tokens: u64,

    /// Cache read input tokens
    #[serde(default)]
    pub cache_read_input_tokens: u64,
}

/// Per-model usage breakdown.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ModelUsage {
    /// Input tokens for this model
    #[serde(default)]
    pub input_tokens: u64,

    /// Output tokens for this model
    #[serde(default)]
    pub output_tokens: u64,

    /// Cost for this model in USD
    pub cost_usd: Option<f64>,
}

/// Permission denial record.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PermissionDenial {
    /// Tool that was denied
    pub tool_name: Option<String>,

    /// Reason for denial
    pub reason: Option<String>,
}

/// Error detail.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ErrorDetail {
    /// Error message
    pub message: Option<String>,

    /// Error code
    pub code: Option<String>,

    /// Additional error data
    pub data: Option<Value>,
}
