//! Agent type definitions for multi-agent coordination
//!
//! Agents represent Claude Code instances that can claim and work on tasks.
//! The agent ID is the Claude Code session ID - a 1:1 mapping between
//! Claude Code sessions and CAS agents.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;

/// Status of an agent
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum AgentStatus {
    /// Agent is active and can accept work
    #[default]
    Active,
    /// Agent is idle (no recent heartbeat but not yet expired)
    Idle,
    /// Agent has gone stale (heartbeat expired, can be revived)
    /// Renamed from Dead - agents can now be revived on MCP tool use
    Stale,
    /// Agent has gracefully shut down
    Shutdown,
}

impl fmt::Display for AgentStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for AgentStatus {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Type of agent
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum AgentType {
    /// Primary Claude Code instance (human-interactive)
    #[default]
    Primary,
    /// Sub-agent spawned by Task tool (has own session, linked via parent_id)
    SubAgent,
    /// Background worker (daemon, maintenance)
    Worker,
    /// CI/CD agent
    CI,
}

impl fmt::Display for AgentType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for AgentType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Role of an agent in a factory session
///
/// Roles define the agent's responsibilities in a hierarchical multi-agent system:
/// - Standard: Default role for regular agents (human-interactive or standalone)
/// - Director: Always-on TUI that monitors events, batches notifications, routes to supervisor
/// - Supervisor: Plans epics, assigns tasks, handles merges, ensures quality
/// - Worker: Executes single tasks in isolated worktrees
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum AgentRole {
    /// Default role for regular agents
    #[default]
    Standard,
    /// Always-on TUI that monitors and routes events
    Director,
    /// Plans epics, assigns tasks, handles merges
    Supervisor,
    /// Executes single tasks in worktrees
    Worker,
}

impl fmt::Display for AgentRole {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for AgentRole {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// An agent that can claim and work on tasks.
///
/// Agent identification uses PPID + machine hash for stability:
/// - Format: `cc-{ppid}-{machine_hash}` (e.g., `cc-12345-a8f3b2c1`)
/// - PPID = Claude Code's PID (since MCP runs as subprocess)
/// - Machine hash = hash of hostname + username for cross-machine uniqueness
///
/// This is stable across `/compact`, `--resume`, and multi-terminal scenarios.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Agent {
    /// PPID-based agent identifier (cc-{ppid}-{machine_hash})
    pub id: String,

    /// Human-readable name (e.g., "Claude Code (PID 12345)")
    pub name: String,

    /// Type of agent
    pub agent_type: AgentType,

    /// Role in factory sessions (Standard, Director, Supervisor, Worker)
    #[serde(default)]
    pub role: AgentRole,

    /// Current status
    pub status: AgentStatus,

    /// MCP server process ID (for debugging, not identification)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub pid: Option<u32>,

    /// Claude Code's PID (the parent process of MCP server)
    /// Used for process liveness checks and debugging
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub ppid: Option<u32>,

    /// Original Claude Code session ID (for correlation/audit)
    /// Kept for backward compatibility and cloud sync correlation
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub cc_session_id: Option<String>,

    /// Parent agent ID (for Task tool sub-agents, links to parent's agent ID)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub parent_id: Option<String>,

    /// Machine identifier (hostname or unique machine ID)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub machine_id: Option<String>,

    /// When the agent was registered
    pub registered_at: DateTime<Utc>,

    /// Last heartbeat timestamp
    pub last_heartbeat: DateTime<Utc>,

    /// Number of tasks currently claimed by this agent
    #[serde(default)]
    pub active_tasks: u32,

    /// Optional metadata (capabilities, version, etc.)
    #[serde(default)]
    pub metadata: std::collections::HashMap<String, String>,
}

impl Agent {
    /// Create a new agent with the given ID and name
    ///
    /// The `id` should be a PPID-based ID (cc-{ppid}-{machine_hash}) for normal agents.
    /// For CLI/worker agents without a Claude Code parent, use `generate_fallback_id()`.
    pub fn new(id: String, name: String) -> Self { todo!() }

    /// Create a new agent with PPID information
    ///
    /// Use this when creating agents from MCP server context where
    /// PPID (Claude Code's PID) and session_id are known.
    pub fn new_with_ppid(
        id: String,
        name: String,
        ppid: u32,
        cc_session_id: Option<String>,
    ) -> Self { todo!() }

    /// Create a new sub-agent with a parent (for Task tool spawned agents)
    ///
    /// Sub-agents have their own PPID-based ID but are linked to their parent.
    pub fn new_sub_agent(id: String, name: String, parent_id: String) -> Self { todo!() }

    /// Create a new agent with a specific role (for factory sessions)
    ///
    /// Use this when creating agents in a factory session with defined roles.
    pub fn new_with_role(id: String, name: String, role: AgentRole) -> Self { todo!() }

    /// Set the agent's role
    pub fn with_role(mut self, role: AgentRole) -> Self { todo!() }

    /// Generate a fallback ID for agents without a Claude Code session
    ///
    /// Use this only for CLI tools, workers, or CI agents that don't have
    /// a Claude Code session ID. Normal Claude Code agents should use the
    /// session ID as their agent ID.
    pub fn generate_fallback_id() -> String { todo!() }

    /// Update the heartbeat timestamp
    pub fn heartbeat(&mut self) { todo!() }

    /// Check if the agent's heartbeat has expired
    pub fn is_heartbeat_expired(&self, timeout_secs: i64) -> bool { todo!() }

