//! CAS Hook E2E tests using real Claude API calls
//!
//! These tests verify that CAS hooks work correctly when integrated with Claude Code.
//! They require:
//! - Valid Claude API credentials (or local Claude instance)
//! - CAS CLI installed and accessible
//!
//! Run with: cargo test --test e2e_test hook_e2e -- --ignored --nocapture

#![cfg(feature = "claude_rs_e2e")]

use crate::fixtures::{HOOK_TEST_SESSION_ID, HookTestEnv};
use claude_rs::{Message, QueryOptions, prompt, session};
use std::path::PathBuf;

/// Get the CAS project root directory
fn cas_project_dir() -> PathBuf { todo!() }

// =============================================================================
// SessionStart Hook Tests
// =============================================================================

mod basic_sessions;
mod direct_hook;
mod exit_blockers;
mod jail_core;
mod jail_edge_cases;
mod mcp_integration;
