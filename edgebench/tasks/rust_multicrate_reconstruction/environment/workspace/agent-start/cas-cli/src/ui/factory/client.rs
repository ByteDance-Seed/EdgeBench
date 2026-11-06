//! Factory TUI client - attaches to factory daemon via Unix socket
//!
//! Connects to the daemon's Unix socket and forwards terminal I/O.
//! The daemon renders the full TUI and broadcasts raw terminal output.
//! This client just forwards bytes between the terminal and socket.

use crate::ui::factory::session::{SessionInfo, SessionManager};
use base64::Engine;
use base64::engine::general_purpose::URL_SAFE_NO_PAD;
use cas_factory::SessionSummary;
use crossterm::event::{self, Event, KeyCode, KeyEvent, KeyModifiers};
use crossterm::execute;
use crossterm::terminal::{self, disable_raw_mode, enable_raw_mode};
use ghostty_vt::KeyModifiers as GhosttyKeyModifiers;
use std::io::{self, Read, Write};
use std::os::unix::net::UnixStream;
use std::path::PathBuf;
use std::time::Duration;

/// Attach to an existing factory session via Unix socket
///
/// Connects to the daemon's Unix socket for the given session.
pub fn attach(session_name: Option<String>) -> anyhow::Result<()> { todo!() }

/// Attach via Unix socket (local daemon mode)
///
/// The daemon renders the full TUI and broadcasts raw terminal output.
/// This client just forwards bytes between the terminal and socket.
fn attach_unix(session: &SessionInfo) -> anyhow::Result<()> { todo!() }

fn contains_dropped_image_path(text: &str) -> bool { todo!() }

fn normalize_image_path_candidate(candidate: &str) -> Option<String> { todo!() }

fn decode_file_uri_path(uri_path: &str) -> String { todo!() }

fn is_image_path(path: &str) -> bool { todo!() }

/// List all factory sessions
pub fn list_sessions() -> anyhow::Result<Vec<SessionInfo>> { todo!() }

/// List factory sessions for a specific project directory
pub fn list_sessions_for_project(project_dir: &str) -> anyhow::Result<Vec<SessionInfo>> { todo!() }

/// Find a running session for a specific project directory
pub fn find_session_for_project(
    project_dir: &str,
    name: Option<&str>,
) -> anyhow::Result<Option<SessionInfo>> { todo!() }

/// List all factory sessions as unified SessionSummary.
///
/// This provides rich session metadata using the unified session model
/// from `cas_factory::UnifiedSessionManager`.
pub fn list_session_summaries() -> anyhow::Result<Vec<SessionSummary>> { todo!() }

/// List factory sessions for a project as unified SessionSummary.
pub fn list_session_summaries_for_project(
    project_dir: &str,
) -> anyhow::Result<Vec<SessionSummary>> { todo!() }

/// Convert a key event to terminal bytes using ghostty_vt's key encoding
fn key_to_bytes(key: &KeyEvent) -> Vec<u8> { todo!() }

fn ctrl_char_to_byte(c: char) -> Option<u8> { todo!() }

#[cfg(test)]
mod tests {
    use super::*;
    use crossterm::event::KeyEventKind;
    use crossterm::event::KeyEventState;

    #[test]
    fn detects_dropped_images_from_plain_path_and_file_uri() {
        assert!(contains_dropped_image_path(
            "/tmp/screenshot.png\nfile:///Users/test/Pictures/image%201.jpeg\n/tmp/not-image.txt"
        ));
    }


    #[test]
    fn key_to_bytes_encodes_ctrl_bracket_as_group_separator() {
        let key = KeyEvent {
            code: KeyCode::Char(']'),
            modifiers: KeyModifiers::CONTROL,
            kind: KeyEventKind::Press,
            state: KeyEventState::empty(),
        };
        assert_eq!(key_to_bytes(&key), vec![0x1d]);
    }


    #[test]
    fn key_to_bytes_encodes_ctrl_alpha() {
        let key = KeyEvent {
            code: KeyCode::Char('d'),
            modifiers: KeyModifiers::CONTROL,
            kind: KeyEventKind::Press,
            state: KeyEventState::empty(),
        };
        assert_eq!(key_to_bytes(&key), vec![0x04]);
    }
}
