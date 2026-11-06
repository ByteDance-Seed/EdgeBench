//! CAS spec syncing
//!
//! Syncs approved specs to .cas/specs/ as markdown files.

use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};

use crate::error::CoreError;
use cas_types::{Spec, SpecStatus};

/// Syncs CAS specs to filesystem
pub struct SpecSyncer {
    target_dir: PathBuf,
}

/// Report of sync operation
#[derive(Debug, Default)]
pub struct SpecSyncReport {
    /// Number of specs synced
    pub synced: usize,
    /// Number of stale files removed
    pub removed: usize,
    /// Specs that were synced
    pub synced_ids: Vec<String>,
    /// Files that were removed
    pub removed_ids: Vec<String>,
}

impl SpecSyncer {
    /// Create a new syncer
    pub fn new(target_dir: PathBuf) -> Self { todo!() }

    /// Create a syncer with default settings
    pub fn with_defaults(cas_dir: &Path) -> Self { todo!() }

    /// Check if a spec should be synced (approved status)
    pub fn is_approved(&self, spec: &Spec) -> bool { todo!() }

    /// Generate the markdown content for a spec
    pub fn generate_spec_md(&self, spec: &Spec) -> String { todo!() }

    /// Sync a single spec to target directory
    ///
    /// Returns true if the spec was synced, false if it wasn't approved
    pub fn sync_spec(&self, spec: &Spec) -> Result<bool, CoreError> { todo!() }

    /// Sync all approved specs and remove stale files
    pub fn sync_all(&self, specs: &[Spec]) -> Result<SpecSyncReport, CoreError> { todo!() }

    /// Remove a specific spec file
    pub fn remove_spec(&self, spec_id: &str) -> Result<(), CoreError> { todo!() }

    /// Get the target directory path
    pub fn target_dir(&self) -> &Path { todo!() }

    /// List all synced spec files
    pub fn list_synced(&self) -> Result<Vec<String>, CoreError> { todo!() }
}

/// Escape a string for YAML
fn escape_yaml(s: &str) -> String { todo!() }

#[cfg(test)]
mod tests {
    use crate::sync::specs::*;
    use chrono::Utc;
    use tempfile::TempDir;

    fn create_test_spec(id: &str, title: &str, approved: bool) -> Spec {
        let mut spec = Spec::new(id.to_string(), title.to_string());
        if approved {
            spec.status = SpecStatus::Approved;
            spec.approved_at = Some(Utc::now());
            spec.approved_by = Some("test-user".to_string());
        }
        spec
    }



    #[test]
    fn test_sync_spec_with_content() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("specs");
        let syncer = SpecSyncer::new(target.clone());

        let mut spec = create_test_spec("spec-002", "Full Spec", true);
        spec.summary = "This is a test summary.".to_string();
        spec.goals = vec!["Goal 1".to_string(), "Goal 2".to_string()];
        spec.in_scope = vec!["Feature A".to_string()];
        spec.out_of_scope = vec!["Feature B".to_string()];
        spec.users = vec!["Developers".to_string()];
        spec.technical_requirements = vec!["Rust 1.70+".to_string()];
        spec.acceptance_criteria = vec!["Tests pass".to_string()];
        spec.design_notes = "Use builder pattern.".to_string();
        spec.tags = vec!["test".to_string(), "example".to_string()];

        syncer.sync_spec(&spec).unwrap();

        let content = fs::read_to_string(target.join("spec-002.md")).unwrap();
        assert!(content.contains("## Summary"));
        assert!(content.contains("This is a test summary."));
        assert!(content.contains("## Goals"));
        assert!(content.contains("- Goal 1"));
        assert!(content.contains("## Scope"));
        assert!(content.contains("### In Scope"));
        assert!(content.contains("- Feature A"));
        assert!(content.contains("### Out of Scope"));
        assert!(content.contains("- Feature B"));
        assert!(content.contains("## Users"));
        assert!(content.contains("- Developers"));
        assert!(content.contains("## Technical Requirements"));
        assert!(content.contains("- Rust 1.70+"));
        assert!(content.contains("## Acceptance Criteria"));
        assert!(content.contains("- Tests pass"));
        assert!(content.contains("## Design Notes"));
        assert!(content.contains("Use builder pattern."));
        assert!(content.contains("tags:"));
        assert!(content.contains("  - test"));
    }

    #[test]
    fn test_sync_all() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("specs");
        let syncer = SpecSyncer::new(target.clone());

        let spec1 = create_test_spec("spec-001", "Approved Spec", true);
        let spec2 = create_test_spec("spec-002", "Draft Spec", false);

        let specs = vec![spec1, spec2];
        let report = syncer.sync_all(&specs).unwrap();

        assert_eq!(report.synced, 1);
        assert!(target.join("spec-001.md").exists());
        assert!(!target.join("spec-002.md").exists());
    }

    #[test]
    fn test_remove_stale() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("specs");
        let syncer = SpecSyncer::new(target.clone());

        // Create a stale spec file
        fs::create_dir_all(&target).unwrap();
        fs::write(target.join("spec-stale.md"), "stale content").unwrap();

        // Sync with no specs
        let report = syncer.sync_all(&[]).unwrap();

        assert_eq!(report.removed, 1);
        assert!(!target.join("spec-stale.md").exists());
    }

    #[test]
    fn test_remove_spec() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("specs");
        let syncer = SpecSyncer::new(target.clone());

        // Create a spec file
        fs::create_dir_all(&target).unwrap();
        fs::write(target.join("spec-001.md"), "content").unwrap();

        // Remove it
        syncer.remove_spec("spec-001").unwrap();
        assert!(!target.join("spec-001.md").exists());
    }

    #[test]
    fn test_list_synced() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("specs");
        let syncer = SpecSyncer::new(target.clone());

        // Create some spec files
        fs::create_dir_all(&target).unwrap();
        fs::write(target.join("spec-001.md"), "content").unwrap();
        fs::write(target.join("spec-002.md"), "content").unwrap();
        fs::write(target.join("other.md"), "content").unwrap(); // Should be ignored

        let synced = syncer.list_synced().unwrap();
        assert_eq!(synced, vec!["spec-001", "spec-002"]);
    }

    #[test]
    fn test_with_defaults() {
        let temp = TempDir::new().unwrap();
        let syncer = SpecSyncer::with_defaults(temp.path());
        assert_eq!(syncer.target_dir(), temp.path().join("specs"));
    }

    #[test]
    fn test_escape_yaml() {
        assert_eq!(escape_yaml("simple"), "simple");
        assert_eq!(escape_yaml("with: colon"), "\"with: colon\"");
        assert_eq!(escape_yaml("with # hash"), "\"with # hash\"");
        assert_eq!(escape_yaml("with\nnewline"), "\"with\\nnewline\"");
        assert_eq!(escape_yaml(" leading space"), "\" leading space\"");
        assert_eq!(escape_yaml("with \"quotes\""), "\"with \\\"quotes\\\"\"");
    }



    #[test]
    fn test_unapproved_spec_removed() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("specs");
        let syncer = SpecSyncer::new(target.clone());

        // First sync an approved spec
        let mut spec = create_test_spec("spec-001", "Test Spec", true);
        syncer.sync_spec(&spec).unwrap();
        assert!(target.join("spec-001.md").exists());

        // Now unapprove it and sync again
        spec.status = SpecStatus::Draft;
        syncer.sync_spec(&spec).unwrap();
        assert!(!target.join("spec-001.md").exists());
    }
}
