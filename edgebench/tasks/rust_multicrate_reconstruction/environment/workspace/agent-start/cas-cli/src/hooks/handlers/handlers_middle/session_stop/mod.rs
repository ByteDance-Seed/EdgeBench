use crate::hooks::handlers::*;

pub fn add_loop_completion_note(
    cas_root: &std::path::Path,
    task_id: &str,
    loop_state: &crate::types::Loop,
    reason: &str,
) { todo!() }

/// Handle loop iteration - blocks exit and feeds prompt back
///
/// This is the core of the iteration loop functionality. When an active loop
/// exists for the session, this function:
/// 1. Checks if the completion promise was found in the transcript
/// 2. Checks if max iterations were reached
/// 3. If neither, blocks exit and injects the prompt for another iteration
pub fn handle_loop_iteration(
    input: &HookInput,
    cas_root: &std::path::Path,
    loop_store: std::sync::Arc<dyn crate::store::LoopStore>,
    active_loop: &mut crate::types::Loop,
) -> Result<HookOutput, MemError> { todo!() }

/// Default limit for learnings shown in review context
const LEARNING_REVIEW_LIMIT: usize = 20;

/// Build context for learning review if there are unreviewed learnings above threshold
///
/// Returns Some(context) if learning review should be triggered, None otherwise.
/// The context instructs the agent to spawn a learning-reviewer subagent.
/// Returns error context if store operations fail (fail explicitly, no silent skip).
pub fn build_learning_review_context(store: &dyn Store, config: &Config) -> Option<String> { todo!() }

/// Build context for rule review when draft rules exceed threshold
///
/// Returns Some(context) if rule review should be triggered, None otherwise.
/// The context instructs the agent to spawn a rule-reviewer subagent.
/// Returns error context if store operations fail (fail explicitly, no silent skip).
pub fn build_rule_review_context(rule_store: &dyn RuleStore, config: &Config) -> Option<String> { todo!() }

/// Build context for duplicate detection when entries exceed threshold
///
/// Returns Some(context) if duplicate detection should be triggered, None otherwise.
/// The context instructs the agent to spawn a duplicate-detector subagent.
/// Returns error context if store operations fail (fail explicitly, no silent skip).
pub fn build_duplicate_detection_context(store: &dyn Store, config: &Config) -> Option<String> { todo!() }

/// Build context for session summary generation
///
/// Returns Some(context) if generate_summary is enabled and no summary exists yet.
/// The context instructs the agent to spawn a session-summarizer subagent.
/// Returns an error context if store operations fail (fail explicitly, no silent skip).
pub fn build_session_summary_context(
    store: &dyn Store,
    config: &Config,
    session_id: &str,
) -> Option<String> { todo!() }

/// Handle Stop hook - generate session summary when agent finishes
///
/// This is triggered when the agent explicitly finishes its task,
/// making it ideal for generating a comprehensive session summary.
///
/// Implements "compaction" pattern from context engineering:
/// - Summarizes session activities
/// - Preserves architectural decisions
/// - Captures unresolved issues for future sessions
mod stop_flow;
mod synthesis;

pub use stop_flow::handle_stop;
pub use synthesis::synthesize_buffered_observations;
