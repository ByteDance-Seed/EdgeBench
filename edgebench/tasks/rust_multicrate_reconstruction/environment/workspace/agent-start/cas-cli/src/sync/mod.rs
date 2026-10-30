//! Claude Code syncing
//!
//! Syncs proven rules and enabled skills to Claude Code directories for integration.
//!
//! # Two-Tier Architecture
//!
//! CAS uses a two-tier storage architecture:
//! - **Global rules** (`~/.config/cas/`) sync to a user-wide Claude Code rules directory
//! - **Project rules** (`./.cas/`) sync to project's `.claude/rules/cas/`
//!
//! # Sync Targets
//!
//! - **Rules**: `.claude/rules/cas/` - Proven rules become Claude Code rules
//! - **Skills**: `.claude/skills/cas-<name>/` - Enabled skills become Agent Skills
//!
//! # Usage
//!
//! ```rust,ignore
//! use cas::sync::Syncer;
//!
//! // Project-level syncing
//! let syncer = Syncer::with_defaults(project_root);
//! let report = syncer.sync_all(&rules)?;
//!
//! // Two-tier syncing
//! let syncer = Syncer::for_two_tier(global_root, project_root);
//! let report = syncer.sync_all_tiered(&global_rules, &project_rules)?;
//! ```
//!
//! # Sync Behavior
//!
//! - Rules must be "proven" (helpful_count >= min_helpful, not retired)
//! - Stale files are automatically removed when rules become unproven
//! - Skills are synced when enabled, removed when disabled

// #![allow(dead_code)] // Check unused // API for sync functionality

pub mod skills;

pub use skills::{SkillSyncer, create_planning_skill, generate_planning_skill};
// create_cas_skill is available but not re-exported - used internally in tests

use std::collections::HashSet;
use std::fs;
use std::path::{Path, PathBuf};

use crate::error::CasError;
use crate::types::{Rule, RuleStatus, Scope};

/// Syncs rules to Claude Code
pub struct Syncer {
    /// Target directory for project rules
    target_dir: PathBuf,
    /// Target directory for global rules (optional)
    global_target_dir: Option<PathBuf>,
    /// Minimum helpful count for a rule to be synced
    min_helpful: i32,
}

/// Report of sync operation
#[derive(Debug, Default)]
pub struct SyncReport {
    /// Number of rules synced
    pub synced: usize,
    /// Number of stale files removed
    pub removed: usize,
    /// Rules that were synced
    pub synced_ids: Vec<String>,
    /// Files that were removed
    pub removed_ids: Vec<String>,
    /// Number of global rules synced
    pub global_synced: usize,
    /// Number of global stale files removed
    pub global_removed: usize,
}

impl Syncer {
    /// Create a new syncer
    pub fn new(target_dir: PathBuf, min_helpful: i32) -> Self { todo!() }

    /// Create a syncer with default settings
    pub fn with_defaults(project_root: &Path) -> Self { todo!() }

    /// Create a syncer for two-tier architecture
    ///
    /// # Arguments
    /// * `global_root` - Optional global CAS root (~/.config/cas/)
    /// * `project_root` - Project root directory
    pub fn for_two_tier(global_root: Option<&Path>, project_root: &Path) -> Self { todo!() }

    /// Set the global target directory
    pub fn with_global_target(mut self, global_target: PathBuf) -> Self { todo!() }

    /// Check if a rule should be synced to Claude Code
    pub fn is_proven(&self, rule: &Rule) -> bool { todo!() }

    /// Sync a single rule to target directory
    ///
    /// Returns true if the rule was synced, false if it wasn't proven
    pub fn sync_rule(&self, rule: &Rule) -> Result<bool, CasError> { todo!() }

    /// Sync all proven rules and remove stale files
    pub fn sync_all(&self, rules: &[Rule]) -> Result<SyncReport, CasError> { todo!() }

    /// Remove a specific rule file
    pub fn remove_rule(&self, rule_id: &str) -> Result<(), CasError> { todo!() }

    /// Get the target directory path
    pub fn target_dir(&self) -> &Path { todo!() }

    /// List all synced rule files
    pub fn list_synced(&self) -> Result<Vec<String>, CasError> { todo!() }

    /// Get the global target directory path (if configured)
    pub fn global_target_dir(&self) -> Option<&Path> { todo!() }

    /// Sync a single rule to the appropriate target directory based on scope
    pub fn sync_rule_with_scope(&self, rule: &Rule) -> Result<bool, CasError> { todo!() }

    /// Sync rules from both global and project stores
    ///
    /// Global rules are synced to global_target_dir, project rules to target_dir.
    pub fn sync_all_tiered(
        &self,
        global_rules: &[Rule],
        project_rules: &[Rule],
    ) -> Result<SyncReport, CasError> { todo!() }

