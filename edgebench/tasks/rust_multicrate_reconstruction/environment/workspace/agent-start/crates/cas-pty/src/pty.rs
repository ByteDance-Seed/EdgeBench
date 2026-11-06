//! PTY management using portable-pty
//!
//! Provides a wrapper around portable-pty with:
//! - Async read/write operations
//! - Raw byte output (terminal parsing done by ghostty_vt)
//! - Resize support

use crate::error::{Error, Result};
use portable_pty::{CommandBuilder, PtySize, native_pty_system};
use std::io::{Read, Write};
use std::path::PathBuf;
use std::sync::Arc;
use tokio::sync::Mutex;
use tokio::sync::mpsc;

/// Configuration for spawning a PTY
#[derive(Debug, Clone)]
pub struct PtyConfig {
    /// Command to run (e.g., "claude")
    pub command: String,
    /// Arguments for the command
    pub args: Vec<String>,
    /// Working directory
    pub cwd: Option<PathBuf>,
    /// Environment variables to set
    pub env: Vec<(String, String)>,
    /// Initial terminal size
    pub rows: u16,
    pub cols: u16,
}

/// Configuration for spawning an agent with native Claude Code Agent Teams flags.
#[derive(Debug, Clone)]
pub struct TeamsSpawnConfig {
    /// Team name (factory session name)
    pub team_name: String,
    /// Agent ID (e.g., "worker-1@session-name")
    pub agent_id: String,
    /// Agent display name
    pub agent_name: String,
    /// Agent color for UI
    pub agent_color: String,
    /// Agent type (e.g., "team-lead", "general-purpose")
    pub agent_type: String,
    /// Parent session ID for analytics correlation (workers only)
    pub parent_session_id: Option<String>,
}

impl Default for PtyConfig {
    fn default() -> Self { todo!() }
}

impl PtyConfig {
    /// Create config for a Claude CLI instance
    ///
    /// # Arguments
    /// * `name` - Agent name
    /// * `role` - Agent role (e.g., "worker", "supervisor")
    /// * `cwd` - Working directory for the agent
    /// * `cas_root` - Optional path to the .cas directory. If provided, sets CAS_ROOT env var
    ///   so workers in clones can access the main repo's CAS state.
    /// * `supervisor_name` - For workers, the name of their supervisor (enables `target: supervisor`)
    #[allow(clippy::too_many_arguments)]
    pub fn claude(
        name: &str,
        role: &str,
        cwd: PathBuf,
        cas_root: Option<&PathBuf>,
        supervisor_name: Option<&str>,
        factory_worker_cli: Option<&str>,
        model: Option<&str>,
        teams: Option<&TeamsSpawnConfig>,
    ) -> Self { todo!() }

    /// Create config for a Codex CLI instance
    ///
    /// # Arguments
    /// * `name` - Agent name
    /// * `role` - Agent role (e.g., "worker", "supervisor")
    /// * `cwd` - Working directory for the agent
    /// * `cas_root` - Optional path to the .cas directory. If provided, sets CAS_ROOT env var
    /// * `supervisor_name` - For workers, the name of their supervisor (enables `target: supervisor`)
    #[allow(clippy::too_many_arguments)]
    pub fn codex(
        name: &str,
        role: &str,
        cwd: PathBuf,
        cas_root: Option<&PathBuf>,
        supervisor_name: Option<&str>,
        factory_worker_cli: Option<&str>,
        model: Option<&str>,
        _teams: Option<&TeamsSpawnConfig>,
    ) -> Self { todo!() }
}

/// Events emitted by a PTY
#[derive(Debug, Clone)]
pub enum PtyEvent {
    /// Terminal output (raw bytes - parsing done by ghostty_vt)
    Output(Vec<u8>),
    /// Process exited
    Exited(Option<i32>),
    /// Error occurred
    Error(String),
}

/// A running PTY process
pub struct Pty {
    /// Unique identifier
    id: String,
    /// Writer handle for sending input
    writer: Arc<Mutex<Box<dyn Write + Send>>>,
    /// Channel for receiving raw output
    event_rx: mpsc::Receiver<PtyEvent>,
    /// Handle to the reader task
    _reader_handle: std::thread::JoinHandle<()>,
    /// Child process handle
    child: Box<dyn portable_pty::Child + Send + Sync>,
    /// Master PTY (keep alive)
    master: Box<dyn portable_pty::MasterPty + Send>,
    /// Whether this PTY is running Codex CLI
    is_codex: bool,
}

impl Pty {
    /// Spawn a new PTY with the given configuration
    pub fn spawn(id: impl Into<String>, config: PtyConfig) -> Result<Self> { todo!() }

