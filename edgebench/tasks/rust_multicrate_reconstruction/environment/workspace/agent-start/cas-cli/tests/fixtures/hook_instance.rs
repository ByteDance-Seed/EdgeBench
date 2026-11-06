//! Hook test environment fixture - extends CasInstance with hook-specific setup
//!
//! Provides a properly initialized CAS environment for hook E2E tests,
//! including database operations for jail state and MCP testing.
#![allow(dead_code)]

use super::cas_instance::{CasInstance, new_cas_instance};
use rusqlite::{Connection, params};
use std::env;
use std::path::{Path, PathBuf};

/// Test environment with CAS initialized and hook testing capabilities
///
/// Composes CasInstance with hook-specific methods for:
/// - Jail state management (pending_verification, pending_worktree_merge)
/// - MCP testing (working_epics, task queries)
/// - File creation for test scenarios
pub struct HookTestEnv {
    pub cas: CasInstance,
}

/// Session ID used for hook simulations in tests
pub const HOOK_TEST_SESSION_ID: &str = "550e8400-e29b-41d4-a716-446655440000";

fn cas_bin() -> PathBuf { todo!() }

impl HookTestEnv {
    /// Create new environment (runs cas init, creates test files)
    pub fn new() -> Self { todo!() }

    /// Get the project directory path
    pub fn dir(&self) -> &Path { todo!() }

    /// Get the database path
    pub fn db_path(&self) -> PathBuf { todo!() }

    /// Get the MCP config path
    pub fn mcp_config_path(&self) -> PathBuf { todo!() }

    /// Run a CAS command in this environment
    pub fn cas(&self, args: &[&str]) -> std::process::Output { todo!() }

    /// Create a task and return its ID (starts immediately)
    pub fn create_task(&self, title: &str) -> String { todo!() }

    /// Close a task
    pub fn close_task(&self, task_id: &str) { todo!() }

    /// Create a file in the test environment
    pub fn create_file(&self, name: &str, content: &str) { todo!() }

    // =========================================================================
    // Jail state methods (direct sqlite3 operations)
    // =========================================================================

    /// Set pending_verification on a task
    pub fn set_pending_verification(&self, task_id: &str, value: bool) { todo!() }

    /// Set pending_worktree_merge on a task
    ///
    /// Uses rusqlite to update the database directly (avoids sqlite3 CLI WAL issues).
    pub fn set_pending_worktree_merge(&self, task_id: &str, value: bool) { todo!() }

    /// Enable worktrees in config (required for worktree merge jail to work)
    pub fn enable_worktrees(&self) { todo!() }

    /// Disable verification in config (useful for MCP integration tests
    /// that close tasks without wanting the verification jail flow)
    pub fn disable_verification(&self) { todo!() }

    /// Append content to config.toml (creates if needed)
    fn append_config(&self, content: &str) { todo!() }

    /// Query a task's jail state from database
    ///
    /// NOTE: Due to SQLite WAL mode on macOS, sqlite3 CLI cannot reliably read
    /// data that CAS CLI has written. This method returns (false, false) if it
    /// can't read the task. The tests using this are ignored.
    pub fn get_task_jail_state(&self, task_id: &str) -> (bool, bool) { todo!() }

    /// Count tasks with pending_verification=true
    pub fn count_jailed_tasks(&self) -> usize { todo!() }

    /// Count tasks with pending_worktree_merge=true
    pub fn count_worktree_jailed_tasks(&self) -> usize { todo!() }

    /// Get total task count
    pub fn count_tasks(&self) -> usize { todo!() }

    // =========================================================================
    // MCP-specific methods
    // =========================================================================

    /// Query working_epics table directly (via rusqlite to avoid WAL issues)
    pub fn get_working_epics(&self) -> Vec<(String, String)> { todo!() }

    /// Get all tasks from database (via rusqlite to avoid WAL issues)
    pub fn get_tasks(&self) -> Vec<(String, String, String)> { todo!() }

    // =========================================================================
    // Hook simulation methods (for true E2E testing)
    // =========================================================================

    /// Run PreToolUse hook with given tool name and input, return (success, output)
    pub fn run_pre_tool_use(
        &self,
        tool_name: &str,
        tool_input: serde_json::Value,
    ) -> (bool, String) { todo!() }

    /// Run PreToolUse for Task(task-verifier) - simulates spawning task-verifier
    pub fn run_pre_tool_use_task_verifier(&self) -> (bool, String) { todo!() }

    /// Run PreToolUse for a Read operation
    pub fn run_pre_tool_use_read(&self, file_path: &str) -> (bool, String) { todo!() }

    /// Run SubagentStart hook for the task-verifier
    pub fn run_subagent_start_task_verifier(&self) -> (bool, String) { todo!() }

    /// Run SubagentStart hook with given subagent_type
    pub fn run_subagent_start(&self, subagent_type: &str) -> (bool, String) { todo!() }

    /// Set task assignee
    pub fn set_task_assignee(&self, task_id: &str, assignee: &str) { todo!() }

    /// Get pending_verification flag for a task
    pub fn get_pending_verification(&self, task_id: &str) -> bool { todo!() }

    /// Check if hook output indicates denial (blocked by jail)
    pub fn is_hook_denied(&self, hook_output: &str) -> bool { todo!() }

    /// Check if verifier unjail marker file exists
    pub fn marker_file_exists(&self) -> bool { todo!() }

    /// Remove verifier unjail marker file (for cleanup)
    pub fn remove_marker_file(&self) { todo!() }

    /// Register an agent in the database
    pub fn register_agent(&self, agent_id: &str, name: &str, agent_type: &str) { todo!() }

    /// Register an agent with a specific role (supervisor, worker, standard)
    pub fn register_agent_with_role(
        &self,
        agent_id: &str,
        name: &str,
        role: &str,
    ) { todo!() }

    /// Add working epic entry (agent_id <-> epic_id association)
    pub fn add_working_epic(&self, agent_id: &str, epic_id: &str) { todo!() }

    /// Add a dependency between tasks
    ///
    /// Common dep_type values (kebab-case, matching serde serialization):
    /// - "blocks" - Hard blocker
    /// - "related" - Soft link
    /// - "parent-child" - Epic/subtask (from=subtask, to=epic)
    pub fn add_dependency(&self, from_id: &str, to_id: &str, dep_type: &str) { todo!() }

    /// Run a Stop hook, return (success, output)
    pub fn run_stop_hook(&self) -> (bool, String) { todo!() }
}
