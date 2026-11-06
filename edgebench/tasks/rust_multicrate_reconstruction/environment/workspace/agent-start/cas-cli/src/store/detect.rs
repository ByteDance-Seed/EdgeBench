//! Store detection and factory functions
//!
//! CAS uses project-scoped storage in `./.cas/` directories.
//! Each project requires `cas init` before use.

use std::path::{Path, PathBuf};
use std::sync::Arc;

use super::{
    AgentStore, CodeStore, CommitLinkStore, EntityStore, EventStore, FileChangeStore, LoopStore,
    MarkdownRuleStore, MarkdownStore, NotifyingEntryStore, NotifyingRuleStore, NotifyingSkillStore,
    NotifyingTaskStore, PromptQueueStore, PromptStore, RecordingStore, ReminderStore, RuleStore,
    SkillStore, SpawnQueueStore, SpecStore, SqliteAgentStore, SqliteCodeStore,
    SqliteCommitLinkStore, SqliteEntityStore, SqliteEventStore, SqliteFileChangeStore,
    SqliteLoopStore, SqlitePromptQueueStore, SqlitePromptStore, SqliteRecordingStore,
    SqliteReminderStore, SqliteRuleStore, SqliteSkillStore, SqliteSpawnQueueStore, SqliteSpecStore,
    SqliteStore, SqliteSupervisorQueueStore, SqliteTaskStore, SqliteVerificationStore,
    SqliteWorktreeStore, Store, SupervisorQueueStore, TaskStore, VerificationStore, WorktreeStore,
};
use crate::cloud::{CloudConfig, SyncQueue};
use crate::config::Config;
use crate::error::CasError;
use crate::migration::run_migrations;
use crate::notifications::has_notifier;
use crate::store::{SyncingEntryStore, SyncingRuleStore, SyncingSkillStore, SyncingTaskStore};

/// Result type for detect functions (uses CasError for richer error handling)
type Result<T> = std::result::Result<T, CasError>;

/// Type of storage backend
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum StoreType {
    /// Modern SQLite storage
    Sqlite,
    /// Legacy markdown files
    Markdown,
}

/// Check if a project store exists in the current directory tree
pub fn has_project_cas() -> bool { todo!() }

/// Find the .cas directory by searching up the directory tree
///
/// Priority order:
/// 1. CAS_ROOT environment variable (if set and valid)
/// 2. Git worktree detection (uses main repo's .cas)
/// 3. Walk up directory tree from cwd
pub fn find_cas_root() -> Result<PathBuf> { todo!() }

/// Find the .cas directory starting from a specific path
///
/// This function handles git worktrees: if we're in a worktree, it looks
/// for .cas in the main repository first, before falling back to walking
/// up the directory tree.
pub fn find_cas_root_from(start: &Path) -> Result<PathBuf> { todo!() }

/// Check if we're in a git worktree and return the main repository path.
///
/// Git worktrees have a `.git` file (not directory) containing:
/// ```text
/// gitdir: /path/to/main/.git/worktrees/<worktree-name>
/// ```
///
/// We parse this to find the main repository's path.
fn find_main_repo_from_worktree(start: &Path) -> Option<PathBuf> { todo!() }

/// Detect the storage type for a .cas directory
pub fn detect_store_type(cas_dir: &Path) -> StoreType { todo!() }

/// Open the appropriate store based on what exists
pub fn open_store(cas_dir: &Path) -> Result<Arc<dyn Store>> { todo!() }

/// Open the task store
pub fn open_task_store(cas_dir: &Path) -> Result<Arc<dyn TaskStore>> { todo!() }

/// Open the skill store
pub fn open_skill_store(cas_dir: &Path) -> Result<Arc<dyn SkillStore>> { todo!() }

/// Open the entity store for knowledge graph
pub fn open_entity_store(cas_dir: &Path) -> Result<Arc<dyn EntityStore>> { todo!() }

/// Open the agent store for multi-agent coordination
pub fn open_agent_store(cas_dir: &Path) -> Result<Arc<dyn AgentStore>> { todo!() }

/// Open the loop store
pub fn open_loop_store(cas_dir: &Path) -> Result<Arc<dyn LoopStore>> { todo!() }

