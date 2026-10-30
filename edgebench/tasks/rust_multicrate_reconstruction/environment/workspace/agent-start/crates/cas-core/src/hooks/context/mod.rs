//! Context building for session start injection
//!
//! Builds a context string from proven rules, high-value entries,
//! ready tasks, and enabled skills to inject at session start.
//!
//! # Progressive Disclosure
//!
//! Context is built using progressive disclosure - showing summaries with
//! token estimates rather than full content. This allows Claude to decide
//! what to fetch based on relevance.
//!
//! # Architecture
//!
//! This module provides the core context building logic that can be used
//! by both CLI and MCP interfaces. Store access is abstracted via traits
//! from `cas-store`.
//!
//! # Scoring System
//!
//! Entries are scored for context selection using pluggable scorers:
//! - `BasicContextScorer` - Simple formula based on type, feedback, age, importance
//! - Hybrid scorers (provided by CLI) - Use semantic embeddings for relevance

use std::collections::{HashMap, HashSet};

use cas_store::{AgentStore, RuleStore, SkillStore, Store, TaskStore};
use cas_types::{Entry, EntryType, Rule, RuleCategory, Skill, Task};

// ============================================================================
// Context Scoring System
// ============================================================================

/// Query context for semantic scoring
///
/// Provides information about the current session to help score entries
/// by relevance to the current work context.
#[derive(Debug, Clone, Default)]
pub struct ContextQuery {
    /// Titles of in-progress tasks (most relevant context)
    pub task_titles: Vec<String>,
    /// Current working directory
    pub cwd: String,
    /// User's current prompt (if available)
    pub user_prompt: Option<String>,
    /// Recent file paths being worked on
    pub recent_files: Vec<String>,
}

impl ContextQuery {
    /// Build a search query string from the context
    pub fn to_query_string(&self) -> String { todo!() }

    /// Check if the query has meaningful content for semantic search
    pub fn has_content(&self) -> bool { todo!() }
}

/// Trait for scoring entries for context selection
///
/// Implementations can use different strategies:
/// - BasicContextScorer: Simple formula (type × feedback × age × importance)
/// - HybridContextScorer: Semantic embeddings + BM25 + temporal (from CLI)
pub trait ContextScorer: Send + Sync {
    /// Score entries for context selection
    ///
    /// Returns entries paired with their scores (higher = more relevant).
    /// The returned vector should be sorted by score descending.
    fn score_entries(&self, entries: &[Entry], context: &ContextQuery) -> Vec<(Entry, f32)>;

    /// Name of the scorer for debugging/tracing
    fn name(&self) -> &'static str;
}

/// Basic context scorer using simple formula
///
/// Score = type_weight × feedback_boost × age_decay × importance_boost × stability_boost
///
/// This is the fallback when hybrid search infrastructure isn't available.
#[derive(Debug, Default)]
pub struct BasicContextScorer;

impl BasicContextScorer {
    /// Calculate score for a single entry
    pub fn calculate_score(entry: &Entry) -> f32 { todo!() }
}

impl ContextScorer for BasicContextScorer {
    fn score_entries(&self, entries: &[Entry], _context: &ContextQuery) -> Vec<(Entry, f32)> { todo!() }

    fn name(&self) -> &'static str { todo!() }
}

/// Estimate token count for a string (approximately 4 chars per token)
pub fn estimate_tokens(s: &str) -> usize { todo!() }

/// Format token count for display
pub fn token_display(tokens: usize) -> String { todo!() }

/// Truncate a string to a maximum length
pub fn truncate(s: &str, max_len: usize) -> String { todo!() }

/// Format rule category as a short badge for display
pub(crate) fn format_category_badge(category: RuleCategory) -> &'static str { todo!() }

// calculate_entry_score moved to BasicContextScorer::calculate_score

/// Check if a rule's path pattern matches the current directory
pub fn rule_matches_path(rule: &Rule, cwd: &str) -> bool { todo!() }

/// Cache for rule path matches to avoid repeated glob parsing
///
/// Pre-computes which rules match a given cwd. Reusable across multiple
/// context builds in the same session (same cwd = same matches).
#[derive(Debug, Default)]
pub struct RuleMatchCache {
    /// Current working directory this cache is valid for
    cwd: String,
    /// Map of rule_id -> matches_path
    matches: HashMap<String, bool>,
}

impl RuleMatchCache {
    /// Create a new empty cache
    pub fn new() -> Self { todo!() }

    /// Build a cache for all rules against a given cwd
    pub fn build(rules: &[Rule], cwd: &str) -> Self { todo!() }

    /// Check if a rule matches (uses cached result if available)
    pub fn matches(&self, rule: &Rule, cwd: &str) -> bool { todo!() }

    /// Check if the cache is valid for a given cwd
    pub fn is_valid_for(&self, cwd: &str) -> bool { todo!() }

