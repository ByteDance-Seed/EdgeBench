//! Layered store for two-tier (global + project) storage
//!
//! The LayeredStore wraps both global and project stores, routing operations
//! based on scope and merging results from both tiers.

use std::path::Path;
use std::sync::Arc;

use crate::types::{Entry, Rule, Scope, ScopeFilter, Skill, SkillStatus};

use crate::store::{Result, RuleStore, SkillStore, Store};

/// Layered entry store combining global and project tiers
pub struct LayeredEntryStore {
    /// Global store (~/.config/cas/)
    global: Arc<dyn Store>,
    /// Project store (./.cas/) - optional, may not exist
    project: Option<Arc<dyn Store>>,
}

impl LayeredEntryStore {
    /// Create a new layered store with both tiers
    pub fn new(global: Arc<dyn Store>, project: Option<Arc<dyn Store>>) -> Self { todo!() }

    /// Create a layered store with only global tier
    pub fn global_only(global: Arc<dyn Store>) -> Self { todo!() }

    /// Get the global store
    pub fn global(&self) -> &Arc<dyn Store> { todo!() }

    /// Get the project store if available
    pub fn project(&self) -> Option<&Arc<dyn Store>> { todo!() }

    /// Check if project store is available
    pub fn has_project(&self) -> bool { todo!() }

    /// Get the appropriate store for a scope
    fn store_for_scope(&self, scope: Scope) -> &Arc<dyn Store> { todo!() }

    /// Generate ID with scope prefix
    pub fn generate_id(&self, scope: Scope) -> Result<String> { todo!() }

    /// Add entry to appropriate store based on its scope
    pub fn add(&self, entry: &Entry) -> Result<()> { todo!() }

    /// Get entry by ID, checking both stores
    pub fn get(&self, id: &str) -> Result<Entry> { todo!() }

    /// Update entry in appropriate store
    pub fn update(&self, entry: &Entry) -> Result<()> { todo!() }

    /// Delete entry from appropriate store
    pub fn delete(&self, id: &str) -> Result<()> { todo!() }

    /// List entries with scope filter
    pub fn list(&self, filter: ScopeFilter) -> Result<Vec<Entry>> { todo!() }

    /// Get recent entries from both stores
    pub fn recent(&self, n: usize, filter: ScopeFilter) -> Result<Vec<Entry>> { todo!() }

    /// Archive entry
    pub fn archive(&self, id: &str) -> Result<()> { todo!() }

    /// Unarchive entry
    pub fn unarchive(&self, id: &str) -> Result<()> { todo!() }

    /// List helpful entries from both stores
    pub fn list_helpful(&self, limit: usize, filter: ScopeFilter) -> Result<Vec<Entry>> { todo!() }

    /// List unreviewed learning entries from both stores
    pub fn list_unreviewed_learnings(&self, limit: usize, filter: ScopeFilter) -> Result<Vec<Entry>> { todo!() }

    /// Mark an entry as reviewed
    pub fn mark_reviewed(&self, id: &str) -> Result<()> { todo!() }

    /// Get the .cas directory path (project if available, otherwise global)
    pub fn cas_dir(&self) -> &Path { todo!() }

    /// Get the global cas directory
    pub fn global_cas_dir(&self) -> &Path { todo!() }

    /// Get the project cas directory if available
    pub fn project_cas_dir(&self) -> Option<&Path> { todo!() }
}

/// Layered rule store combining global and project tiers
pub struct LayeredRuleStore {
    global: Arc<dyn RuleStore>,
    project: Option<Arc<dyn RuleStore>>,
}

impl LayeredRuleStore {
    /// Create a new layered rule store
    pub fn new(global: Arc<dyn RuleStore>, project: Option<Arc<dyn RuleStore>>) -> Self { todo!() }

    /// Create with only global tier
    pub fn global_only(global: Arc<dyn RuleStore>) -> Self { todo!() }

    /// Get store for scope
    fn store_for_scope(&self, scope: Scope) -> &Arc<dyn RuleStore> { todo!() }

    /// Generate ID with scope prefix
    pub fn generate_id(&self, scope: Scope) -> Result<String> { todo!() }

    /// Add rule to appropriate store
    pub fn add(&self, rule: &Rule) -> Result<()> { todo!() }

    /// Get rule by ID
    pub fn get(&self, id: &str) -> Result<Rule> { todo!() }

    /// Update rule
    pub fn update(&self, rule: &Rule) -> Result<()> { todo!() }

