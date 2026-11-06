//! SQLite-based skill storage

use chrono::{DateTime, TimeZone, Utc};
use rusqlite::{Connection, OptionalExtension, params};
use std::path::Path;
use std::sync::{Arc, Mutex};

use crate::error::StoreError;
use crate::{Result, SkillStore};
use cas_types::{Scope, Skill, SkillHooks, SkillStatus, SkillType};

const SKILL_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS skills (
    id TEXT PRIMARY KEY,
    name TEXT NOT NULL,
    description TEXT NOT NULL DEFAULT '',
    skill_type TEXT NOT NULL DEFAULT 'command',
    invocation TEXT NOT NULL DEFAULT '',
    parameters_schema TEXT NOT NULL DEFAULT '',
    example TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'enabled',
    tags TEXT NOT NULL DEFAULT '[]',
    summary TEXT NOT NULL DEFAULT '',
    -- Validation columns
    preconditions TEXT NOT NULL DEFAULT '[]',
    postconditions TEXT NOT NULL DEFAULT '[]',
    validation_script TEXT NOT NULL DEFAULT '',
    -- Invokable skill support
    invokable INTEGER NOT NULL DEFAULT 0,
    argument_hint TEXT NOT NULL DEFAULT '',
    -- Claude Code frontmatter fields (added for Claude Code compatibility)
    context_mode TEXT,
    agent_type TEXT,
    allowed_tools TEXT NOT NULL DEFAULT '[]',
    -- Skill-scoped hooks (Claude Code 2.1.0+)
    hooks TEXT,
    -- Disable model invocation (Claude Code 2.1.3+)
    disable_model_invocation INTEGER NOT NULL DEFAULT 0,
    -- Usage tracking
    usage_count INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL,
    last_used TEXT,
    -- Team collaboration
    team_id TEXT
);

CREATE INDEX IF NOT EXISTS idx_skills_status ON skills(status);
CREATE INDEX IF NOT EXISTS idx_skills_name ON skills(name);
"#;

// NOTE: Column migrations are now handled by `cas update --schema-only`
// See cas-cli/src/migration/migrations.rs for migration definitions (IDs 71-76)

/// SQLite-based skill store
pub struct SqliteSkillStore {
    conn: Arc<Mutex<Connection>>,
}

impl SqliteSkillStore {
    /// Open or create a SQLite skill store
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    fn parse_datetime(s: &str) -> Option<DateTime<Utc>> { todo!() }

    fn parse_tags(s: &str) -> Vec<String> { todo!() }

    fn tags_to_string(tags: &[String]) -> String { todo!() }

    /// Generate a hash-based ID like cas-sk01
    fn generate_hash_id(&self) -> Result<String> { todo!() }

    fn parse_hooks(s: &str) -> Option<SkillHooks> { todo!() }

    fn hooks_to_string(hooks: &Option<SkillHooks>) -> Option<String> { todo!() }

    fn skill_from_row(row: &rusqlite::Row) -> rusqlite::Result<Skill> { todo!() }
}

impl SkillStore for SqliteSkillStore {
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

#[cfg(test)]
mod tests {
    use crate::skill_store::*;
    use tempfile::TempDir;

    fn create_test_store() -> (TempDir, SqliteSkillStore) {
        let temp = TempDir::new().unwrap();
        let store = SqliteSkillStore::open(temp.path()).unwrap();
        store.init().unwrap();
        (temp, store)
    }

    #[test]
    fn test_skill_crud() {
        let (_temp, store) = create_test_store();

        // Create skill
        let id = store.generate_id().unwrap();
        let mut skill = Skill::new(id.clone(), "Test Skill".to_string());
        skill.description = "A test skill".to_string();
        skill.skill_type = SkillType::Command;
        skill.invocation = "echo hello".to_string();
        skill.tags = vec!["test".to_string()];
        store.add(&skill).unwrap();

        // Get skill
        let retrieved = store.get(&id).unwrap();
        assert_eq!(retrieved.name, "Test Skill");
        assert_eq!(retrieved.description, "A test skill");
        assert_eq!(retrieved.tags, vec!["test"]);

        // Update skill
        skill.description = "Updated description".to_string();
        skill.usage_count = 5;
        store.update(&skill).unwrap();

        let retrieved = store.get(&id).unwrap();
        assert_eq!(retrieved.description, "Updated description");
        assert_eq!(retrieved.usage_count, 5);

        // List skills
        let all_skills = store.list(None).unwrap();
        assert_eq!(all_skills.len(), 1);

        let enabled = store.list_enabled().unwrap();
        assert_eq!(enabled.len(), 1);

        // Delete skill
        store.delete(&id).unwrap();
        assert!(store.get(&id).is_err());
    }

    #[test]
    fn test_skill_search() {
        let (_temp, store) = create_test_store();

        // Create skills
        let skill1 = Skill {
            id: store.generate_id().unwrap(),
            name: "File Search".to_string(),
            description: "Search for files by pattern".to_string(),
            tags: vec!["files".to_string(), "search".to_string()],
            ..Default::default()
        };
        let skill2 = Skill {
            id: store.generate_id().unwrap(),
            name: "Git Status".to_string(),
            description: "Check git repository status".to_string(),
            tags: vec!["git".to_string()],
            ..Default::default()
        };
        store.add(&skill1).unwrap();
        store.add(&skill2).unwrap();

        // Search by name
        let results = store.search("File").unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].name, "File Search");

        // Search by description
        let results = store.search("repository").unwrap();
        assert_eq!(results.len(), 1);
        assert_eq!(results[0].name, "Git Status");

        // Search by tag
        let results = store.search("search").unwrap();
        assert_eq!(results.len(), 1);
    }

    #[test]
    fn test_skill_invokable() {
        let (_temp, store) = create_test_store();

        // Create invokable skill
        let id = store.generate_id().unwrap();
        let mut skill = Skill::new(id.clone(), "Task Creator".to_string());
        skill.description = "Create a task".to_string();
        skill.invokable = true;
        skill.argument_hint = "[title]".to_string();
        store.add(&skill).unwrap();

        // Retrieve and verify
        let retrieved = store.get(&id).unwrap();
        assert!(retrieved.invokable);
        assert_eq!(retrieved.argument_hint, "[title]");

        // Update invokable fields
        skill.argument_hint = "[title] [priority?]".to_string();
        store.update(&skill).unwrap();

        let retrieved = store.get(&id).unwrap();
        assert_eq!(retrieved.argument_hint, "[title] [priority?]");
    }
}
