//! Event type definitions for activity tracking
//!
//! Events record significant actions in CAS for the sidecar activity feed.
//! They provide a chronological log of agent activity, task changes, and memory storage.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;

/// Type of event that occurred
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EventType {
    /// Agent registered with CAS
    AgentRegistered,
    /// Agent heartbeat (throttled, not every heartbeat)
    AgentHeartbeat,
    /// Agent shut down or died
    AgentShutdown,
    /// New task created
    TaskCreated,
    /// Task started (status → InProgress)
    TaskStarted,
    /// Task completed (status → Closed)
    TaskCompleted,
    /// Task blocked (status → Blocked)
    TaskBlocked,
    /// Note added to a task
    TaskNoteAdded,
    /// Task deleted
    TaskDeleted,
    /// Memory/learning stored
    MemoryStored,
    /// Rule promoted to proven
    RulePromoted,
    /// Skill used/invoked
    SkillUsed,

    // Factory session events
    /// Factory session started
    FactoryStarted,
    /// Factory session stopped
    FactoryStopped,
    /// Worker agent died unexpectedly
    WorkerDied,
    /// Worker assigned a task by supervisor
    WorkerAssigned,
    /// Worker completed assigned task
    WorkerCompleted,
    /// Supervisor received batch of notifications
    SupervisorNotified,
    /// Supervisor injected prompt to worker
    SupervisorInjected,

    // Worker activity events (for supervisor visibility)
    /// Worker spawned a subagent (e.g., task-verifier)
    WorkerSubagentSpawned,
    /// Worker's subagent completed
    WorkerSubagentCompleted,
    /// Worker edited a file
    WorkerFileEdited,
    /// Worker made a git commit
    WorkerGitCommit,
    /// Worker blocked waiting for verification
    WorkerVerificationBlocked,

    // Verification lifecycle events
    /// Verification started (task-verifier spawned for a task)
    VerificationStarted,
    /// Verification result recorded
    VerificationAdded,
}

impl fmt::Display for EventType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for EventType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Type of entity the event relates to
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum EventEntityType {
    Agent,
    Task,
    Entry,
    Rule,
    Skill,
    Session,
    Verification,
}

impl fmt::Display for EventEntityType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for EventEntityType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// An event recording a significant action in CAS
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Event {
    /// Auto-incrementing event ID
    pub id: i64,
    /// Type of event
    pub event_type: EventType,
    /// Type of entity this event relates to
    pub entity_type: EventEntityType,
    /// ID of the affected entity
    pub entity_id: String,
    /// Human-readable summary of the event
    pub summary: String,
    /// Optional JSON metadata with additional context
    #[serde(skip_serializing_if = "Option::is_none")]
    pub metadata: Option<serde_json::Value>,
    /// When the event occurred
    pub created_at: DateTime<Utc>,
    /// Optional session ID of the agent that caused this event
    #[serde(skip_serializing_if = "Option::is_none")]
    pub session_id: Option<String>,
}

impl Event {
    /// Create a new event (ID will be assigned by the database)
    pub fn new(
        event_type: EventType,
        entity_type: EventEntityType,
        entity_id: impl Into<String>,
        summary: impl Into<String>,
    ) -> Self { todo!() }

    /// Add metadata to the event
    pub fn with_metadata(mut self, metadata: serde_json::Value) -> Self { todo!() }

    /// Add session ID to the event
    pub fn with_session(mut self, session_id: impl Into<String>) -> Self { todo!() }

    /// Get the icon for this event type (for UI display)
    pub fn icon(&self) -> &'static str { todo!() }
}

impl Default for Event {
    fn default() -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::event::*;

    #[test]
    fn test_event_type_display() {
        assert_eq!(EventType::AgentRegistered.to_string(), "agent_registered");
        assert_eq!(EventType::TaskStarted.to_string(), "task_started");
    }



    #[test]
    fn test_event_with_metadata() {
        let event = Event::new(
            EventType::MemoryStored,
            EventEntityType::Entry,
            "2025-01-20-001",
            "Stored learning about Rust",
        )
        .with_metadata(serde_json::json!({"tags": ["rust", "learning"]}))
        .with_session("session-123");

        assert!(event.metadata.is_some());
        assert_eq!(event.session_id, Some("session-123".to_string()));
    }

    #[test]
    fn test_session_entity_type() {
        assert_eq!(
            EventEntityType::from_str("session").unwrap(),
            EventEntityType::Session
        );
        assert_eq!(EventEntityType::Session.to_string(), "session");
    }
}
