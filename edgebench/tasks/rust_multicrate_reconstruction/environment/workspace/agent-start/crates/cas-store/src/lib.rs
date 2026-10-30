//! Storage abstraction for CAS
//!
//! This crate provides a unified storage interface for all CAS data types:
//!
//! - [`Store`] - Entry (memory) storage operations
//! - [`RuleStore`] - Rule storage operations
//! - [`TaskStore`] - Task and dependency storage operations
//! - [`SkillStore`] - Skill storage operations
//! - [`CodeStore`] - Code file and symbol storage operations
//!
//! # Implementations
//!
//! - **SQLite** (`SqliteStore`, `SqliteRuleStore`, etc.) - Primary backend,
//!   uses WAL mode for good read concurrency
//! - **Markdown** (`MarkdownStore`, `MarkdownRuleStore`) - Legacy file-based
//!   storage with YAML frontmatter
//!
//! # Concurrency
//!
//! All SQLite stores share a process-level connection pool (`shared_db`) to
//! minimize connection count. A 5-second busy timeout plus application-level
//! retry with exponential backoff handles concurrent access from multiple
//! agents in factory mode.

use std::time::Duration;

/// Busy timeout for SQLite connections to handle concurrent access.
/// When multiple agents try to write simultaneously, SQLite will wait
/// up to this duration before returning SQLITE_BUSY.
///
/// Reduced from 30s to 5s — application-level retry with exponential
/// backoff (in `shared_db::with_write_retry`) handles longer contention.
pub const SQLITE_BUSY_TIMEOUT: Duration = Duration::from_secs(5);

pub mod shared_db;

mod agent_store;
mod code_store;
mod commit_link_store;
mod entity_store;
pub mod error;
mod event_store;
mod file_change_store;
pub mod layered;
mod loop_store;
pub mod markdown;
mod prompt_queue_store;
mod prompt_store;
mod recording_store;
mod recording_text_store;
mod reminder_store;
mod skill_store;
mod spawn_queue_store;
mod spec_store;
mod sqlite;
mod sqlite_code_store;
mod supervisor_queue_store;
mod task_store;
pub mod tracing;
mod verification_store;
mod worktree_store;

// Mock stores for testing
#[cfg(test)]
pub mod mock;

// Worktree lease tests (TDD)
#[cfg(test)]
mod worktree_lease_test;

// Re-export error types
pub use error::{Result, StoreError};

// Agent store for multi-agent coordination
pub use agent_store::{AgentStore, LeaseHistoryEntry, SqliteAgentStore};

// Event store for activity tracking (sidecar)
pub use event_store::{EVENT_SCHEMA, EventStore, SqliteEventStore, record_event_with_conn};

// Code store for indexed source code
pub use code_store::CodeStore;
pub use sqlite_code_store::SqliteCodeStore;

// Entity store for knowledge graph feature
pub use entity_store::SqliteEntityStore;

// Loop store for iteration loops
pub use loop_store::{LoopStore, SqliteLoopStore};

// Verification store for task quality gates
pub use verification_store::{
    SqliteVerificationStore, VerificationStore, add_verification_with_conn,
    save_verification_issues_with_conn,
};

// Worktree store for git worktree tracking
pub use worktree_store::{SqliteWorktreeStore, WorktreeStore};

// Recording store for terminal recording metadata
pub use recording_store::{
    RecordingStore, SqliteRecordingStore, capture_agent_event, capture_memory_event,
    capture_message_event, capture_recording_event, capture_task_event,
    get_active_recording_with_conn, get_any_active_recording_with_conn,
    record_agent_event_with_conn, record_memory_event_with_conn, record_message_event_with_conn,
    record_recording_event_with_conn, record_task_event_with_conn,
};

// Supervisor queue store for factory sessions
pub use supervisor_queue_store::{
    NotificationPriority, SqliteSupervisorQueueStore, SupervisorNotification, SupervisorQueueStore,
};

// Prompt queue store for supervisor → worker communication
pub use prompt_queue_store::{PromptQueueStore, QueuedPrompt, SqlitePromptQueueStore};

// Reminder store for supervisor "Remind Me" feature
pub use reminder_store::{
    Reminder, ReminderStatus, ReminderStore, ReminderTriggerType, SqliteReminderStore,
};

