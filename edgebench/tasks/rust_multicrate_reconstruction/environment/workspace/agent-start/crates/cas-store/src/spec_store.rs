//! SQLite-based spec storage

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, OptionalExtension, params};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::Result;
use crate::error::StoreError;
use cas_types::{Scope, Spec, SpecStatus, SpecType};

const SPEC_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS specs (
    id TEXT PRIMARY KEY,
    scope TEXT NOT NULL DEFAULT 'project',
    title TEXT NOT NULL,
    summary TEXT NOT NULL DEFAULT '',
    goals TEXT NOT NULL DEFAULT '[]',
    in_scope TEXT NOT NULL DEFAULT '[]',
    out_of_scope TEXT NOT NULL DEFAULT '[]',
    users TEXT NOT NULL DEFAULT '[]',
    technical_requirements TEXT NOT NULL DEFAULT '[]',
    acceptance_criteria TEXT NOT NULL DEFAULT '[]',
    design_notes TEXT NOT NULL DEFAULT '',
    additional_notes TEXT NOT NULL DEFAULT '',
    spec_type TEXT NOT NULL DEFAULT 'epic',
    status TEXT NOT NULL DEFAULT 'draft',
    version INTEGER NOT NULL DEFAULT 1,
    previous_version_id TEXT,
    task_id TEXT,
    source_ids TEXT NOT NULL DEFAULT '[]',
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    approved_at TEXT,
    approved_by TEXT,
    team_id TEXT,
    tags TEXT NOT NULL DEFAULT '[]'
);

CREATE INDEX IF NOT EXISTS idx_specs_status ON specs(status);
CREATE INDEX IF NOT EXISTS idx_specs_task_id ON specs(task_id);
"#;

/// Trait for spec storage operations
pub trait SpecStore: Send + Sync {
    /// Initialize the store (create tables, etc.)
    fn init(&self) -> Result<()>;

    /// Generate a new unique spec ID (e.g., spec-a1b2)
    fn generate_id(&self) -> Result<String>;

    /// Add a new spec
    fn add(&self, spec: &Spec) -> Result<()>;

    /// Get a spec by ID
    fn get(&self, id: &str) -> Result<Spec>;

    /// Update an existing spec
    fn update(&self, spec: &Spec) -> Result<()>;

    /// Delete a spec
    fn delete(&self, id: &str) -> Result<()>;

    /// List specs with optional status filter
    fn list(&self, status: Option<SpecStatus>) -> Result<Vec<Spec>>;

    /// List approved specs
    fn list_approved(&self) -> Result<Vec<Spec>>;

    /// Get specs for a specific task
    fn get_for_task(&self, task_id: &str) -> Result<Vec<Spec>>;

    /// Get all versions of a spec (by previous_version_id chain)
    fn get_versions(&self, spec_id: &str) -> Result<Vec<Spec>>;

    /// Search specs by title or summary
    fn search(&self, query: &str) -> Result<Vec<Spec>>;

    /// Close the store
    fn close(&self) -> Result<()>;
}

/// SQLite-based spec store
pub struct SqliteSpecStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSpecStore {
    /// Open or create a SQLite spec store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_datetime(s: &str) -> Option<DateTime<Utc>> { todo!() }

    fn parse_json_array(s: &str) -> Vec<String> { todo!() }

    fn array_to_json(arr: &[String]) -> String { todo!() }

    /// Generate a hash-based ID like spec-a1b2
    fn generate_hash_id(&self) -> Result<String> { todo!() }

    fn spec_from_row(row: &rusqlite::Row) -> rusqlite::Result<Spec> { todo!() }
}