    /// Internal helper to sync rules to a specific directory
    fn sync_rules_to_dir(&self, target_dir: &Path, rules: &[Rule]) -> Result<SyncReport, CasError> { todo!() }

    /// List all synced rule files from both project and global directories
    pub fn list_all_synced(&self) -> Result<(Vec<String>, Vec<String>), CasError> { todo!() }

    /// List synced rules from a specific directory
    fn list_synced_from_dir(&self, dir: &Path) -> Result<Vec<String>, CasError> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::sync::*;
    use tempfile::TempDir;

    #[test]
    fn test_is_proven() {
        let temp = TempDir::new().unwrap();
        let syncer = Syncer::new(temp.path().to_path_buf(), 2);

        let mut rule = Rule::new("rule-001".to_string(), "Test rule".to_string());

        // Not proven yet (helpful_count = 0)
        assert!(!syncer.is_proven(&rule));

        // Still not proven (helpful_count = 1)
        rule.helpful_count = 1;
        assert!(!syncer.is_proven(&rule));

        // Now proven (helpful_count = 2)
        rule.helpful_count = 2;
        assert!(syncer.is_proven(&rule));

        // Retired rules are never proven
        rule.status = RuleStatus::Retired;
        assert!(!syncer.is_proven(&rule));
    }


    #[test]
    fn test_sync_all() {
        let temp = TempDir::new().unwrap();
        let target = temp.path().join("claude/rules/cas");
        let syncer = Syncer::new(target.clone(), 1);

        let mut rule1 = Rule::new("rule-001".to_string(), "Rule 1".to_string());
        rule1.helpful_count = 2;

        let mut rule2 = Rule::new("rule-002".to_string(), "Rule 2".to_string());
        rule2.helpful_count = 0; // Not proven

        let rules = vec![rule1, rule2];
        let report = syncer.sync_all(&rules).unwrap();

        assert_eq!(report.synced, 1);
        assert!(target.join("rule-001.md").exists());
        assert!(!target.join("rule-002.md").exists());
    }

    #[test]
    fn test_for_two_tier() {
        let temp = TempDir::new().unwrap();
        let global_root = temp.path().join("global");
        let project_root = temp.path().join("project");
        fs::create_dir_all(&global_root).unwrap();
        fs::create_dir_all(&project_root).unwrap();

        let syncer = Syncer::for_two_tier(Some(&global_root), &project_root);

        assert_eq!(syncer.target_dir(), project_root.join(".claude/rules/cas"));
        assert!(syncer.global_target_dir().is_some());
    }

    #[test]
    fn test_sync_all_tiered() {
        let temp = TempDir::new().unwrap();
        let project_target = temp.path().join("project/.claude/rules/cas");
        let global_target = temp.path().join("global/.claude/rules/cas-global");

        let syncer =
            Syncer::new(project_target.clone(), 1).with_global_target(global_target.clone());

        // Create global rules
        let mut global_rule = Rule::new("g-rule-001".to_string(), "Global rule".to_string());
        global_rule.helpful_count = 1;
        global_rule.scope = Scope::Global;

        // Create project rules
        let mut project_rule = Rule::new("p-rule-001".to_string(), "Project rule".to_string());
        project_rule.helpful_count = 1;
        project_rule.scope = Scope::Project;

        let report = syncer
            .sync_all_tiered(&[global_rule], &[project_rule])
            .unwrap();

        // Check both directories have the synced rules
        assert_eq!(report.synced, 1);
        assert_eq!(report.global_synced, 1);
        assert!(project_target.join("p-rule-001.md").exists());
        assert!(global_target.join("g-rule-001.md").exists());
    }


    #[test]
    fn test_list_all_synced() {
        let temp = TempDir::new().unwrap();
        let project_target = temp.path().join("project/.claude/rules/cas");
        let global_target = temp.path().join("global/.claude/rules/cas-global");

        let syncer =
            Syncer::new(project_target.clone(), 1).with_global_target(global_target.clone());

        // Create some files
        fs::create_dir_all(&project_target).unwrap();
        fs::create_dir_all(&global_target).unwrap();
        fs::write(project_target.join("p-rule-001.md"), "project rule").unwrap();
        fs::write(global_target.join("g-rule-001.md"), "global rule").unwrap();

        let (project_ids, global_ids) = syncer.list_all_synced().unwrap();

        assert_eq!(project_ids, vec!["p-rule-001".to_string()]);
        assert_eq!(global_ids, vec!["g-rule-001".to_string()]);
    }
}
