use crate::error::CoreError;
use crate::search::{DocType, SearchIndex};
use cas_types::{Entry, Rule, Skill, Spec, Task};

impl SearchIndex {
    /// Index a single entry
    pub fn index_entry(&self, entry: &Entry) -> Result<(), CoreError> { todo!() }

    /// Index a single task
    pub fn index_task(&self, task: &Task) -> Result<(), CoreError> { todo!() }

    /// Index a single rule
    pub fn index_rule(&self, rule: &Rule) -> Result<(), CoreError> { todo!() }

    /// Index a single skill
    pub fn index_skill(&self, skill: &Skill) -> Result<(), CoreError> { todo!() }

    /// Index a single spec
    pub fn index_spec(&self, spec: &Spec) -> Result<(), CoreError> { todo!() }

    /// Delete an entry from the index
    pub fn delete(&self, id: &str) -> Result<(), CoreError> { todo!() }

    /// Reindex all entries (legacy method - use reindex_all for unified search)
    pub fn reindex(&self, entries: &[Entry]) -> Result<(), CoreError> { todo!() }

    /// Reindex all entity types (entries, tasks, rules, skills, specs)
    pub fn reindex_all(
        &self,
        entries: &[Entry],
        tasks: &[Task],
        rules: &[Rule],
        skills: &[Skill],
        specs: &[Spec],
    ) -> Result<usize, CoreError> { todo!() }
}