    /// Get the cwd this cache was built for
    pub fn cwd(&self) -> &str { todo!() }

    /// Number of cached entries
    pub fn len(&self) -> usize { todo!() }

    /// Check if cache is empty
    pub fn is_empty(&self) -> bool { todo!() }
}

/// Context item with token estimate for progressive disclosure
#[derive(Debug)]
pub struct ContextItem {
    pub id: String,
    pub summary: String,
    pub tokens: usize,
    pub item_type: ContextItemType,
}

#[derive(Debug, Clone, Copy)]
pub enum ContextItemType {
    Task,
    Rule,
    Skill,
    Memory,
}

impl ContextItem {
    pub fn from_task(task: &Task) -> Self { todo!() }

    pub fn from_rule(rule: &Rule) -> Self { todo!() }

    pub fn from_skill(skill: &Skill) -> Self { todo!() }

    pub fn from_entry(entry: &Entry) -> Self { todo!() }
}

/// CAS usage reminder for MCP tools
pub(crate) const USAGE_REMINDER: &str = r#"## 📋 CAS Context

**Use CAS MCP tools for task/memory management (NOT built-in TodoWrite):**
- `mcp__cas__task` - Track work
- `mcp__cas__memory` - Store learnings
- `mcp__cas__search` - Find context

<IMPORTANT>
**When to use `memory` with action: remember (PROACTIVELY store learnings):**
- After discovering project-specific patterns or conventions
- After fixing non-trivial bugs (capture root cause + solution)
- After learning how unfamiliar code works
- When you find important architectural decisions
- After resolving configuration or setup issues

Don't wait to be asked - if you learned something valuable, store it immediately.
</IMPORTANT>

**Search guidance:**
- For exploratory searches ("where is X handled?", "how does Y work?"), prefer `mcp__cas__search` - it combines code + tasks + memories with semantic understanding
- For exact pattern matching (specific regex, literal strings), use Grep directly
"#;

/// Stores required for context building
pub struct ContextStores<'a> {
    /// Global entry store (optional)
    pub global_store: Option<&'a dyn Store>,
    /// Project entry store (optional)
    pub project_store: Option<&'a dyn Store>,
    /// Global rule store (optional)
    pub global_rule_store: Option<&'a dyn RuleStore>,
    /// Project rule store (optional)
    pub project_rule_store: Option<&'a dyn RuleStore>,
    /// Task store (project only)
    pub task_store: Option<&'a dyn TaskStore>,
    /// Agent store (project only)
    pub agent_store: Option<&'a dyn AgentStore>,
    /// Global skill store (optional)
    pub global_skill_store: Option<&'a dyn SkillStore>,
    /// Project skill store (optional)
    pub project_skill_store: Option<&'a dyn SkillStore>,
    /// Entry scorer for context selection (optional, defaults to BasicContextScorer)
    pub entry_scorer: Option<&'a dyn ContextScorer>,
    /// Rule match cache for avoiding repeated glob parsing (optional)
    pub rule_match_cache: Option<&'a RuleMatchCache>,
    /// Recent files from session (for context query boosting)
    pub recent_files: Vec<String>,
}

impl<'a> ContextStores<'a> {
    /// Create empty stores (for testing)
    pub fn empty() -> Self { todo!() }

    /// Get primary store (project preferred, then global)
    pub fn primary_store(&self) -> Option<&'a dyn Store> { todo!() }

    /// Get primary rule store (project preferred, then global)
    pub fn primary_rule_store(&self) -> Option<&'a dyn RuleStore> { todo!() }
}

/// Merge entries from both global and project stores
pub(crate) fn merge_entries(stores: &ContextStores) -> Vec<Entry> { todo!() }

/// Merge rules from both global and project stores
pub(crate) fn merge_rules(stores: &ContextStores) -> Vec<Rule> { todo!() }

/// Merge skills from both global and project stores
pub(crate) fn merge_skills(stores: &ContextStores) -> Vec<Skill> { todo!() }

/// Context building statistics (for tracing/metrics)
#[derive(Debug, Default)]
pub struct ContextStats {
    pub tasks_included: usize,
    pub rules_included: usize,
    pub skills_included: usize,
    pub memories_included: usize,
    pub pinned_included: usize,
    pub total_tokens: usize,
    pub items_omitted: usize,
}

/// Optional callback for surfaced items (for feedback tracking)
pub type SurfacedItemCallback = Box<dyn Fn(&str, &str, Option<&str>)>;

mod build_start;
mod coordination;
mod plan_mode;

#[cfg(test)]
mod tests;

pub use build_start::build_context_with_stores;
pub(crate) use coordination::{render_factory_coordination, render_normal_coordination};
pub use plan_mode::build_plan_context_with_stores;

#[cfg(test)]
pub(crate) use coordination::is_factory_participant;
