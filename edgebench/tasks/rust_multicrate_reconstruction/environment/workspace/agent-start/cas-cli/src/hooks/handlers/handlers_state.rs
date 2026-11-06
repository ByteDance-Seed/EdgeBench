use crate::hooks::handlers::*;

pub(crate) fn detect_significant_activity(
    tool_name: &str,
    input: &HookInput,
) -> Option<(String, String)> { todo!() }

/// Extract entity ID for activity tracking
#[allow(dead_code)]
pub(crate) fn extract_activity_entity_id(tool_name: &str, input: &HookInput) -> Option<String> { todo!() }

/// Track a file access for session-aware context boosting
///
/// Records files being worked on so they can influence context selection.
/// Uses a simple JSON file in the CAS directory.
pub(crate) fn track_session_file(cas_root: &std::path::Path, file_path: &str) { todo!() }

/// Read recent files being worked on in this session
pub fn get_session_files(cas_root: &std::path::Path) -> Vec<String> { todo!() }

/// Determine the current agent ID in hook context.
///
/// Prefer the session_id (canonical agent ID) and fall back to PPID-based
/// computation when the session_id is missing.
pub(crate) fn current_agent_id(input: &HookInput) -> String { todo!() }

/// Clear session files (called on session end)
pub(crate) fn clear_session_files(cas_root: &std::path::Path) { todo!() }

/// Add an interruption note to a task (instead of resetting status)
///
/// Preserves the InProgress status but adds a system note indicating the work was interrupted.
/// This allows the next agent to see that work was attempted and decide whether to resume or reset.
pub(crate) fn add_interruption_note(task: &mut crate::types::Task, agent_id: &str) { todo!() }

/// Clean up agent leases for a session
///
/// Called during Stop/SubagentStop/SessionEnd to:
/// 1. Release all leases held by the agent
/// 2. Clear working epics tracking
/// 3. Add interruption note to tasks that were in progress (preserves status)
///
/// Note: Agents are registered with their session_id, so we use session_id
/// as the agent_id for lookup and cleanup.
/// PID → session mapping is handled by the daemon via socket events.
pub(crate) fn cleanup_agent_leases(
    cas_root: &std::path::Path,
    session_id: &str,
) -> Option<Vec<String>> { todo!() }

/// Cleanup orphaned tasks on session start
///
/// Finds in_progress tasks that have no active lease (from crashed/interrupted sessions)
/// and resets them to Open status so they can be worked on again.
pub(crate) fn cleanup_orphaned_tasks(cas_root: &std::path::Path) -> usize { todo!() }

/// Exit blockers preventing agent from stopping
#[derive(Debug, Default)]
pub struct ExitBlockers {
    /// Active child agents that must complete first
    pub active_children: Vec<Agent>,
    /// Tasks with active lease that must be closed
    pub claimed_tasks: Vec<Task>,
    /// Subtasks of claimed epics that must be closed
    pub epic_subtasks: Vec<Task>,
}

impl ExitBlockers {
    /// Check if there are any blockers preventing exit
    pub fn has_blockers(&self) -> bool { todo!() }

    /// Format a message describing the blockers
    pub fn format_message(&self) -> String { todo!() }
}

/// Check for blockers that would prevent agent from exiting
///
/// Returns exit blockers if there are open tasks/children that must be handled first.
///
/// Exit blocker logic:
/// 1. Check for active child agents (subagents still running)
/// 2. Check for claimed tasks that aren't closed (active leases)
/// 3. Check working_epics for open subtasks (epics the agent is working on)
///
/// Note: `session_id` is the canonical agent ID; PPID-based ID is a fallback
/// when the session ID is missing.
pub(crate) fn get_exit_blockers(
    cas_root: &std::path::Path,
    session_id: &str,
) -> Result<ExitBlockers, MemError> { todo!() }

/// Handle SubagentStop hook - minimal cleanup for subagent completion
///
/// Called when a Claude Code subagent (Task tool call) finishes.
///
/// IMPORTANT: The session_id in SubagentStop is the PARENT's session_id, not the
/// subagent's. We do NOT have the subagent's agent ID, and subagents spawned via
/// Task tool may not even be registered as CAS agents. Therefore, we do NOT
/// perform any agent cleanup here - that would incorrectly shut down the parent!
///
/// Only the parent's Stop hook should clean up agents and PID mappings.
pub fn handle_subagent_stop(
    _input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }

/// Handle SubagentStart hook - unjail for task-verifier
///
/// Called when a Claude Code subagent (Task tool call) is about to start.
/// If the subagent is task-verifier, clear pending_verification to release the jail.
pub fn handle_subagent_start(
    input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }
