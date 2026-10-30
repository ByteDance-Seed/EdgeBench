//! Traced Claude API wrapper
//!
//! Provides a drop-in replacement for `claude_rs::prompt()` that automatically
//! records traces when dev mode is enabled.
//!
//! # Usage
//!
//! ```rust,ignore
//! use cas::tracing::claude_wrapper::traced_prompt;
//!
//! // Instead of:
//! // let result = claude_rs::prompt(&prompt_text, options).await?;
//!
//! // Use:
//! let result = traced_prompt(&prompt_text, options, "consolidation").await?;
//! ```
//!
//! # Integration Status
//!
//! Fully integrated - all Claude API calls use this wrapper for tracing.

use claude_rs::{QueryOptions, message::ResultMessage};

use crate::tracing::TraceTimer;
use crate::tracing::dev_tracer::DevTracer;

/// Traced version of claude_rs::prompt()
///
/// Wraps the Claude API call and records a trace if dev mode is enabled.
/// The `caller` parameter identifies the calling context (e.g., "consolidation",
/// "extraction", "hook_summary").
pub async fn traced_prompt(
    prompt: &str,
    options: QueryOptions,
    caller: &str,
) -> Result<ResultMessage, claude_rs::Error> { todo!() }

/// Traced version with explicit model name
///
/// Use this when you know the model name and want it recorded accurately.
pub async fn traced_prompt_with_model(
    prompt: &str,
    options: QueryOptions,
    model: &str,
    caller: &str,
) -> Result<ResultMessage, claude_rs::Error> { todo!() }

#[cfg(test)]
mod tests {
    // Tests require ai-extraction feature
}
