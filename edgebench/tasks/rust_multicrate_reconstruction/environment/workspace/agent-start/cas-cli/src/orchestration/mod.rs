//! Orchestration module for multi-agent CAS sessions
//!
//! This module provides:
//! - Name generation for agents
//!
//! Note: Worker isolation is handled by the worktree module (`crate::worktree`).

pub mod names;

pub use names::generate_unique;
