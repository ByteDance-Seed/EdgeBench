use crate::hooks::handlers::*;

pub fn synthesize_with_ai_sync(
    cas_root: &std::path::Path,
    buffered: &[crate::tracing::BufferedObservation],
    session_id: &str,
) -> Result<usize, MemError> { todo!() }

/// AI-powered buffer synthesis
///
/// Uses Claude to analyze buffered observations and extract meaningful learnings.
/// More nuanced than rule-based synthesis but requires API call.
async fn synthesize_with_ai_async(
    cas_root: &std::path::Path,
    buffered: &[crate::tracing::BufferedObservation],
    session_id: &str,
) -> Result<usize, MemError> { todo!() }

/// Synthesize buffered observations into learnings
///
/// Instead of storing every observation, we analyze the buffer and extract
/// meaningful learnings at session end. This dramatically reduces noise.
///
/// When `ai-extraction` feature is enabled and config allows, uses Claude
/// for smarter synthesis. Otherwise falls back to rule-based synthesis.
pub fn synthesize_buffered_observations(
    cas_root: &std::path::Path,
    buffered: &[crate::tracing::BufferedObservation],
    session_id: &str,
) -> Result<usize, MemError> { todo!() }
