//! Integration tests for SQLite stores
//!
//! These tests use real SQLite databases to verify the stores work correctly.

use std::sync::Arc;
use tempfile::TempDir;

use cas_store::{
    EntityStore, RuleStore, SkillStore, SpecStore, SqliteEntityStore, SqliteRuleStore,
    SqliteSkillStore, SqliteSpecStore, SqliteStore, SqliteTaskStore, Store, TaskStore,
};
use cas_types::{
    Dependency, DependencyType, Entity, EntityType, Entry, EntryType, Priority, RelationType,
    Relationship, Rule, RuleStatus, Scope, ScopeFilter, Skill, SkillStatus, Spec, SpecStatus,
    SpecType, Task, TaskStatus,
};

fn setup_temp_dir() -> TempDir { todo!() }

// =============================================================================
// SqliteStore (Entry) Integration Tests
// =============================================================================

#[path = "sqlite_integration_cases/tests.rs"]
mod tests;
