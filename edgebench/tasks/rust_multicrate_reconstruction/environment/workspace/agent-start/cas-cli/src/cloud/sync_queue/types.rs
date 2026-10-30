use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fmt;

/// Type of entity being synced
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum EntityType {
    Entry,
    Task,
    Rule,
    Skill,
    Session,
    Verification,
    Event,
    Prompt,
    FileChange,
    CommitLink,
    Agent,
    Worktree,
}

impl EntityType {
    pub fn as_str(&self) -> &'static str { todo!() }

    pub fn parse(value: &str) -> Option<Self> { todo!() }
}

impl fmt::Display for EntityType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

/// Type of sync operation
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum SyncOperation {
    /// Create or update an entity
    Upsert,
    /// Delete an entity
    Delete,
}

impl SyncOperation {
    pub fn as_str(&self) -> &'static str { todo!() }

    pub fn parse(value: &str) -> Option<Self> { todo!() }
}

impl fmt::Display for SyncOperation {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

/// A queued sync operation
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct QueuedSync {
    /// Queue item ID
    pub id: i64,
    /// Type of entity
    pub entity_type: EntityType,
    /// Entity ID (e.g., entry ID, task ID)
    pub entity_id: String,
    /// Operation to perform
    pub operation: SyncOperation,
    /// JSON-serialized entity data (for upsert operations)
    pub payload: Option<String>,
    /// Team ID for team-scoped sync (None for personal sync)
    pub team_id: Option<String>,
    /// When the item was queued
    pub created_at: DateTime<Utc>,
    /// Number of sync attempts
    pub retry_count: i32,
    /// Last error message (if any)
    pub last_error: Option<String>,
}

/// Queue statistics
#[derive(Debug, Clone, Serialize)]
pub struct QueueStats {
    /// Total items in queue
    pub total: usize,
    /// Items pending sync (under max retries)
    pub pending: usize,
    /// Items that have failed (at max retries)
    pub failed: usize,
    /// Count by entity type
    pub by_type: HashMap<String, usize>,
    /// Oldest item timestamp
    pub oldest_item: Option<String>,
}

/// Pending items grouped by entity type
#[derive(Debug, Default)]
pub struct PendingByType {
    pub entries: Vec<QueuedSync>,
    pub tasks: Vec<QueuedSync>,
    pub rules: Vec<QueuedSync>,
    pub skills: Vec<QueuedSync>,
    pub sessions: Vec<QueuedSync>,
    pub verifications: Vec<QueuedSync>,
    pub events: Vec<QueuedSync>,
    pub prompts: Vec<QueuedSync>,
    pub file_changes: Vec<QueuedSync>,
    pub commit_links: Vec<QueuedSync>,
    pub agents: Vec<QueuedSync>,
    pub worktrees: Vec<QueuedSync>,
}

impl PendingByType {
    pub fn is_empty(&self) -> bool { todo!() }

    pub fn total(&self) -> usize { todo!() }
}
