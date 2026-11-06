//! Clipboard support for the factory TUI
//!
//! On macOS, uses `pbcopy` subprocess to avoid NSPasteboard fork-safety issues.
//! On other platforms, uses the arboard crate.

/// Copy text to the system clipboard.
///
/// Returns Ok(()) on success, or an error if clipboard access fails.
///
/// # macOS Note
/// Uses `pbcopy` subprocess instead of direct NSPasteboard access because
/// NSPasteboard is not fork-safe. The factory daemon runs in a forked process,
/// and calling NSPasteboard APIs after fork() causes crashes.
pub fn copy_to_clipboard(text: &str) -> anyhow::Result<()> { todo!() }

#[cfg(test)]
mod tests {
    use crate::ui::factory::clipboard::*;

}
