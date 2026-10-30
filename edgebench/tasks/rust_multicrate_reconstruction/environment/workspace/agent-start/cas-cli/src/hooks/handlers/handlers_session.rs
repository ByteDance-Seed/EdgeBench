use crate::hooks::handlers::*;

pub fn handle_session_start(
    input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }

/// Estimate token count (rough approximation: ~4 chars per token)
pub(crate) fn estimate_tokens(s: &str) -> usize { todo!() }

/// Compute session outcome based on metrics and friction events
///
/// Outcome determination priority:
/// Handle SessionEnd hook - generate session summary and mark for extraction
pub fn handle_session_end(
    input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }

/// Generate session summary using AI (synchronous wrapper with timeout)
pub(crate) fn generate_session_summary_sync(
    observations: &[&Entry],
) -> Result<SessionSummary, MemError> { todo!() }

/// Generate session summary using AI
async fn generate_session_summary_async(
    observations: &[&Entry],
) -> Result<SessionSummary, MemError> { todo!() }

/// Generate session title (synchronous wrapper with timeout)
pub fn generate_session_title_sync(observations: &[&Entry]) -> Result<String, MemError> { todo!() }

/// Generate a concise session title using AI
async fn generate_session_title_async(observations: &[&Entry]) -> Result<String, MemError> { todo!() }

/// Extract learnings from transcript (synchronous wrapper with timeout)
pub(crate) fn extract_learnings_sync(
    transcript_path: &str,
    file_paths: &[String],
) -> Result<Vec<ExtractedLearning>, MemError> { todo!() }

/// Extract learnings from transcript using AI
///
/// Reads the transcript, sends to Haiku to identify project conventions
/// that the user taught Claude during the session.
async fn extract_learnings_async(
    transcript_path: &str,
    file_paths: &[String],
) -> Result<Vec<ExtractedLearning>, MemError> { todo!() }
