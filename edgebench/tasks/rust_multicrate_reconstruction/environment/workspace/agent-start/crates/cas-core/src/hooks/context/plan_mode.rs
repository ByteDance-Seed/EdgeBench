use crate::error::CoreError;
use crate::hooks::config::HooksConfig;
use crate::hooks::context::{
    ContextItem, ContextStats, ContextStores, estimate_tokens, merge_rules, rule_matches_path,
    token_display, truncate,
};
use crate::hooks::types::HookInput;
use cas_store::TaskStore;
use cas_types::{Dependency, Rule, RuleStatus, Task, TaskStatus};
use std::collections::HashSet;

pub fn build_plan_context_with_stores(
    input: &HookInput,
    stores: &ContextStores,
    config: &dyn HooksConfig,
    _limit: usize,
) -> Result<(String, ContextStats), CoreError> { todo!() }

/// Format a task with dependency info for plan mode
fn format_task_for_plan(task: &Task, ts: &dyn TaskStore) -> String { todo!() }

/// Build a text representation of the dependency tree
fn build_dependency_tree(deps: &[Dependency], tasks: &[Task]) -> String { todo!() }
