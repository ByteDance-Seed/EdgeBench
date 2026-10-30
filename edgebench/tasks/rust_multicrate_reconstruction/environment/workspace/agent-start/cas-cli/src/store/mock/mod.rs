//! Mock store implementations for testing.
//!
//! Provides in-memory implementations of all store traits for unit testing
//! CLI and MCP handlers without requiring a real database.

mod entry_store;
mod fixtures;
mod id_counter;
mod rule_store;
mod skill_store;
mod task_store;
#[cfg(test)]
mod tests;

pub use entry_store::MockStore;
pub use fixtures::*;
pub use rule_store::MockRuleStore;
pub use skill_store::MockSkillStore;
pub use task_store::MockTaskStore;