/// Open the verification store for task quality gates
pub fn open_verification_store(cas_dir: &Path) -> Result<Arc<dyn VerificationStore>> { todo!() }

/// Open the worktree store for tracking git worktrees
pub fn open_worktree_store(cas_dir: &Path) -> Result<Arc<dyn WorktreeStore>> { todo!() }

/// Open the recording store for terminal recording metadata
pub fn open_recording_store(cas_dir: &Path) -> Result<Arc<dyn RecordingStore>> { todo!() }

/// Open the code store for indexed source code
pub fn open_code_store(cas_dir: &Path) -> Result<Arc<dyn CodeStore>> { todo!() }

/// Open the supervisor queue store for factory session Director → Supervisor communication
pub fn open_supervisor_queue_store(cas_dir: &Path) -> Result<Arc<dyn SupervisorQueueStore>> { todo!() }

/// Open the prompt queue store (for supervisor → worker communication)
pub fn open_prompt_queue_store(cas_dir: &Path) -> Result<Arc<dyn PromptQueueStore>> { todo!() }

/// Open the reminder store (for supervisor "Remind Me" feature)
pub fn open_reminder_store(cas_dir: &Path) -> Result<Arc<dyn ReminderStore>> { todo!() }

/// Open the spawn queue store (for dynamic worker lifecycle management)
pub fn open_spawn_queue_store(cas_dir: &Path) -> Result<Arc<dyn SpawnQueueStore>> { todo!() }

/// Open the prompt store (for code attribution / git blame)
pub fn open_prompt_store(cas_dir: &Path) -> Result<Arc<dyn PromptStore>> { todo!() }

/// Open the file change store (for code attribution / git blame)
pub fn open_file_change_store(cas_dir: &Path) -> Result<Arc<dyn FileChangeStore>> { todo!() }

/// Open the commit link store (for code attribution / git blame)
pub fn open_commit_link_store(cas_dir: &Path) -> Result<Arc<dyn CommitLinkStore>> { todo!() }

/// Open the event store (for activity tracking)
pub fn open_event_store(cas_dir: &Path) -> Result<Arc<dyn EventStore>> { todo!() }

/// Open the spec store
pub fn open_spec_store(cas_dir: &Path) -> Result<Arc<dyn SpecStore>> { todo!() }

/// Open the appropriate rule store
pub fn open_rule_store(cas_dir: &Path) -> Result<Arc<dyn RuleStore>> { todo!() }

/// Initialize a new .cas directory
pub fn init_cas_dir(path: &Path) -> Result<PathBuf> { todo!() }

#[cfg(test)]
mod tests {
    use crate::store::detect::*;
    use tempfile::TempDir;

    #[test]
    fn test_init_cas_dir() {
        let temp = TempDir::new().unwrap();
        let cas_dir = init_cas_dir(temp.path()).unwrap();

        assert!(cas_dir.exists());
        assert!(cas_dir.join("cas.db").exists());
        // Config is now saved as TOML (preferred format)
        assert!(cas_dir.join("config.toml").exists());
    }

    #[test]
    fn test_find_cas_root() {
        let _guard = ENV_MUTEX.lock().unwrap();
        let original_cas_root = std::env::var("CAS_ROOT").ok();
        unsafe { std::env::remove_var("CAS_ROOT") };

        let temp = TempDir::new().unwrap();
        init_cas_dir(temp.path()).unwrap();

        // Create a subdirectory
        let subdir = temp.path().join("subdir/nested");
        std::fs::create_dir_all(&subdir).unwrap();

        // Should find .cas from subdirectory
        let found = find_cas_root_from(&subdir).unwrap();
        assert_eq!(found, temp.path().join(".cas"));

        match original_cas_root {
            Some(val) => unsafe { std::env::set_var("CAS_ROOT", val) },
            None => unsafe { std::env::remove_var("CAS_ROOT") },
        }
    }

    #[test]
    fn test_detect_store_type() {
        let temp = TempDir::new().unwrap();
        let cas_dir = temp.path().join(".cas");
        std::fs::create_dir_all(&cas_dir).unwrap();

        // Default should be SQLite
        assert_eq!(detect_store_type(&cas_dir), StoreType::Sqlite);

        // Create entries dir to simulate markdown store
        std::fs::create_dir_all(cas_dir.join("entries")).unwrap();
        assert_eq!(detect_store_type(&cas_dir), StoreType::Markdown);

        // SQLite takes precedence
        std::fs::write(cas_dir.join("cas.db"), "").unwrap();
        assert_eq!(detect_store_type(&cas_dir), StoreType::Sqlite);
    }

