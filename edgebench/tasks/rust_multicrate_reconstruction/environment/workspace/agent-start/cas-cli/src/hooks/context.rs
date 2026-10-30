//! Context building wrappers for CLI
//!
//! This module provides CLI-specific wrappers around the core context building
//! functions from `cas-core::hooks::context`. These wrappers handle:
//!
//! - Opening stores from the filesystem
//! - Loading configuration
//! - DevTracer integration for tracing
//! - Feedback nudging
//! - AI-powered context selection (via claude CLI)
//! - Hybrid search scoring for semantic context selection
//!
//! The core logic lives in `cas-core::hooks::context`.

use std::process::Command;
use std::sync::Arc;

use cas_code::{CodeSymbol, SymbolKind};
use cas_core::hooks::{
    ContextScorer, ContextStores, HookInput, HooksConfig, RuleMatchCache, SurfacedItemCallback,
    build_context_with_stores, build_plan_context_with_stores, estimate_tokens, rule_matches_path,
    token_display, truncate,
};
use cas_store::{AgentStore, RuleStore, SkillStore, Store, TaskStore};
use cas_types::{Entry, Rule, RuleStatus, Skill, Task, TaskStatus};

use crate::hooks::get_session_files;
use crate::hooks::scorer::HybridContextScorer;

use std::path::Path;

use crate::config::Config;
use crate::error::MemError;
use crate::store::{
    open_agent_store, open_code_store, open_rule_store, open_skill_store, open_store,
    open_task_store,
};

/// Build context string for session start injection
///
/// This is the main entry point for CLI usage. It:
/// 1. Opens stores from project directory
/// 2. Loads configuration
/// 3. Calls the core context builder from cas-core
/// 4. Records tracing information
/// 5. Handles feedback nudging
pub fn build_context(input: &HookInput, limit: usize, cas_root: &Path) -> Result<String, MemError> { todo!() }

/// Build context with AI-powered prioritization
///
/// Uses Claude CLI to select the most relevant context items.
pub fn build_context_ai(
    input: &HookInput,
    limit: usize,
    cas_root: &Path,
) -> Result<String, MemError> { todo!() }

/// Build context optimized for plan mode
pub fn build_plan_context(
    input: &HookInput,
    limit: usize,
    cas_root: &Path,
) -> Result<String, MemError> { todo!() }

/// Candidate item for AI prioritization
#[derive(Debug, Clone)]
pub struct ContextCandidate {
    pub id: String,
    pub item_type: String,
    pub summary: String,
    pub tokens: usize,
    pub priority: i32,
}

impl ContextCandidate {
    fn from_task(task: &Task) -> Self { todo!() }

    fn from_rule(rule: &Rule) -> Self { todo!() }

    fn from_skill(skill: &Skill) -> Self { todo!() }

    fn from_entry(entry: &Entry) -> Self { todo!() }

    fn from_code_symbol(symbol: &CodeSymbol) -> Self { todo!() }
}

/// Build AI prompt for context prioritization
fn build_ai_prioritization_prompt(
    candidates: &[ContextCandidate],
    cwd: &str,
    token_budget: usize,
) -> String { todo!() }

/// Parse AI response to extract selected item IDs
fn parse_ai_selection(response: &str) -> Vec<String> { todo!() }

/// Call Claude to select context items
fn call_claude_for_selection(prompt: &str, model: &str) -> Result<String, MemError> { todo!() }

/// Fetch personal patterns from CAS Cloud and format as context section.
///
/// Returns empty string if not logged in, no patterns, or on any error.
/// Failures are silent — personal patterns are optional enhancement.
fn fetch_personal_patterns_for_context() -> Result<String, MemError> { todo!() }

/// Fetch new team suggestions from CAS Cloud and format as context section.
///
/// Only shows pending (not yet adopted/dismissed) suggestions.
/// Returns empty string if not in a team, no suggestions, or on any error.
/// Failures are silent — team suggestions are optional enhancement.
fn fetch_team_suggestions_for_context() -> Result<String, MemError> { todo!() }

/// Build the MCP proxy tools section from the cached catalog file.
///
/// Reads `.cas/proxy_catalog.json` (written by the MCP server on startup/reload)
/// and formats a concise section listing connected servers and their tools.
/// Returns empty string if no cache file exists or it's empty.
fn build_mcp_tools_section(cas_root: &Path) -> String { todo!() }

#[cfg(test)]
mod tests {
    use crate::hooks::context::*;

    #[test]
    fn test_parse_ai_selection_json() {
        let response = r#"{"selected": ["cas-1234", "rule-001", "cas-5678"], "reasoning": "Selected based on relevance"}"#;
        let ids = parse_ai_selection(response);
        assert_eq!(ids, vec!["cas-1234", "rule-001", "cas-5678"]);
    }

    #[test]
    fn test_parse_ai_selection_with_text() {
        let response =
            "Here are the selected items:\n{\"selected\": [\"cas-abcd\"]}\nHope this helps!";
        let ids = parse_ai_selection(response);
        assert_eq!(ids, vec!["cas-abcd"]);
    }

    #[test]
    fn test_parse_ai_selection_fallback() {
        let response = "I recommend cas-1234 and rule-005 for this session.";
        let ids = parse_ai_selection(response);
        assert!(ids.contains(&"cas-1234".to_string()));
        assert!(ids.contains(&"rule-005".to_string()));
    }

    #[test]
    fn test_context_candidate_priority() {
        let mut task = Task {
            status: TaskStatus::InProgress,
            id: "test".to_string(),
            ..Default::default()
        };
        let candidate = ContextCandidate::from_task(&task);
        assert!(candidate.priority > 100); // In progress gets 100 + priority bonus

        task.status = TaskStatus::Open;
        let candidate2 = ContextCandidate::from_task(&task);
        assert!(candidate.priority > candidate2.priority);
    }

    #[test]
    fn test_build_mcp_tools_section_with_cache() {
        let dir = tempfile::tempdir().unwrap();
        let cache_path = dir.path().join("proxy_catalog.json");

        // No cache file → empty string
        assert!(build_mcp_tools_section(dir.path()).is_empty());

        // Empty servers → empty string
        std::fs::write(&cache_path, "{}").unwrap();
        assert!(build_mcp_tools_section(dir.path()).is_empty());

        // Valid catalog
        let catalog = serde_json::json!({
            "chrome-devtools": ["navigate_page", "take_screenshot", "click", "type_text"],
            "github": ["list_issues", "create_pr"]
        });
        std::fs::write(&cache_path, catalog.to_string()).unwrap();
        let section = build_mcp_tools_section(dir.path());
        assert!(section.contains("Connected MCP Tools"));
        assert!(section.contains("2 servers"));
        assert!(section.contains("6 tools"));
        assert!(section.contains("chrome-devtools"));
        assert!(section.contains("navigate_page"));
        assert!(section.contains("github"));
        assert!(section.contains("mcp__cas__mcp_search"));
    }
}
