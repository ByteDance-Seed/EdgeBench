//! Claude Code hook handling
//!
//! This module provides core hook types and context building logic that can be
//! used by both CLI and MCP interfaces for Claude Code integration.
//!
//! # Architecture
//!
//! The hooks module is designed to be storage-agnostic:
//! - Types (HookInput, HookOutput) are pure data structures
//! - Context building takes store references as parameters
//! - Configuration is abstracted via the HooksConfig trait
//!
//! # Usage
//!
//! ```rust,ignore
//! use cas_core::hooks::{HookInput, HookOutput, build_context_with_stores, ContextStores};
//! use cas_core::hooks::config::{DefaultHooksConfig, HooksConfig};
//!
//! // Create stores and config
//! let stores = ContextStores { ... };
//! let config = DefaultHooksConfig::new().with_mcp();
//!
//! // Build context
//! let input = HookInput { cwd: "/project".to_string(), ..Default::default() };
//! let (context, stats) = build_context_with_stores(&input, &stores, &config, 10, None)?;
//! ```
//!
//! # Supported Hooks
//!
//! - **SessionStart**: Injects relevant context at session start
//! - **SessionEnd**: Marks observations for extraction
//! - **Stop**: Generates session summary when agent finishes
//! - **SubagentStop**: Cleans up subagent leases when subagent finishes
//! - **PostToolUse**: Captures interesting tool interactions as observations
//! - **UserPromptSubmit**: Optional prompt capture

pub mod config;
pub mod context;
pub mod transcript;
pub mod types;

// Re-export main types
pub use config::{DefaultHooksConfig, HooksConfig, PlanModeConfig};
pub use context::{
    BasicContextScorer, ContextItem, ContextItemType, ContextQuery, ContextScorer, ContextStats,
    ContextStores, RuleMatchCache, SurfacedItemCallback, build_context_with_stores,
    build_plan_context_with_stores, estimate_tokens, rule_matches_path, token_display, truncate,
};
pub use transcript::{
    ContentBlock, TranscriptEntry, TranscriptMessage, TranscriptMetadata,
    check_promise_in_transcript, extract_transcript_metadata, get_last_assistant_text,
    get_recent_assistant_messages, parse_transcript_to_messages,
};
pub use types::{HookInput, HookOutput, HookSpecificOutput};
