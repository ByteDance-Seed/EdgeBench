use crate::hooks::handlers::*;

pub fn handle_user_prompt_submit(
    input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }

/// Capture a prompt for code attribution (git blame for AI sessions)
///
/// This function stores every user prompt in the prompts table, enabling
/// later attribution: "which prompt created this code?"
///
/// Unlike the context entry logic, this captures ALL prompts (even short ones)
/// because any prompt could trigger code changes.
pub fn capture_prompt_for_attribution(
    cas_root: &std::path::Path,
    input: &HookInput,
    prompt_text: &str,
) { todo!() }

/// Generate a unique prompt ID using ULID
pub fn generate_prompt_id() -> String { todo!() }

/// Get the ID of the currently in-progress task (if any)
pub fn get_current_task_id(cas_root: &std::path::Path) -> Option<String> { todo!() }

/// Capture the conversation transcript and update prompts with messages (blame v2)
///
/// Called at session end to store the full conversation for each prompt,
/// enabling rich context display in `cas blame --verbose`.
pub fn capture_transcript_for_prompts(cas_root: &std::path::Path, input: &HookInput) { todo!() }

/// Determine if a user prompt is important enough to capture
pub fn is_important_prompt(prompt: &str) -> bool { todo!() }

/// Detect if a user prompt expresses a preference or rule
///
/// Looks for patterns like:
/// - "never add TODOs" / "don't add TODOs"
/// - "always implement full functionality"
/// - "prefer X over Y" / "use X instead of Y"
pub fn is_preference_prompt(prompt: &str) -> bool { todo!() }

/// Extract a preference/rule from a user prompt using AI
///
/// Returns None if no clear preference is detected or extraction fails
pub fn extract_preference_from_prompt(prompt: &str) -> Option<ExtractedPreference> { todo!() }

/// Async implementation of preference extraction using Haiku
async fn extract_preference_from_prompt_async(
    prompt: &str,
) -> Result<Option<ExtractedPreference>, MemError> { todo!() }
