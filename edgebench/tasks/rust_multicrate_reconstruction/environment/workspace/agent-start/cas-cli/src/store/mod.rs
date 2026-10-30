//! Storage abstraction for CAS
//!
//! This module re-exports storage implementations from `cas-store` crate
//! and adds higher-level wrappers for notifications and syncing.

use std::path::{Path, PathBuf};

use crate::error::CasError;

/// Context for CAS operations, providing resolved paths and configuration.
///
/// CasContext eliminates the need for global state lookups (like `find_cas_root()`)
/// by resolving the CAS root once at entry points and passing it through.
/// This enables:
/// - Deterministic behavior in tests (inject specific paths)
/// - Parallel test execution without environment variable conflicts
/// - Clear dependency injection for better testability
#[derive(Debug, Clone)]
pub struct CasContext {
    /// Path to the .cas directory
    pub cas_root: PathBuf,
}

impl CasContext {
    /// Create a new CasContext with an explicit cas_root path.
    ///
    /// Use this for tests or when you have a known path.
    pub fn new(cas_root: PathBuf) -> Self { todo!() }

    /// Create CasContext by finding .cas from current working directory.
    ///
    /// This is the standard entry point for CLI commands.
    pub fn from_cwd() -> std::result::Result<Self, CasError> { todo!() }

    /// Create CasContext by finding .cas from a specific path.
    ///
    /// Useful when you have a working directory path (e.g., from HookInput.cwd).
    pub fn from_path(path: &Path) -> std::result::Result<Self, CasError> { todo!() }

    /// Get reference to the cas_root path.
    pub fn root(&self) -> &Path { todo!() }
}

// Re-export everything from cas-store
pub use cas_store::{
    AgentStore,
    CodeStore,
    CommitLinkStore,
    EntityStore,
    EventStore,
    FileChangeStore,
    LayeredEntryStore,
    LayeredRuleStore,
    LayeredSkillStore,
    LeaseHistoryEntry,
    LoopStore,
    MarkdownRuleStore,
    // Other implementations
    MarkdownStore,
    NotificationPriority,
    PromptQueueStore,
    PromptStore,
    // Prompt queue types
    QueuedPrompt,
    // Recording store for terminal recordings
    RecordingStore,
    // Reminder store for supervisor reminders
    Reminder,
    ReminderStatus,
    ReminderStore,
    ReminderTriggerType,
    Result,
    RuleStore,
    SkillStore,
    // Spawn queue types
    SpawnAction,
    SpawnQueueStore,
    SpawnRequest,
    SpecStore,
    SqliteAgentStore,
    SqliteCodeStore,
    SqliteCommitLinkStore,
    SqliteEntityStore,
    SqliteEventStore,
    SqliteFileChangeStore,
    SqliteLoopStore,
    SqlitePromptQueueStore,
    SqlitePromptStore,
    SqliteRecordingStore,
    SqliteReminderStore,
    SqliteRuleStore,
    SqliteSkillStore,
    SqliteSpawnQueueStore,
    SqliteSpecStore,
    // SQLite implementations
    SqliteStore,
    SqliteSupervisorQueueStore,
    SqliteTaskStore,
    SqliteVerificationStore,
    SqliteWorktreeStore,
    // Traits
    Store,
    // Error types
    StoreError,
    // Supervisor queue types
    SupervisorNotification,
    SupervisorQueueStore,
    TaskStore,
    VerificationStore,
    WorktreeStore,
    // Commit link store helpers
    add_commit_link_with_conn,
    // File change store helpers
    add_file_change_with_conn,
    // Prompt store helpers
    add_prompt_with_conn,
    get_current_prompt_for_session,
    layered,
    // Modules
    markdown,
};

// Local modules (not in cas-store)
pub mod detect;
mod notifying_entry;
mod notifying_rule;
mod notifying_skill;
mod notifying_task;
mod syncing;
mod syncing_entry;
mod syncing_skill;
mod syncing_task;

// Re-export local wrappers
pub use detect::{
    StoreType, detect_store_type, find_cas_root, find_cas_root_from, has_project_cas, init_cas_dir,
    open_agent_store, open_code_store, open_commit_link_store, open_entity_store, open_event_store,
    open_file_change_store, open_loop_store, open_prompt_queue_store, open_prompt_store,
    open_recording_store, open_reminder_store, open_rule_store, open_skill_store,
    open_spawn_queue_store, open_spec_store, open_store, open_supervisor_queue_store,
    open_task_store, open_verification_store, open_worktree_store,
};
pub use notifying_entry::NotifyingEntryStore;
pub use notifying_rule::NotifyingRuleStore;
pub use notifying_skill::NotifyingSkillStore;
pub use notifying_task::NotifyingTaskStore;
pub use syncing::SyncingRuleStore;
pub use syncing_entry::SyncingEntryStore;
pub use syncing_skill::SyncingSkillStore;
pub use syncing_task::SyncingTaskStore;

// Mock stores for testing
#[cfg(test)]
pub mod mock;
