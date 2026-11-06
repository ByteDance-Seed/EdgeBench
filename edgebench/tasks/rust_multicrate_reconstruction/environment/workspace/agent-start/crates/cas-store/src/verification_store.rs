//! Verification storage for task quality gates
//!
//! Stores verification results in SQLite. Verifications are created when
//! attempting to close a task, with a Haiku subagent reviewing the work.

use chrono::{DateTime, Utc};
use rusqlite::{Connection, OptionalExtension, params};
use std::path::Path;
use std::str::FromStr;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::error::StoreError;
use cas_types::{
    IssueSeverity, Verification, VerificationIssue, VerificationStatus, VerificationType,
};

// Helper to convert lock errors
fn lock_err<T>(_: std::sync::PoisonError<T>) -> StoreError { todo!() }

const VERIFICATION_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS verifications (
    id TEXT PRIMARY KEY,
    task_id TEXT NOT NULL,
    agent_id TEXT,
    verification_type TEXT NOT NULL DEFAULT 'task',
    status TEXT NOT NULL DEFAULT 'approved',
    confidence REAL,
    summary TEXT NOT NULL DEFAULT '',
    files_reviewed TEXT NOT NULL DEFAULT '[]',
    duration_ms INTEGER,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS verification_issues (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    verification_id TEXT NOT NULL,
    file TEXT NOT NULL,
    line INTEGER,
    severity TEXT NOT NULL DEFAULT 'blocking',
    category TEXT NOT NULL,
    code TEXT NOT NULL DEFAULT '',
    problem TEXT NOT NULL,
    suggestion TEXT,
    FOREIGN KEY (verification_id) REFERENCES verifications(id) ON DELETE CASCADE
);

CREATE INDEX IF NOT EXISTS idx_verifications_task ON verifications(task_id);
CREATE INDEX IF NOT EXISTS idx_verifications_status ON verifications(status);
CREATE INDEX IF NOT EXISTS idx_verifications_created ON verifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_verification_issues_verification ON verification_issues(verification_id);
"#;

/// Trait for verification storage operations
pub trait VerificationStore: Send + Sync {
    /// Initialize the store (create tables)
    fn init(&self) -> Result<()>;

    /// Generate a new unique verification ID (e.g., ver-a1b2)
    fn generate_id(&self) -> Result<String>;

    /// Add a new verification with its issues
    fn add(&self, verification: &Verification) -> Result<()>;

    /// Get a verification by ID (includes issues)
    fn get(&self, id: &str) -> Result<Verification>;

    /// Update an existing verification
    fn update(&self, verification: &Verification) -> Result<()>;

    /// Delete a verification and its issues
    fn delete(&self, id: &str) -> Result<()>;

    /// Get verifications for a task
    fn get_for_task(&self, task_id: &str) -> Result<Vec<Verification>>;

    /// Get the most recent verification for a task
    fn get_latest_for_task(&self, task_id: &str) -> Result<Option<Verification>>;

    /// Get the most recent verification for a task of a specific type
    fn get_latest_for_task_by_type(
        &self,
        task_id: &str,
        verification_type: VerificationType,
    ) -> Result<Option<Verification>>;

    /// List recent verifications
    fn list_recent(&self, limit: usize) -> Result<Vec<Verification>>;

    /// List verifications by status
    fn list_by_status(&self, status: VerificationStatus) -> Result<Vec<Verification>>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite-based verification store
pub struct SqliteVerificationStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteVerificationStore {
    /// Open or create a SQLite verification store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_verification(row: &rusqlite::Row) -> rusqlite::Result<Verification> { todo!() }

    fn load_issues(
        &self,
        conn: &Connection,
        verification_id: &str,
    ) -> Result<Vec<VerificationIssue>> { todo!() }

    fn save_issues(&self, conn: &Connection, verification: &Verification) -> Result<()> { todo!() }
}

/// Add a verification record using an existing connection (for cross-store transactions).
///
/// Caller is responsible for managing the transaction. Does not save issues -
/// call `save_verification_issues_with_conn` separately.
pub fn add_verification_with_conn(conn: &Connection, verification: &Verification) -> Result<()> { todo!() }

/// Save verification issues using an existing connection (for cross-store transactions).
pub fn save_verification_issues_with_conn(
    conn: &Connection,
    verification: &Verification,
) -> Result<()> { todo!() }

impl VerificationStore for SqliteVerificationStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, verification: &Verification) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Verification> { todo!() }

    fn update(&self, verification: &Verification) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn get_for_task(&self, task_id: &str) -> Result<Vec<Verification>> { todo!() }

    fn get_latest_for_task(&self, task_id: &str) -> Result<Option<Verification>> { todo!() }

    fn get_latest_for_task_by_type(
        &self,
        task_id: &str,
        verification_type: VerificationType,
    ) -> Result<Option<Verification>> { todo!() }

    fn list_recent(&self, limit: usize) -> Result<Vec<Verification>> { todo!() }

    fn list_by_status(&self, status: VerificationStatus) -> Result<Vec<Verification>> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::verification_store::*;
    use tempfile::TempDir;

    fn create_test_store() -> (SqliteVerificationStore, TempDir) {
        let dir = TempDir::new().unwrap();
        let store = SqliteVerificationStore::open(dir.path()).unwrap();
        (store, dir)
    }


    #[test]
    fn test_verification_with_issues() {
        let (store, _dir) = create_test_store();

        let issues = vec![
            VerificationIssue::blocking(
                "src/main.rs".to_string(),
                Some(42),
                "todo_comment".to_string(),
                "// TODO: implement".to_string(),
                "TODO comment found".to_string(),
                Some("Implement the function".to_string()),
            ),
            VerificationIssue::warning(
                "src/lib.rs".to_string(),
                "hardcoded_value".to_string(),
                "Magic number detected".to_string(),
            ),
        ];

        let verification = Verification::rejected(
            "ver-test".to_string(),
            "cas-1234".to_string(),
            "Found incomplete work".to_string(),
            issues,
        );

        store.add(&verification).unwrap();

        let retrieved = store.get("ver-test").unwrap();
        assert!(retrieved.is_rejected());
        assert_eq!(retrieved.issues.len(), 2);
        assert_eq!(retrieved.blocking_count(), 1);
        assert_eq!(retrieved.warning_count(), 1);

        let first_issue = &retrieved.issues[0];
        assert_eq!(first_issue.file, "src/main.rs");
        assert_eq!(first_issue.line, Some(42));
        assert!(first_issue.is_blocking());
    }

    #[test]
    fn test_update_verification() {
        let (store, _dir) = create_test_store();

        let mut verification = Verification::new("ver-test".to_string(), "cas-1234".to_string());
        store.add(&verification).unwrap();

        // Update with new status and issues
        verification.status = VerificationStatus::Rejected;
        verification.summary = "Found issues".to_string();
        verification.issues.push(VerificationIssue::new(
            "src/api.rs".to_string(),
            "stub".to_string(),
            "Stub implementation".to_string(),
        ));

        store.update(&verification).unwrap();

        let retrieved = store.get("ver-test").unwrap();
        assert!(retrieved.is_rejected());
        assert_eq!(retrieved.issues.len(), 1);
    }

    #[test]
    fn test_get_for_task() {
        let (store, _dir) = create_test_store();

        // Add multiple verifications for same task
        for i in 0..3 {
            let verification = Verification::approved(
                format!("ver-{i}"),
                "cas-1234".to_string(),
                format!("Attempt {i}"),
            );
            store.add(&verification).unwrap();
        }

        // Add one for different task
        let other = Verification::approved(
            "ver-other".to_string(),
            "cas-5678".to_string(),
            "Other task".to_string(),
        );
        store.add(&other).unwrap();

        let task_verifications = store.get_for_task("cas-1234").unwrap();
        assert_eq!(task_verifications.len(), 3);
    }

    #[test]
    fn test_get_latest_for_task() {
        let (store, _dir) = create_test_store();

        // No verifications initially
        let latest = store.get_latest_for_task("cas-1234").unwrap();
        assert!(latest.is_none());

        // Add verifications
        let v1 = Verification::rejected(
            "ver-1".to_string(),
            "cas-1234".to_string(),
            "First attempt".to_string(),
            vec![],
        );
        store.add(&v1).unwrap();

        let v2 = Verification::approved(
            "ver-2".to_string(),
            "cas-1234".to_string(),
            "Second attempt".to_string(),
        );
        store.add(&v2).unwrap();

        let latest = store.get_latest_for_task("cas-1234").unwrap();
        assert!(latest.is_some());
        assert_eq!(latest.unwrap().id, "ver-2");
    }

    #[test]
    fn test_get_latest_for_task_by_type() {
        let (store, _dir) = create_test_store();

        // No verifications initially
        let latest = store
            .get_latest_for_task_by_type("cas-1234", VerificationType::Task)
            .unwrap();
        assert!(latest.is_none());

        let latest = store
            .get_latest_for_task_by_type("cas-1234", VerificationType::Epic)
            .unwrap();
        assert!(latest.is_none());

        // Add a task-type verification
        let mut v1 = Verification::approved(
            "ver-task-1".to_string(),
            "cas-1234".to_string(),
            "Task verification".to_string(),
        );
        v1.verification_type = VerificationType::Task;
        store.add(&v1).unwrap();

        // Add an epic-type verification
        let mut v2 = Verification::rejected(
            "ver-epic-1".to_string(),
            "cas-1234".to_string(),
            "Epic verification".to_string(),
            vec![],
        );
        v2.verification_type = VerificationType::Epic;
        store.add(&v2).unwrap();

        // Add another task-type verification (newer)
        let mut v3 = Verification::approved(
            "ver-task-2".to_string(),
            "cas-1234".to_string(),
            "Second task verification".to_string(),
        );
        v3.verification_type = VerificationType::Task;
        store.add(&v3).unwrap();

        // Get latest task verification - should be v3
        let latest_task = store
            .get_latest_for_task_by_type("cas-1234", VerificationType::Task)
            .unwrap();
        assert!(latest_task.is_some());
        assert_eq!(latest_task.unwrap().id, "ver-task-2");

        // Get latest epic verification - should be v2
        let latest_epic = store
            .get_latest_for_task_by_type("cas-1234", VerificationType::Epic)
            .unwrap();
        assert!(latest_epic.is_some());
        assert_eq!(latest_epic.unwrap().id, "ver-epic-1");

        // Different task has no verifications
        let latest_other = store
            .get_latest_for_task_by_type("cas-5678", VerificationType::Task)
            .unwrap();
        assert!(latest_other.is_none());
    }

    #[test]
    fn test_list_by_status() {
        let (store, _dir) = create_test_store();

        let approved = Verification::approved(
            "ver-approved".to_string(),
            "cas-1".to_string(),
            "Good".to_string(),
        );
        store.add(&approved).unwrap();

        let rejected = Verification::rejected(
            "ver-rejected".to_string(),
            "cas-2".to_string(),
            "Bad".to_string(),
            vec![],
        );
        store.add(&rejected).unwrap();

        let approved_list = store.list_by_status(VerificationStatus::Approved).unwrap();
        assert_eq!(approved_list.len(), 1);
        assert_eq!(approved_list[0].id, "ver-approved");

        let rejected_list = store.list_by_status(VerificationStatus::Rejected).unwrap();
        assert_eq!(rejected_list.len(), 1);
        assert_eq!(rejected_list[0].id, "ver-rejected");
    }

    #[test]
    fn test_delete_verification() {
        let (store, _dir) = create_test_store();

        let verification = Verification::approved(
            "ver-test".to_string(),
            "cas-1234".to_string(),
            "Good".to_string(),
        );
        store.add(&verification).unwrap();

        store.delete("ver-test").unwrap();

        let result = store.get("ver-test");
        assert!(result.is_err());
    }

    #[test]
    fn test_generate_id() {
        let (store, _dir) = create_test_store();

        let id = store.generate_id().unwrap();
        assert!(id.starts_with("ver-"));
        assert!(id.len() > 4);
    }

    #[test]
    fn test_list_recent() {
        let (store, _dir) = create_test_store();

        for i in 0..5 {
            let verification =
                Verification::approved(format!("ver-{i}"), format!("cas-{i}"), format!("Task {i}"));
            store.add(&verification).unwrap();
        }

        let recent = store.list_recent(3).unwrap();
        assert_eq!(recent.len(), 3);
    }

    #[test]
    fn test_files_reviewed_persistence() {
        let (store, _dir) = create_test_store();

        let mut verification = Verification::approved(
            "ver-test".to_string(),
            "cas-1234".to_string(),
            "Done".to_string(),
        );
        verification.add_file_reviewed("src/main.rs".to_string());
        verification.add_file_reviewed("src/lib.rs".to_string());
        verification.add_file_reviewed("tests/test.rs".to_string());

        store.add(&verification).unwrap();

        let retrieved = store.get("ver-test").unwrap();
        assert_eq!(retrieved.files_reviewed.len(), 3);
        assert!(
            retrieved
                .files_reviewed
                .contains(&"src/main.rs".to_string())
        );
    }

}