    /// Mark the agent as stale (heartbeat expired, can be revived)
    pub fn mark_stale(&mut self) { todo!() }

    /// Mark the agent as gracefully shutdown
    pub fn mark_shutdown(&mut self) { todo!() }

    /// Check if the agent is alive (active or idle)
    pub fn is_alive(&self) -> bool { todo!() }

    /// Get the machine ID, generating one if needed
    pub fn get_or_generate_machine_id() -> String { todo!() }
}

impl Default for Agent {
    fn default() -> Self { todo!() }
}

/// Default heartbeat timeout in seconds (5 minutes)
pub const DEFAULT_HEARTBEAT_TIMEOUT_SECS: i64 = 300;

/// Default heartbeat interval in seconds (30 seconds)
pub const DEFAULT_HEARTBEAT_INTERVAL_SECS: u64 = 30;

/// Default lease duration in seconds (10 minutes)
pub const DEFAULT_LEASE_DURATION_SECS: i64 = 600;

/// Maximum concurrent tasks per agent (default)
pub const DEFAULT_MAX_CONCURRENT_TASKS: u32 = 5;

/// Capabilities that an agent can have
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum AgentCapability {
    /// General coding tasks
    Coding,
    /// Code review
    Review,
    /// Testing and test writing
    Testing,
    /// Documentation
    Documentation,
    /// DevOps and infrastructure
    DevOps,
    /// Bug fixing
    BugFix,
    /// Research and exploration
    Research,
    /// Refactoring
    Refactor,
}

impl fmt::Display for AgentCapability {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for AgentCapability {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

impl AgentCapability {
    /// Get all available capabilities
    pub fn all() -> Vec<Self> { todo!() }

    /// Get default capabilities for an agent type
    pub fn defaults_for(agent_type: AgentType) -> Vec<Self> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::agent::*;

    #[test]
    fn test_agent_status_from_str() {
        assert_eq!(
            AgentStatus::from_str("active").unwrap(),
            AgentStatus::Active
        );
        assert_eq!(AgentStatus::from_str("idle").unwrap(), AgentStatus::Idle);
        assert_eq!(AgentStatus::from_str("stale").unwrap(), AgentStatus::Stale);
        assert_eq!(AgentStatus::from_str("dead").unwrap(), AgentStatus::Stale); // backward compat
        assert_eq!(
            AgentStatus::from_str("shutdown").unwrap(),
            AgentStatus::Shutdown
        );
        assert!(AgentStatus::from_str("invalid").is_err());
    }

    #[test]
    fn test_agent_type_from_str() {
        assert_eq!(AgentType::from_str("primary").unwrap(), AgentType::Primary);
        assert_eq!(
            AgentType::from_str("sub_agent").unwrap(),
            AgentType::SubAgent
        );
        assert_eq!(AgentType::from_str("worker").unwrap(), AgentType::Worker);
        assert_eq!(AgentType::from_str("ci").unwrap(), AgentType::CI);
    }


    #[test]
    fn test_agent_sub_agent() {
        let agent = Agent::new_sub_agent(
            "agent-sub".to_string(),
            "Sub Agent".to_string(),
            "agent-parent".to_string(),
        );
        assert_eq!(agent.agent_type, AgentType::SubAgent);
        assert_eq!(agent.parent_id, Some("agent-parent".to_string()));
    }

    #[test]
    fn test_agent_fallback_id_generation() {
        let id1 = Agent::generate_fallback_id();
        let id2 = Agent::generate_fallback_id();
        assert!(id1.starts_with("cli-"));
        assert!(id2.starts_with("cli-"));
        // IDs should be different (with very high probability)
        assert_ne!(id1, id2);
    }

    #[test]
    fn test_heartbeat() {
        let mut agent = Agent::new("test".to_string(), "Test".to_string());
        let old_heartbeat = agent.last_heartbeat;
        std::thread::sleep(std::time::Duration::from_millis(10));
        agent.heartbeat();
        assert!(agent.last_heartbeat > old_heartbeat);
    }

    #[test]
    fn test_heartbeat_expiry() {
        let mut agent = Agent::new("test".to_string(), "Test".to_string());
        // Set heartbeat to 10 seconds ago
        agent.last_heartbeat = Utc::now() - chrono::Duration::seconds(10);
        assert!(agent.is_heartbeat_expired(5));
        assert!(!agent.is_heartbeat_expired(15));
    }

    #[test]
    fn test_agent_role_from_str() {
        assert_eq!(
            AgentRole::from_str("standard").unwrap(),
            AgentRole::Standard
        );
        assert_eq!(AgentRole::from_str("").unwrap(), AgentRole::Standard);
        assert_eq!(
            AgentRole::from_str("director").unwrap(),
            AgentRole::Director
        );
        assert_eq!(
            AgentRole::from_str("supervisor").unwrap(),
            AgentRole::Supervisor
        );
        assert_eq!(AgentRole::from_str("worker").unwrap(), AgentRole::Worker);
        assert!(AgentRole::from_str("invalid").is_err());
    }

    #[test]
    fn test_agent_role_display() {
        assert_eq!(AgentRole::Standard.to_string(), "standard");
        assert_eq!(AgentRole::Director.to_string(), "director");
        assert_eq!(AgentRole::Supervisor.to_string(), "supervisor");
        assert_eq!(AgentRole::Worker.to_string(), "worker");
    }



}
