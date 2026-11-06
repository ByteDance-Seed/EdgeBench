use crate::error::CoreError;
use crate::hooks::config::HooksConfig;
use crate::hooks::context::{
    BasicContextScorer, ContextItem, ContextQuery, ContextScorer, ContextStats, ContextStores,
    SurfacedItemCallback, USAGE_REMINDER, estimate_tokens, format_category_badge, merge_entries,
    merge_rules, merge_skills, render_factory_coordination, render_normal_coordination,
    rule_matches_path, token_display,
};
use crate::hooks::types::HookInput;
use cas_types::{
    AgentRole, AgentStatus, Entry, EntryType, Rule, RuleStatus, Skill, SkillStatus, TaskStatus,
};
use std::collections::HashSet;

/// Build context string for session start injection
///
/// Uses progressive disclosure pattern:
/// - Shows summaries with token estimates
/// - Full content available via `cas show <id>`
/// - Allows Claude to decide what to fetch based on relevance
pub fn build_context_with_stores(
    input: &HookInput,
    stores: &ContextStores,
    config: &dyn HooksConfig,
    limit: usize,
    on_surfaced: Option<&SurfacedItemCallback>,
) -> Result<(String, ContextStats), CoreError> { todo!() }