impl SpecStore for SqliteSpecStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, spec: &Spec) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Spec> { todo!() }

    fn update(&self, spec: &Spec) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self, status: Option<SpecStatus>) -> Result<Vec<Spec>> { todo!() }

    fn list_approved(&self) -> Result<Vec<Spec>> { todo!() }

    fn get_for_task(&self, task_id: &str) -> Result<Vec<Spec>> { todo!() }

    fn get_versions(&self, spec_id: &str) -> Result<Vec<Spec>> { todo!() }

    fn search(&self, query: &str) -> Result<Vec<Spec>> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::spec_store::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SqliteSpecStore) {
        let temp = TempDir::new().unwrap();
        let store = SqliteSpecStore::open(temp.path()).unwrap();
        store.init().unwrap();
        (temp, store)
    }

    #[test]
    fn test_spec_crud() {
        let (_temp, store) = create_test_store();

        // Create spec
        let id = store.generate_id().unwrap();
        let mut spec = Spec::new(id.clone(), "Test Spec".to_string());
        spec.summary = "A test spec description".to_string();
        spec.spec_type = SpecType::Epic;
        spec.goals = vec!["Goal 1".to_string(), "Goal 2".to_string()];
        spec.tags = vec!["test".to_string()];
        store.add(&spec).unwrap();

        // Get spec
        let retrieved = store.get(&id).unwrap();
        assert_eq!(retrieved.title, "Test Spec");
        assert_eq!(retrieved.summary, "A test spec description");
        assert_eq!(retrieved.spec_type, SpecType::Epic);
        assert_eq!(retrieved.goals, vec!["Goal 1", "Goal 2"]);
        assert_eq!(retrieved.tags, vec!["test"]);

        // Update spec
        spec.summary = "Updated description".to_string();
        spec.status = SpecStatus::UnderReview;
        store.update(&spec).unwrap();

        let retrieved = store.get(&id).unwrap();
        assert_eq!(retrieved.summary, "Updated description");
        assert_eq!(retrieved.status, SpecStatus::UnderReview);

        // List specs
        let all_specs = store.list(None).unwrap();
        assert_eq!(all_specs.len(), 1);

        let under_review = store.list(Some(SpecStatus::UnderReview)).unwrap();
        assert_eq!(under_review.len(), 1);

        let approved = store.list_approved().unwrap();
        assert_eq!(approved.len(), 0);

        // Delete spec
        store.delete(&id).unwrap();
        assert!(store.get(&id).is_err());
    }

    #[test]
    fn test_spec_search() {
        let (_temp, store) = create_test_store();

        // Create specs
        let spec1 = Spec {
            id: store.generate_id().unwrap(),
            title: "Authentication System".to_string(),
            summary: "User login and session management".to_string(),
            tags: vec!["security".to_string(), "auth".to_string()],
            ..Default::default()
        };
        let spec2 = Spec {
            id: store.generate_id().unwrap(),
            title: "Database Migration".to_string(),
            summary: "PostgreSQL to SQLite migration".to_string(),
            tags: vec!["database".to_string()],
            ..Default::default()
        };
        store.add(&spec1).unwrap();
        store.add(&spec2).unwrap();

        // Search by title
        let results = store.search("Authentication").unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].title, "Authentication System");

        // Search by summary
        let results = store.search("PostgreSQL").unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].title, "Database Migration");

        // Search by tag
        let results = store.search("security").unwrap();
        assert_eq!(results.len(), 1);
    }

    #[test]
    fn test_spec_task_association() {
        let (_temp, store) = create_test_store();

        // Create specs with task association
        let spec1 = Spec {
            id: store.generate_id().unwrap(),
            title: "Epic Spec".to_string(),
            task_id: Some("task-001".to_string()),
            ..Default::default()
        };
        let spec2 = Spec {
            id: store.generate_id().unwrap(),
            title: "Another Spec".to_string(),
            task_id: Some("task-001".to_string()),
            ..Default::default()
        };
        let spec3 = Spec {
            id: store.generate_id().unwrap(),
            title: "Unrelated Spec".to_string(),
            task_id: Some("task-002".to_string()),
            ..Default::default()
        };
        store.add(&spec1).unwrap();
        store.add(&spec2).unwrap();
        store.add(&spec3).unwrap();

        // Get specs for task
        let task_specs = store.get_for_task("task-001").unwrap();
        assert_eq!(task_specs.len(), 2);

        let task_specs = store.get_for_task("task-002").unwrap();
        assert_eq!(task_specs.len(), 1);
        assert_eq!(task_specs[0].title, "Unrelated Spec");
    }

    #[test]
    fn test_spec_versions() {
        let (_temp, store) = create_test_store();

        // Create version chain: v1 -> v2 -> v3
        let id1 = store.generate_id().unwrap();
        let id2 = store.generate_id().unwrap();
        let id3 = store.generate_id().unwrap();

        let spec1 = Spec {
            id: id1.clone(),
            title: "Spec v1".to_string(),
            version: 1,
            previous_version_id: None,
            ..Default::default()
        };
        let spec2 = Spec {
            id: id2.clone(),
            title: "Spec v2".to_string(),
            version: 2,
            previous_version_id: Some(id1.clone()),
            ..Default::default()
        };
        let spec3 = Spec {
            id: id3.clone(),
            title: "Spec v3".to_string(),
            version: 3,
            previous_version_id: Some(id2.clone()),
            ..Default::default()
        };
        store.add(&spec1).unwrap();
        store.add(&spec2).unwrap();
        store.add(&spec3).unwrap();

        // Get versions from any point in chain
        let versions = store.get_versions(&id1).unwrap();
        assert_eq!(versions.len(), 3);
        assert_eq!(versions[0].version, 1);
        assert_eq!(versions[1].version, 2);
        assert_eq!(versions[2].version, 3);

        let versions = store.get_versions(&id3).unwrap();
        assert_eq!(versions.len(), 3);
    }

    #[test]
    fn test_spec_approved() {
        let (_temp, store) = create_test_store();

        let mut spec1 = Spec {
            id: store.generate_id().unwrap(),
            title: "Draft Spec".to_string(),
            status: SpecStatus::Draft,
            ..Default::default()
        };
        let spec2 = Spec {
            id: store.generate_id().unwrap(),
            title: "Approved Spec".to_string(),
            status: SpecStatus::Approved,
            approved_at: Some(Utc::now()),
            approved_by: Some("user-123".to_string()),
            ..Default::default()
        };
        store.add(&spec1).unwrap();
        store.add(&spec2).unwrap();

        // List approved only
        let approved = store.list_approved().unwrap();
        assert_eq!(approved.len(), 1);
        assert_eq!(approved[0].title, "Approved Spec");
        assert!(approved[0].approved_at.is_some());
        assert_eq!(approved[0].approved_by, Some("user-123".to_string()));

        // Approve the draft
        spec1.status = SpecStatus::Approved;
        spec1.approved_at = Some(Utc::now());
        store.update(&spec1).unwrap();

        let approved = store.list_approved().unwrap();
        assert_eq!(approved.len(), 2);
    }

}