// Spawn queue store for worker lifecycle commands
pub use spawn_queue_store::{SpawnAction, SpawnQueueStore, SpawnRequest, SqliteSpawnQueueStore};

// Prompt store for tracking user prompts (code attribution)
pub use prompt_store::{
    PROMPT_SCHEMA, PromptStore, SqlitePromptStore, add_prompt_with_conn,
    get_current_prompt_for_session,
};

// File change store for tracking AI-generated code changes (code attribution)
pub use file_change_store::{
    FILE_CHANGE_SCHEMA, FileChangeStore, SqliteFileChangeStore, add_file_change_with_conn,
};

// Commit link store for associating git commits with AI sessions (code attribution)
pub use commit_link_store::{
    COMMIT_LINK_SCHEMA, CommitLinkStore, SqliteCommitLinkStore, add_commit_link_with_conn,
};

// Recording text store for full-text search in factory recordings
pub use recording_text_store::{
    RecordingSearchResult, RecordingTextEntry, RecordingTextStore, SqliteRecordingTextStore,
    format_timestamp,
};

// Core stores
pub use layered::{LayeredEntryStore, LayeredRuleStore, LayeredSkillStore};
pub use markdown::{MarkdownRuleStore, MarkdownStore};
pub use skill_store::SqliteSkillStore;
pub use spec_store::{SpecStore, SqliteSpecStore};
pub use sqlite::{SqliteRuleStore, SqliteStore};
pub use task_store::{SqliteTaskStore, clear_pending_verification_with_conn};

use cas_types::{
    Dependency, DependencyType, Entity, EntityMention, EntityType, Entry, RelationType,
    Relationship, Rule, Skill, SkillStatus, Task, TaskStatus, TaskType,
};

/// Trait for entry storage operations
pub trait Store: Send + Sync {
    /// Initialize the store (create tables, etc.)
    fn init(&self) -> Result<()>;

    /// Generate a new unique entry ID
    fn generate_id(&self) -> Result<String>;

    /// Add a new entry
    fn add(&self, entry: &Entry) -> Result<()>;

    /// Get an entry by ID
    fn get(&self, id: &str) -> Result<Entry>;

    /// Get an archived entry by ID
    fn get_archived(&self, id: &str) -> Result<Entry>;

    /// Update an existing entry
    fn update(&self, entry: &Entry) -> Result<()>;

    /// Delete an entry
    fn delete(&self, id: &str) -> Result<()>;

    /// List all active (non-archived) entries
    fn list(&self) -> Result<Vec<Entry>>;

    /// Get the N most recent entries
    fn recent(&self, n: usize) -> Result<Vec<Entry>>;

    /// Archive an entry
    fn archive(&self, id: &str) -> Result<()>;

    /// Unarchive an entry
    fn unarchive(&self, id: &str) -> Result<()>;

    /// List all archived entries
    fn list_archived(&self) -> Result<Vec<Entry>>;

    /// List entries pending AI extraction
    fn list_pending(&self, limit: usize) -> Result<Vec<Entry>>;

    /// Mark an entry as extracted (no longer pending)
    fn mark_extracted(&self, id: &str) -> Result<()>;

    /// List entries in the in-context tier (always injected)
    fn list_pinned(&self) -> Result<Vec<Entry>>;

    /// List entries with positive feedback score, ordered by score descending
    fn list_helpful(&self, limit: usize) -> Result<Vec<Entry>>;

    /// List entries for a specific session
    fn list_by_session(&self, session_id: &str) -> Result<Vec<Entry>>;

    /// List learning entries that haven't been reviewed yet
    /// Used by the learning review hook to find entries needing analysis
    fn list_unreviewed_learnings(&self, limit: usize) -> Result<Vec<Entry>>;

    /// Mark an entry as reviewed (sets last_reviewed timestamp)
    fn mark_reviewed(&self, id: &str) -> Result<()>;

    /// List entries pending BM25/vector indexing (updated_at > indexed_at or indexed_at IS NULL)
    fn list_pending_index(&self, limit: usize) -> Result<Vec<Entry>>;

    /// Mark an entry as indexed (sets indexed_at to current timestamp)
    fn mark_indexed(&self, id: &str) -> Result<()>;

    /// Mark multiple entries as indexed in a single transaction
    fn mark_indexed_batch(&self, ids: &[&str]) -> Result<()>;