    /// Reader loop that forwards raw PTY output
    fn reader_loop(
        mut reader: Box<dyn Read + Send>,
        writer: Arc<Mutex<Box<dyn Write + Send>>>,
        event_tx: mpsc::Sender<PtyEvent>,
    ) { todo!() }

    /// Get the PTY's identifier
    pub fn id(&self) -> &str { todo!() }

    /// Returns true when this PTY is running Codex CLI.
    pub fn is_codex(&self) -> bool { todo!() }

    /// Get a clone of the writer handle (for concurrent writing)
    pub fn writer_handle(&self) -> Arc<Mutex<Box<dyn Write + Send>>> { todo!() }

    /// Write input to the PTY (for prompt injection)
    pub async fn write(&self, data: &[u8]) -> Result<()> { todo!() }

    /// Write a string to the PTY
    pub async fn write_str(&self, s: &str) -> Result<()> { todo!() }

    /// Send a line of input (appends carriage return to submit, same as Enter key)
    pub async fn send_line(&self, line: &str) -> Result<()> { todo!() }

    /// Receive the next event from the PTY (blocking)
    pub async fn recv(&mut self) -> Option<PtyEvent> { todo!() }

    /// Try to receive an event from the PTY (non-blocking)
    pub fn try_recv(&mut self) -> Option<PtyEvent> { todo!() }

    /// Resize the PTY
    pub fn resize(&self, rows: u16, cols: u16) -> Result<()> { todo!() }

    /// Send Ctrl+C to the process
    pub async fn interrupt(&self) -> Result<()> { todo!() }

    /// Send Ctrl+D (EOF) to the process
    pub async fn send_eof(&self) -> Result<()> { todo!() }

    /// Kill the child process
    pub fn kill(&mut self) { todo!() }
}

fn filter_cursor_position_requests(carry: &[u8], chunk: &[u8]) -> (Vec<u8>, Vec<u8>, bool) { todo!() }

#[cfg(test)]
mod tests {
    use crate::pty::*;



    #[tokio::test]
    async fn test_pty_config_claude_with_cas_root() {
        let cas_root = PathBuf::from("/home/user/project/.cas");
        let config = PtyConfig::claude(
            "test-agent",
            "worker",
            PathBuf::from("/tmp"),
            Some(&cas_root),
            None,
            None,
            None,
            None,
        );
        assert!(
            config
                .env
                .iter()
                .any(|(k, v)| k == "CAS_ROOT" && v == "/home/user/project/.cas")
        );
    }


    #[tokio::test]
    async fn test_pty_config_sets_clone_path() {
        let config = PtyConfig::claude(
            "test-worker",
            "worker",
            PathBuf::from("/tmp/worktree"),
            None,
            None,
            None,
            None,
            None,
        );
        assert!(
            config
                .env
                .iter()
                .any(|(k, v)| k == "CAS_CLONE_PATH" && v == "/tmp/worktree")
        );
    }

    #[tokio::test]
    async fn test_pty_config_claude_with_model() {
        let config = PtyConfig::claude(
            "test-agent",
            "worker",
            PathBuf::from("/tmp"),
            None,
            None,
            None,
            Some("claude-opus-4-6"),
            None,
        );
        assert!(config.args.contains(&"--model".to_string()));
        assert!(config.args.contains(&"claude-opus-4-6".to_string()));
    }

    #[tokio::test]
    async fn test_pty_config_claude_without_model() {
        let config = PtyConfig::claude(
            "test-agent",
            "worker",
            PathBuf::from("/tmp"),
            None,
            None,
            None,
            None,
            None,
        );
        assert!(!config.args.contains(&"--model".to_string()));
    }



    #[tokio::test]
    async fn test_pty_config_claude_with_teams_lead() {
        let teams = TeamsSpawnConfig {
            team_name: "test-team".to_string(),
            agent_id: "supervisor@test-team".to_string(),
            agent_name: "supervisor".to_string(),
            agent_color: "green".to_string(),
            agent_type: "team-lead".to_string(),
            parent_session_id: None,
        };
        let config = PtyConfig::claude(
            "supervisor",
            "supervisor",
            PathBuf::from("/tmp"),
            None,
            None,
            None,
            None,
            Some(&teams),
        );
        // Lead also gets --teammate-mode so it polls its inbox
        assert!(config.args.contains(&"--teammate-mode".to_string()));
        assert!(config.args.contains(&"tmux".to_string()));
        // No --parent-session-id for the lead
        assert!(!config.args.contains(&"--parent-session-id".to_string()));
    }
}
