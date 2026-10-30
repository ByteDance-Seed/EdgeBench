//! Data loading for the director panel
//!
//! This module re-exports DirectorData and related types from cas-factory.
//! The actual implementation is in the cas-factory crate for sharing
//! between TUI and desktop applications.

// Re-export all types from cas-factory
pub use cas_factory::{AgentSummary, DirectorData, TaskSummary};