    /// Get the .cas directory path
    fn cas_dir(&self) -> &std::path::Path;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// Trait for rule storage operations
pub trait RuleStore: Send + Sync {
    /// Initialize the store
    fn init(&self) -> Result<()>;

    /// Generate a new unique rule ID
    fn generate_id(&self) -> Result<String>;

    /// Add a new rule
    fn add(&self, rule: &Rule) -> Result<()>;

    /// Get a rule by ID
    fn get(&self, id: &str) -> Result<Rule>;

    /// Update an existing rule
    fn update(&self, rule: &Rule) -> Result<()>;

    /// Delete a rule
    fn delete(&self, id: &str) -> Result<()>;

    /// List all rules
    fn list(&self) -> Result<Vec<Rule>>;

    /// List only proven rules (status = 'proven')
    fn list_proven(&self) -> Result<Vec<Rule>>;

    /// List critical rules (priority = 0, proven or draft)
    fn list_critical(&self) -> Result<Vec<Rule>>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// Trait for task storage operations
pub trait TaskStore: Send + Sync {
    /// Initialize the store (create tables, etc.)
    fn init(&self) -> Result<()>;

    /// Generate a new unique task ID (e.g., cas-a1b2)
    fn generate_id(&self) -> Result<String>;

    /// Add a new task
    fn add(&self, task: &Task) -> Result<()>;

    /// Atomically create a task and its initial dependencies.
    ///
    /// The default implementation is non-transactional and exists for compatibility with
    /// wrapper stores. Concrete stores with transactional support should override this.
    fn create_atomic(
        &self,
        task: &Task,
        blocked_by: &[String],
        epic_id: Option<&str>,
        created_by: Option<&str>,
    ) -> Result<()> { todo!() }

    /// Get a task by ID
    fn get(&self, id: &str) -> Result<Task>;

    /// Update an existing task
    fn update(&self, task: &Task) -> Result<()>;

    /// Delete a task
    fn delete(&self, id: &str) -> Result<()>;

    /// List tasks with optional status filter
    fn list(&self, status: Option<TaskStatus>) -> Result<Vec<Task>>;

    /// List tasks that are ready to work on (open, not blocked)
    fn list_ready(&self) -> Result<Vec<Task>>;

    /// List blocked tasks with their blockers
    fn list_blocked(&self) -> Result<Vec<(Task, Vec<Task>)>>;

    /// Close the store
    fn close(&self) -> Result<()>;

    // Dependency operations

    /// Add a dependency between two items
    fn add_dependency(&self, dep: &Dependency) -> Result<()>;

    /// Remove a dependency
    fn remove_dependency(&self, from_id: &str, to_id: &str) -> Result<()>;

    /// Get dependencies of a task (what it depends on)
    fn get_dependencies(&self, task_id: &str) -> Result<Vec<Dependency>>;

    /// Get dependents of a task (what depends on it)
    fn get_dependents(&self, task_id: &str) -> Result<Vec<Dependency>>;

    /// Get blocking dependencies (only type=blocks)
    fn get_blockers(&self, task_id: &str) -> Result<Vec<Task>>;

    /// Check if adding a dependency would create a cycle
    fn would_create_cycle(&self, from_id: &str, to_id: &str) -> Result<bool>;

    /// Get all dependencies in the system
    fn list_dependencies(&self, dep_type: Option<DependencyType>) -> Result<Vec<Dependency>>;

    /// Get all subtasks of a parent task (via Parent dependency)
    fn get_subtasks(&self, parent_id: &str) -> Result<Vec<Task>>;

    /// Get notes from sibling tasks (other subtasks of the same epic)
    /// Returns Vec<(task_id, title, notes)> for tasks with non-empty notes
    fn get_sibling_notes(
        &self,
        epic_id: &str,
        exclude_task_id: &str,
    ) -> Result<Vec<(String, String, String)>>;

    /// Get parent epic for a task (if it's a subtask)
    fn get_parent_epic(&self, task_id: &str) -> Result<Option<Task>>;
}

/// Trait for skill storage operations
pub trait SkillStore: Send + Sync {
    /// Initialize the store (create tables, etc.)
    fn init(&self) -> Result<()>;

