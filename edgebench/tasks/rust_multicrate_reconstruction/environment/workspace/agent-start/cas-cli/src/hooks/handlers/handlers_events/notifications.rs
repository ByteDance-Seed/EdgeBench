use crate::hooks::handlers::*;

pub fn handle_permission_request(
    input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }

// ============================================================================
// Notification Hook Handler
// ============================================================================

/// Handle Notification hook - external alerts
///
/// This hook fires on various notification events and can:
/// 1. Send desktop notifications (via terminal-notifier on macOS)
/// 2. Optional webhook support for Slack/Discord
/// 3. Log notification patterns for analytics
///
/// Supported matchers: permission_prompt, idle_prompt, auth_success
pub fn handle_notification(
    input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }

/// Send a webhook notification (blocking, for use in spawned thread)
pub fn send_webhook_notification(url: &str, message: &str) -> Result<(), MemError> { todo!() }

// ============================================================================
// PreCompact Hook Handler
// ============================================================================

/// Handle PreCompact hook - preserve critical context before compaction
///
/// This hook fires before Claude's context is compacted and can:
/// 1. Inject high-importance memories before compaction
/// 2. Preserve active task context and decisions
/// 3. Support both manual (/compact) and auto triggers
/// 4. Optionally generate pre-compaction summary
///
/// Returns additionalContext with preserved memories
pub fn handle_pre_compact(
    input: &HookInput,
    cas_root: Option<&Path>,
) -> Result<HookOutput, MemError> { todo!() }
