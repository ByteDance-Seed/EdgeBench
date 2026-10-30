use crate::hooks::handlers::*;

pub fn handle_post_tool_use(
    input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }

/// Determine if an observation is significant enough to buffer
///
/// We only buffer observations that are likely to yield useful learnings:
/// - Errors (always capture - failures are learning opportunities)
/// - New file creation (architectural decisions)
/// - Large edits (significant changes)
/// - Commands with interesting output
pub fn should_buffer_observation(input: &HookInput, tool_name: &str) -> bool { todo!() }

pub fn record_rich_tool_trace(input: &HookInput, tool_name: &str) { todo!() }

/// Format an observation from tool usage
pub fn format_observation(
    input: &HookInput,
    skip_config: Option<&crate::config::PostToolUseSkipConfig>,
) -> String { todo!() }

/// Format a file write/edit observation
pub fn format_file_change(input: &HookInput) -> String { todo!() }

/// Format a bash command observation
pub fn format_bash_command(
    input: &HookInput,
    skip_config: Option<&crate::config::PostToolUseSkipConfig>,
) -> String { todo!() }

/// Format a file read observation
pub fn format_file_read(
    input: &HookInput,
    skip_config: Option<&crate::config::PostToolUseSkipConfig>,
) -> String { todo!() }

/// Check if a modified file is referenced by any active task or spec.
/// Returns a reminder string if matches are found, None otherwise.
/// Designed to be lightweight (< 50ms) — fails silently on any error.
fn check_ripple_consistency(cas_root: &Path, input: &HookInput) -> Option<String> { todo!() }

/// Check if a task's text fields reference a given file path.
fn task_references_file(task: &Task, relative: &str, short_path: Option<&str>) -> bool { todo!() }

/// Check if a spec's text fields reference a given file path.
fn spec_references_file(
    spec: &crate::types::Spec,
    relative: &str,
    short_path: Option<&str>,
) -> bool { todo!() }