    /// Delete rule
    pub fn delete(&self, id: &str) -> Result<()> { todo!() }

    /// List rules with scope filter
    pub fn list(&self, filter: ScopeFilter) -> Result<Vec<Rule>> { todo!() }
}

/// Layered skill store combining global and project tiers
pub struct LayeredSkillStore {
    global: Arc<dyn SkillStore>,
    project: Option<Arc<dyn SkillStore>>,
}

impl LayeredSkillStore {
    /// Create a new layered skill store
    pub fn new(global: Arc<dyn SkillStore>, project: Option<Arc<dyn SkillStore>>) -> Self { todo!() }

    /// Create with only global tier
    pub fn global_only(global: Arc<dyn SkillStore>) -> Self { todo!() }

    /// Get store for scope
    fn store_for_scope(&self, scope: Scope) -> &Arc<dyn SkillStore> { todo!() }

    /// Generate ID with scope prefix
    pub fn generate_id(&self, scope: Scope) -> Result<String> { todo!() }

    /// Add skill to appropriate store
    pub fn add(&self, skill: &Skill) -> Result<()> { todo!() }

    /// Get skill by ID
    pub fn get(&self, id: &str) -> Result<Skill> { todo!() }

    /// Update skill
    pub fn update(&self, skill: &Skill) -> Result<()> { todo!() }

    /// Delete skill
    pub fn delete(&self, id: &str) -> Result<()> { todo!() }

    /// List skills with scope filter
    pub fn list(&self, status: Option<SkillStatus>, filter: ScopeFilter) -> Result<Vec<Skill>> { todo!() }

    /// List enabled skills from both stores
    pub fn list_enabled(&self) -> Result<Vec<Skill>> { todo!() }

    /// Search skills in both stores
    pub fn search(&self, query: &str) -> Result<Vec<Skill>> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::store::layered::*;
    use crate::store::mock::{MockRuleStore, MockSkillStore, MockStore};



    #[test]
    fn test_layered_entry_store_add_and_get() {
        let global: Arc<dyn Store> = Arc::new(MockStore::new());
        let project: Arc<dyn Store> = Arc::new(MockStore::new());
        let layered = LayeredEntryStore::new(Arc::clone(&global), Some(Arc::clone(&project)));

        // Add global entry
        let mut global_entry = Entry::new("g-001".to_string(), "Global entry".to_string());
        global_entry.scope = Scope::Global;
        layered.add(&global_entry).unwrap();

        // Add project entry
        let mut project_entry = Entry::new("p-001".to_string(), "Project entry".to_string());
        project_entry.scope = Scope::Project;
        layered.add(&project_entry).unwrap();

        // Retrieve by ID
        let got_global = layered.get("g-001").unwrap();
        assert_eq!(got_global.content, "Global entry");

        let got_project = layered.get("p-001").unwrap();
        assert_eq!(got_project.content, "Project entry");
    }


    #[test]
    fn test_layered_rule_store() {
        let global: Arc<dyn RuleStore> = Arc::new(MockRuleStore::new());
        let project: Arc<dyn RuleStore> = Arc::new(MockRuleStore::new());
        let layered = LayeredRuleStore::new(Arc::clone(&global), Some(Arc::clone(&project)));

        // Add rules
        let mut g_rule = Rule::new("g-rule-001".to_string(), "Global rule".to_string());
        g_rule.scope = Scope::Global;
        layered.add(&g_rule).unwrap();

        let mut p_rule = Rule::new("p-rule-001".to_string(), "Project rule".to_string());
        p_rule.scope = Scope::Project;
        layered.add(&p_rule).unwrap();

        // List all
        let all = layered.list(ScopeFilter::All).unwrap();
        assert_eq!(all.len(), 2);
    }

    #[test]
    fn test_layered_skill_store() {
        let global: Arc<dyn SkillStore> = Arc::new(MockSkillStore::new());
        let project: Arc<dyn SkillStore> = Arc::new(MockSkillStore::new());
        let layered = LayeredSkillStore::new(Arc::clone(&global), Some(Arc::clone(&project)));

        // Add skills (default scope is Global)
        let g_skill = Skill::new("g-sk01".to_string(), "Global Skill".to_string());
        layered.add(&g_skill).unwrap();

        let mut p_skill = Skill::new("p-sk01".to_string(), "Project Skill".to_string());
        p_skill.scope = Scope::Project;
        layered.add(&p_skill).unwrap();

        // List all
        let all = layered.list(None, ScopeFilter::All).unwrap();
        assert_eq!(all.len(), 2);
    }
}