    /// Generate a new unique skill ID (e.g., cas-sk01)
    fn generate_id(&self) -> Result<String>;

    /// Add a new skill
    fn add(&self, skill: &Skill) -> Result<()>;

    /// Get a skill by ID
    fn get(&self, id: &str) -> Result<Skill>;

    /// Update an existing skill
    fn update(&self, skill: &Skill) -> Result<()>;

    /// Delete a skill
    fn delete(&self, id: &str) -> Result<()>;

    /// List skills with optional status filter
    fn list(&self, status: Option<SkillStatus>) -> Result<Vec<Skill>>;

    /// List enabled skills
    fn list_enabled(&self) -> Result<Vec<Skill>>;

    /// Search skills by name or description
    fn search(&self, query: &str) -> Result<Vec<Skill>>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// Trait for entity (knowledge graph) storage operations
pub trait EntityStore: Send + Sync {
    /// Initialize the store (create tables, etc.)
    fn init(&self) -> Result<()>;

    // Entity operations

    /// Generate a new unique entity ID
    fn generate_entity_id(&self) -> Result<String>;

    /// Add a new entity
    fn add_entity(&self, entity: &Entity) -> Result<()>;

    /// Get an entity by ID
    fn get_entity(&self, id: &str) -> Result<Entity>;

    /// Get an entity by name (case-insensitive, including aliases)
    fn get_entity_by_name(
        &self,
        name: &str,
        entity_type: Option<EntityType>,
    ) -> Result<Option<Entity>>;

    /// Update an existing entity
    fn update_entity(&self, entity: &Entity) -> Result<()>;

    /// Delete an entity
    fn delete_entity(&self, id: &str) -> Result<()>;

    /// List entities with optional type filter
    fn list_entities(&self, entity_type: Option<EntityType>) -> Result<Vec<Entity>>;

    /// Search entities by name (substring match)
    fn search_entities(&self, query: &str, entity_type: Option<EntityType>) -> Result<Vec<Entity>>;

    // Relationship operations

    /// Generate a new unique relationship ID
    fn generate_relationship_id(&self) -> Result<String>;

    /// Add a new relationship
    fn add_relationship(&self, relationship: &Relationship) -> Result<()>;

    /// Get a relationship by ID
    fn get_relationship(&self, id: &str) -> Result<Relationship>;

    /// Get relationship between two entities (if exists)
    fn get_relationship_between(
        &self,
        source_id: &str,
        target_id: &str,
        relation_type: Option<RelationType>,
    ) -> Result<Option<Relationship>>;

    /// Update an existing relationship
    fn update_relationship(&self, relationship: &Relationship) -> Result<()>;

    /// Delete a relationship
    fn delete_relationship(&self, id: &str) -> Result<()>;

    /// List relationships with optional type filter
    fn list_relationships(&self, relation_type: Option<RelationType>) -> Result<Vec<Relationship>>;

    /// Get all relationships for an entity (as source or target)
    fn get_entity_relationships(&self, entity_id: &str) -> Result<Vec<Relationship>>;

    /// Get outgoing relationships (entity as source)
    fn get_outgoing_relationships(&self, entity_id: &str) -> Result<Vec<Relationship>>;

    /// Get incoming relationships (entity as target)
    fn get_incoming_relationships(&self, entity_id: &str) -> Result<Vec<Relationship>>;

    // Entity mention operations

    /// Add an entity mention (link entity to entry)
    fn add_mention(&self, mention: &EntityMention) -> Result<()>;

    /// Get mentions for an entity
    fn get_entity_mentions(&self, entity_id: &str) -> Result<Vec<EntityMention>>;

    /// Get mentions in an entry
    fn get_entry_mentions(&self, entry_id: &str) -> Result<Vec<EntityMention>>;

    /// Delete mentions for an entry (when entry is deleted/updated)
    fn delete_entry_mentions(&self, entry_id: &str) -> Result<()>;

    // Graph queries

    /// Get entities connected to a given entity (1-hop neighbors)
    fn get_connected_entities(&self, entity_id: &str) -> Result<Vec<(Entity, Relationship)>>;

    /// Get entries that mention an entity
    fn get_entity_entries(&self, entity_id: &str, limit: usize) -> Result<Vec<String>>;

    /// Close the store
    fn close(&self) -> Result<()>;
}
