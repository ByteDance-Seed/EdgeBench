//! Native Agent Teams integration for factory daemon.
//!
//! Manages Claude Code's native Agent Teams file structure:
//! - `~/.claude/teams/{team-name}/config.json` — team member registry
//! - `~/.claude/teams/{team-name}/inboxes/{agent-name}.json` — per-agent inbox files
//!
//! This replaces the old prompt_queue + mux.inject (PTY stdin injection) transport
//! with native Teams mailbox writes that Claude Code polls internally.

use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Colors assigned to team members (matches Claude Code's palette).
const AGENT_COLORS: &[&str] = &["green", "blue", "yellow", "cyan", "magenta", "red", "white"];

/// The director agent name registered in the team config.
/// The daemon uses this identity when writing system/auto-prompt messages
/// to agent inboxes so that Claude Code recognizes the sender as a valid
/// team member.
pub const DIRECTOR_AGENT_NAME: &str = "director";

/// A single message in a Teams inbox file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct InboxMessage {
    pub from: String,
    pub text: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub summary: Option<String>,
    pub timestamp: String,
    pub color: String,
    pub read: bool,
}

/// Team member entry in config.json.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TeamMember {
    pub agent_id: String,
    pub name: String,
    pub agent_type: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub model: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub prompt: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub color: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub plan_mode_required: Option<bool>,
    pub joined_at: u64,
    pub tmux_pane_id: String,
    pub cwd: String,
    #[serde(default)]
    pub subscriptions: Vec<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub backend_type: Option<String>,
}

/// Team config.json structure.
#[derive(Debug, Clone, Serialize, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct TeamConfig {
    pub name: String,
    pub description: String,
    pub created_at: u64,
    pub lead_agent_id: String,
    pub lead_session_id: String,
    pub members: Vec<TeamMember>,
}

/// Manages the native Agent Teams file structure for a factory session.
pub struct TeamsManager {
    team_name: String,
    teams_dir: PathBuf,
    inboxes_dir: PathBuf,
}

impl TeamsManager {
    /// Create a new TeamsManager for the given factory session.
    ///
    /// The team name is derived from the session name.
    /// Files are stored at `~/.claude/teams/{team-name}/`.
    pub fn new(session_name: &str) -> Self { todo!() }

    /// Get the team name.
    pub fn team_name(&self) -> &str { todo!() }

    /// Format an agent ID: `{name}@{team-name}`.
    pub fn agent_id_for(&self, name: &str) -> String { todo!() }

    /// Build a teams_configs HashMap for MuxConfig before agents are spawned.
    ///
    /// This is a static method because it's called before TeamsManager is fully
    /// initialized (before `init_team_config`). It constructs the CLI flags map
    /// that Mux::factory() uses when spawning agent PTYs.
    /// Returns `(configs_map, lead_session_id)`.
    pub fn build_configs_for_mux(
        session_name: &str,
        supervisor_name: &str,
        worker_names: &[String],
    ) -> (
        std::collections::HashMap<String, cas_mux::TeamsSpawnConfig>,
        String,
    ) { todo!() }

    /// Assign a color to an agent based on its index in the team.
    pub fn color_for_index(index: usize) -> &'static str { todo!() }

    /// Initialize the team directory and write config.json with supervisor + initial workers.
    ///
    /// `worker_cwds` maps worker names to their actual working directories (worktree paths
    /// when worktrees are enabled). Workers not in the map use `project_cwd` as fallback.
    pub fn init_team_config(
        &self,
        worker_names: &[String],
        project_cwd: &std::path::Path,
        worker_cwds: &std::collections::HashMap<String, std::path::PathBuf>,
        lead_session_id: &str,
    ) -> anyhow::Result<()> { todo!() }

    /// Add a new member to the team (e.g., when a worker is spawned dynamically).
    pub fn add_member(
        &self,
        name: &str,
        cwd: &std::path::Path,
        color_index: usize,
    ) -> anyhow::Result<()> { todo!() }

    /// Remove a member from the team (e.g., when a worker is shut down).
    pub fn remove_member(&self, name: &str) -> anyhow::Result<()> { todo!() }

    /// Write a message to a target agent's inbox file.
    ///
    /// Uses file locking to prevent corruption when multiple writers
    /// (daemon + agents) access the same inbox concurrently.
    pub fn write_to_inbox(
        &self,
        target: &str,
        from: &str,
        message: &str,
        summary: Option<&str>,
        color: Option<&str>,
    ) -> anyhow::Result<()> { todo!() }

    /// Ensure an inbox file exists for the given agent.
    fn ensure_inbox(&self, name: &str) -> anyhow::Result<()> { todo!() }

    /// Clean up the team directory on shutdown.
    pub fn cleanup(&self) { todo!() }

    /// Remove orphaned team directories whose daemon is no longer running.
    ///
    /// Scans `~/.claude/teams/` for directories and checks if the corresponding
    /// factory daemon socket (`~/.cas/factory-{name}.sock`) still exists. If the
    /// socket is gone, the daemon crashed without cleaning up and the team
    /// directory is safe to remove.
    ///
    /// Called once at daemon startup to clean up after previous crashes.
    pub fn cleanup_orphans() { todo!() }

    /// Build a `cas_mux::TeamsSpawnConfig` for spawning a new agent with native teams flags.
    pub fn spawn_config_for(
        &self,
        name: &str,
        agent_type: &str,
        color: &str,
        parent_session_id: Option<&str>,
    ) -> cas_mux::TeamsSpawnConfig { todo!() }
}
