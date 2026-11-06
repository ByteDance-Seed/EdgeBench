//! Testing utilities for claude_rs.
//!
//! This module provides tools for testing Claude Code integrations,
//! including hook testing without requiring actual API calls.

mod hook_harness;

pub use hook_harness::HookTestHarness;
