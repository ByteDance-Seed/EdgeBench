mod attribution;
mod notifications;
mod pre_tool;

pub use attribution::{capture_file_change_for_attribution, detect_and_link_git_commit};
#[cfg(test)]
pub(crate) use attribution::{
    compute_content_hash, extract_commit_hash, extract_commit_message, generate_file_change_id,
    is_git_commit_command,
};
pub use notifications::{handle_notification, handle_permission_request, handle_pre_compact};
pub use pre_tool::handle_pre_tool_use;
