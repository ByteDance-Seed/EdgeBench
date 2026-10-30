//! Claude Code hook input/output types
//!
//! This module re-exports types from `cas-core::hooks::types` for backward compatibility.
//! The types are defined in cas-core for cross-crate sharing.

// Re-export all types from cas-core
pub use cas_core::hooks::types::{HookInput, HookOutput, HookSpecificOutput};
