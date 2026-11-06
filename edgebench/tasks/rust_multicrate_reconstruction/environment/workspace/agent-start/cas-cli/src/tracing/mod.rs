//! Tracing for AI operations
//!
//! Traces context injection decisions, search queries, rule applications,
//! extraction quality, command execution, Claude API calls, and store operations.
//! Inspired by LangSmith patterns.
//!
//! # Dev Mode Tracing
//!
//! When `dev.dev_mode` is enabled in config, comprehensive tracing captures:
//! - CLI command executions with args, duration, and success/error
//! - Claude API calls with full prompts and responses
//! - Store operations (add, update, delete, get)
//! - Hook events with input/output context
//!
//! # Usage
//!
//! ```rust,ignore
//! use cas::tracing::{DevTracer, TraceEventType};
//!
//! // Initialize at CLI startup (in main.rs or cli/mod.rs)
//! DevTracer::init_global(&cas_root)?;
//!
//! // Record a trace event anywhere
//! if let Some(tracer) = DevTracer::get() {
//!     tracer.record_command("add", &["content"], 150, true, None)?;
//! }
//! ```

mod builder;
pub mod claude_wrapper;
pub mod dev_tracer;
mod store;
mod tool_trace;
mod types;

pub use builder::{TraceBuilder, TraceTimer, generate_trace_id};
pub use dev_tracer::DevTracer;
pub use store::TraceStore;
pub use tool_trace::ToolTrace;
pub use types::{
    BufferedObservation, ClaudeApiTrace, CommandExecutionTrace, ContextInjectionTrace,
    ExtractionTrace, HookEventTrace, RuleApplicationTrace, SkillInvocationTrace,
    StoreOperationTrace, SurfacedItem, TraceEvent, TraceEventType, TraceStats,
};

#[cfg(test)]
mod tests;
