use crate::hooks::handlers::*;

pub fn generate_file_change_id() -> String { todo!() }

/// Compute content hash using SHA-256
pub fn compute_content_hash(content: &str) -> String { todo!() }

/// Get the repository name from the current directory
pub fn get_repository_name() -> String { todo!() }

/// Normalize an absolute file path to a relative path
///
/// Enables cross-clone file tracking in factory mode by stripping the
/// clone-specific directory prefix. Handles both main repo and worktree/clone paths.
///
/// Examples:
/// - `/Users/user/project/src/foo.rs` -> `src/foo.rs` (main repo)
/// - `/Users/user/worktrees/swift-fox/src/foo.rs` -> `src/foo.rs` (clone)
pub fn normalize_to_relative_path(cas_root: &std::path::Path, file_path: &str) -> String { todo!() }

/// Capture a file change for attribution tracking
///
/// Called from PostToolUse for Write and Edit tools.
/// Records which file was changed and links to the current prompt/session.
pub fn capture_file_change_for_attribution(
    cas_root: &std::path::Path,
    input: &HookInput,
    tool_name: &str,
) { todo!() }

/// Get the most recent prompt ID for a session
pub fn get_current_prompt_id(cas_root: &std::path::Path, session_id: &str) -> Option<String> { todo!() }

// =============================================================================
// GIT COMMIT DETECTION (Code Attribution)
// =============================================================================

/// Detect git commit command and link uncommitted file changes
///
/// Called from PostToolUse for Bash commands that contain "git commit".
/// Links all uncommitted file_changes for this session to the commit.
pub fn detect_and_link_git_commit(cas_root: &std::path::Path, input: &HookInput) { todo!() }

/// Check if a command is a git commit command
pub fn is_git_commit_command(command: &str) -> bool { todo!() }

/// Extract commit hash from git commit output
///
/// Git commit output format: "[branch hash] message"
/// Example: "[main abc1234] Add new feature"
pub fn extract_commit_hash(stdout: &str) -> Option<String> { todo!() }

/// Extract commit message from git commit command
pub fn extract_commit_message(command: &str) -> Option<String> { todo!() }

/// Get current git branch name
pub fn get_current_branch() -> Option<String> { todo!() }

/// Get git author from config
pub fn get_git_author() -> Option<String> { todo!() }
