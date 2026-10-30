use crate::types::{
    Dependency, DependencyType, Entry, EntryType, Priority, Rule, RuleStatus, Skill, SkillStatus,
    Task, TaskStatus,
};

/// Create a test entry with minimal required fields.
pub fn entry(id: &str, content: &str) -> Entry { todo!() }

/// Create a test entry with tags.
pub fn entry_with_tags(id: &str, content: &str, tags: Vec<&str>) -> Entry { todo!() }

/// Create a test rule.
pub fn rule(id: &str, content: &str) -> Rule { todo!() }

/// Create a proven rule.
pub fn proven_rule(id: &str, content: &str) -> Rule { todo!() }

/// Create a test task.
pub fn task(id: &str, title: &str) -> Task { todo!() }

/// Create a task with priority.
pub fn task_with_priority(id: &str, title: &str, priority: i32) -> Task { todo!() }

/// Create an in-progress task.
pub fn in_progress_task(id: &str, title: &str) -> Task { todo!() }

/// Create a test skill.
pub fn skill(id: &str, name: &str) -> Skill { todo!() }

/// Create a disabled skill.
pub fn disabled_skill(id: &str, name: &str) -> Skill { todo!() }

/// Create a dependency.
pub fn blocks(from: &str, to: &str) -> Dependency { todo!() }
