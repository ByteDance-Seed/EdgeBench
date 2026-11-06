//! Mock store implementations for testing
//!
//! Provides in-memory implementations of all store traits for unit testing
//! without requiring a real database.

use std::collections::HashMap;
use std::path::{Path, PathBuf};
use std::sync::RwLock;

use chrono::Utc;

use crate::error::{Result, StoreError};
use crate::{RuleStore, SkillStore, Store};
use cas_types::{Entry, MemoryTier, Rule, RuleStatus, Skill, SkillStatus};

/// Thread-safe counter for generating unique IDs
#[derive(Debug, Default)]
struct IdCounter(RwLock<u32>);

impl IdCounter {
    fn next(&self) -> u32 { todo!() }
}

// =============================================================================
// MockStore - Entry storage
// =============================================================================

/// In-memory mock implementation of the Store trait
#[derive(Debug)]
pub struct MockStore {
    entries: RwLock<HashMap<String, Entry>>,
    archived: RwLock<HashMap<String, Entry>>,
    id_counter: IdCounter,
    cas_dir: PathBuf,
}

impl Default for MockStore {
    fn default() -> Self { todo!() }
}

impl MockStore {
    /// Create a new empty mock store
    pub fn new() -> Self { todo!() }

    /// Create a mock store with pre-populated test data
    pub fn with_entries(entries: Vec<Entry>) -> Self { todo!() }

    /// Get the number of entries (for testing)
    pub fn len(&self) -> usize { todo!() }

    /// Check if store is empty (for testing)
    pub fn is_empty(&self) -> bool { todo!() }
}

impl Store for MockStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, entry: &Entry) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Entry> { todo!() }

    fn get_archived(&self, id: &str) -> Result<Entry> { todo!() }

    fn update(&self, entry: &Entry) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self) -> Result<Vec<Entry>> { todo!() }

    fn recent(&self, n: usize) -> Result<Vec<Entry>> { todo!() }

    fn archive(&self, id: &str) -> Result<()> { todo!() }

    fn unarchive(&self, id: &str) -> Result<()> { todo!() }

    fn list_archived(&self) -> Result<Vec<Entry>> { todo!() }

    fn list_pending(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }

    fn mark_extracted(&self, id: &str) -> Result<()> { todo!() }

    fn list_pinned(&self) -> Result<Vec<Entry>> { todo!() }

    fn list_helpful(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }

    fn list_by_session(&self, session_id: &str) -> Result<Vec<Entry>> { todo!() }

    fn list_unreviewed_learnings(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }

    fn mark_reviewed(&self, id: &str) -> Result<()> { todo!() }

    fn list_pending_index(&self, limit: usize) -> Result<Vec<Entry>> { todo!() }

    fn mark_indexed(&self, id: &str) -> Result<()> { todo!() }

    fn mark_indexed_batch(&self, ids: &[&str]) -> Result<()> { todo!() }

    fn cas_dir(&self) -> &Path { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

// =============================================================================
// MockRuleStore - Rule storage
// =============================================================================

/// In-memory mock implementation of the RuleStore trait
#[derive(Debug)]
pub struct MockRuleStore {
    rules: RwLock<HashMap<String, Rule>>,
    id_counter: IdCounter,
}

impl Default for MockRuleStore {
    fn default() -> Self { todo!() }
}

impl MockRuleStore {
    /// Create a new empty mock rule store
    pub fn new() -> Self { todo!() }

    /// Create with pre-populated rules
    pub fn with_rules(rules: Vec<Rule>) -> Self { todo!() }

    /// Get count (for testing)
    pub fn len(&self) -> usize { todo!() }

    /// Check if empty (for testing)
    pub fn is_empty(&self) -> bool { todo!() }
}

impl RuleStore for MockRuleStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, rule: &Rule) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Rule> { todo!() }

    fn update(&self, rule: &Rule) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self) -> Result<Vec<Rule>> { todo!() }

    fn list_proven(&self) -> Result<Vec<Rule>> { todo!() }

    fn list_critical(&self) -> Result<Vec<Rule>> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}

// =============================================================================
// MockSkillStore - Skill storage
// =============================================================================

/// In-memory mock implementation of the SkillStore trait
#[derive(Debug)]
pub struct MockSkillStore {
    skills: RwLock<HashMap<String, Skill>>,
    id_counter: IdCounter,
}

impl Default for MockSkillStore {
    fn default() -> Self { todo!() }
}

impl MockSkillStore {
    /// Create a new empty mock skill store
    pub fn new() -> Self { todo!() }

    /// Create with pre-populated skills
    pub fn with_skills(skills: Vec<Skill>) -> Self { todo!() }

    /// Get count (for testing)
    pub fn len(&self) -> usize { todo!() }

    /// Check if empty (for testing)
    pub fn is_empty(&self) -> bool { todo!() }
}

impl SkillStore for MockSkillStore {
    fn init(&self) -> Result<()> { todo!() }

    fn generate_id(&self) -> Result<String> { todo!() }

    fn add(&self, skill: &Skill) -> Result<()> { todo!() }

    fn get(&self, id: &str) -> Result<Skill> { todo!() }

    fn update(&self, skill: &Skill) -> Result<()> { todo!() }

    fn delete(&self, id: &str) -> Result<()> { todo!() }

    fn list(&self, status: Option<SkillStatus>) -> Result<Vec<Skill>> { todo!() }

    fn list_enabled(&self) -> Result<Vec<Skill>> { todo!() }

    fn search(&self, query: &str) -> Result<Vec<Skill>> { todo!() }

    fn close(&self) -> Result<()> { todo!() }
}
