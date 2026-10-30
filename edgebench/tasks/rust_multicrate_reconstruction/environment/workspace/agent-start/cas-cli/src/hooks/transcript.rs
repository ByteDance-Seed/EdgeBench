//! Transcript parsing for Claude Code sessions
//!
//! This module re-exports types from `cas-core::hooks::transcript` for backward compatibility.
//! The types are defined in cas-core for cross-crate sharing.

// Re-export all types and functions from cas-core
pub use cas_core::hooks::transcript::{
    ContentBlock, TranscriptEntry, TranscriptMessage, TranscriptMetadata,
    check_promise_in_transcript, extract_transcript_metadata, get_last_assistant_text,
    get_recent_assistant_messages, parse_transcript_to_messages,
};