    // Mutex for tests that modify global state (env vars, CWD).
    // These tests are #[ignore]d by default - run with: cargo test -- --ignored
    static ENV_MUTEX: std::sync::Mutex<()> = std::sync::Mutex::new(());

    #[test]
    #[ignore] // Uses global state (CWD, env vars) - run with: cargo test -- --ignored
    fn test_has_project_cas() {
        let _guard = ENV_MUTEX.lock().unwrap();

        let temp = TempDir::new().unwrap();
        // Canonicalize to handle macOS /var -> /private/var symlinks
        let temp_path = temp
            .path()
            .canonicalize()
            .expect("Failed to canonicalize temp path");

        // Save original env var and CWD
        let original_cas_root = std::env::var("CAS_ROOT").ok();
        let original_cwd = std::env::current_dir().ok();

        // Clear CAS_ROOT so find_cas_root uses CWD-based detection
        unsafe { std::env::remove_var("CAS_ROOT") };
        std::env::set_current_dir(&temp_path).expect("Failed to change to temp dir");

        // In temp dir with no .cas, should return false
        assert!(!has_project_cas(), "Expected no .cas in empty temp dir");

        // After init, should return true
        init_cas_dir(&temp_path).unwrap();
        assert!(has_project_cas(), "Expected .cas to be found after init");

        // Restore original state
        if let Some(cwd) = original_cwd {
            let _ = std::env::set_current_dir(cwd);
        }
        match original_cas_root {
            Some(val) => unsafe { std::env::set_var("CAS_ROOT", val) },
            None => unsafe { std::env::remove_var("CAS_ROOT") },
        }
    }


    #[test]
    fn test_find_main_repo_from_worktree() {
        let temp = TempDir::new().unwrap();
        let main_repo = temp.path().join("main_repo");
        let worktree = temp.path().join("worktrees/wt1");

        // Create main repo's .git directory and worktrees subdir
        let git_dir = main_repo.join(".git");
        std::fs::create_dir_all(&git_dir).unwrap();
        let worktree_git_data = git_dir.join("worktrees/wt1");
        std::fs::create_dir_all(&worktree_git_data).unwrap();

        // Create worktree directory with .git file
        std::fs::create_dir_all(&worktree).unwrap();
        let git_file_content = format!("gitdir: {}", worktree_git_data.display());
        std::fs::write(worktree.join(".git"), git_file_content).unwrap();

        // Should find main repo from worktree
        let found = find_main_repo_from_worktree(&worktree);
        assert_eq!(found, Some(main_repo));

        // Should return None for regular git repo
        let regular_repo = temp.path().join("regular_repo");
        std::fs::create_dir_all(regular_repo.join(".git")).unwrap();
        let found = find_main_repo_from_worktree(&regular_repo);
        assert!(found.is_none());

        // Should return None for non-git directory
        let non_git = temp.path().join("non_git");
        std::fs::create_dir_all(&non_git).unwrap();
        let found = find_main_repo_from_worktree(&non_git);
        assert!(found.is_none());
    }

    #[test]
    #[ignore] // Uses global state (CAS_ROOT env var) - run with: cargo test -- --ignored
    fn test_cas_root_env_var() {
        let _guard = ENV_MUTEX.lock().unwrap();

        let temp = TempDir::new().unwrap();
        let cas_dir = temp.path().join(".cas");
        std::fs::create_dir_all(&cas_dir).unwrap();

        // Save original env var
        let original = std::env::var("CAS_ROOT").ok();

        // Set CAS_ROOT to temp cas dir
        unsafe { std::env::set_var("CAS_ROOT", &cas_dir) };

        // find_cas_root should use CAS_ROOT
        let found = find_cas_root().unwrap();
        assert_eq!(found, cas_dir);

        // Restore original
        match original {
            Some(val) => unsafe { std::env::set_var("CAS_ROOT", val) },
            None => unsafe { std::env::remove_var("CAS_ROOT") },
        }
    }

}
