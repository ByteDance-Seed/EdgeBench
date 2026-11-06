//! Rule type definitions

// Dead code check enabled - all items used

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;
use crate::scope::Scope;

/// Category of a rule - helps with filtering and prioritization
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum RuleCategory {
    /// General purpose rule
    #[default]
    General,
    /// Naming conventions, code style patterns
    Convention,
    /// Security-related guidelines
    Security,
    /// Performance optimization patterns
    Performance,
    /// Architectural patterns and boundaries
    Architecture,
    /// Error handling patterns
    ErrorHandling,
}

impl fmt::Display for RuleCategory {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for RuleCategory {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Status of a rule in its lifecycle
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum RuleStatus {
    /// New, unproven rule
    #[default]
    Draft,
    /// Proven rule, synced to Claude Code
    Proven,
    /// Not accessed recently
    Stale,
    /// Explicitly disabled
    Retired,
}

impl fmt::Display for RuleStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for RuleStatus {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// A rule extracted from memory entries
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Rule {
    /// Unique identifier in scope-rule-NNN format (e.g., g-rule-001 or p-rule-001)
    pub id: String,

    /// Storage scope (global or project)
    /// Global: user style preferences stored in ~/.config/cas/
    /// Project: project-specific conventions stored in ./.cas/
    #[serde(default)]
    pub scope: Scope,

    /// When the rule was created
    pub created: DateTime<Utc>,

    /// Entry IDs this rule was extracted from
    #[serde(default)]
    pub source_ids: Vec<String>,

    /// The rule description/content
    pub content: String,

    /// Current status of the rule
    #[serde(default)]
    pub status: RuleStatus,

    /// Number of times marked helpful
    #[serde(default)]
    pub helpful_count: i32,

    /// Number of times marked harmful
    #[serde(default)]
    pub harmful_count: i32,

    /// Optional categorization tags
    #[serde(default)]
    pub tags: Vec<String>,

    /// File pattern glob for rule applicability
    #[serde(default)]
    pub paths: String,

    /// Last time the rule was accessed
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub last_accessed: Option<DateTime<Utc>>,

    /// When the rule should be reviewed
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub review_after: Option<DateTime<Utc>>,

    /// Hook command to execute (e.g., linter) when files matching paths are edited
    /// If set, this rule becomes a "linter rule" that triggers the command
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub hook_command: Option<String>,

    /// Rule category for filtering and prioritization
    #[serde(default)]
    pub category: RuleCategory,

    /// Rule priority: 0=critical (always surface), 1=high, 2=normal (default), 3=low
    /// Critical rules bypass token budget limits
    #[serde(default = "default_priority")]
    pub priority: u8,

    /// Number of times this rule has been surfaced in context
    /// Tracked separately from helpful_count to enable quality-gated promotion
    #[serde(default)]
    pub surface_count: i32,

    /// Comma-separated list of tools to auto-approve when this rule matches
    /// Only applies to proven rules. Example: "Read,Glob,Grep"
    /// Dangerous tools (Bash, Write, Edit) cannot be auto-approved via rules.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub auto_approve_tools: Option<String>,

    /// Glob patterns for paths that trigger auto-approval (separate from matching paths)
    /// When a tool operates on files matching these patterns AND the tool is in
    /// auto_approve_tools, the operation is auto-approved.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub auto_approve_paths: Option<String>,

    /// Team ID this rule belongs to (None = personal/not shared with team)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub team_id: Option<String>,
}

fn default_priority() -> u8 { todo!() }

impl Rule {
    /// Create a new rule with the given content (defaults to project scope)
    pub fn new(id: String, content: String) -> Self { todo!() }

    /// Create a new rule with explicit scope
    pub fn with_scope(id: String, content: String, scope: Scope) -> Self { todo!() }

    /// Check if this is a critical rule (priority 0) that should always be surfaced
    pub fn is_critical(&self) -> bool { todo!() }

    /// Check if this is a security rule
    pub fn is_security(&self) -> bool { todo!() }

    /// Check if this rule has a hook command (is a linter rule)
    pub fn is_linter_rule(&self) -> bool { todo!() }

    /// Tools that are considered safe for auto-approval
    pub const SAFE_AUTO_APPROVE_TOOLS: &'static [&'static str] =
        &["Read", "Glob", "Grep", "WebFetch", "WebSearch"];

    /// Tools that are too dangerous to ever auto-approve via rules
    pub const DANGEROUS_TOOLS: &'static [&'static str] = &["Bash", "Write", "Edit", "NotebookEdit"];

    /// Check if this rule has auto-approval configured
    pub fn has_auto_approve(&self) -> bool { todo!() }

    /// Get the list of tools configured for auto-approval
    pub fn get_auto_approve_tools(&self) -> Vec<&str> { todo!() }

    /// Check if a specific tool is auto-approved by this rule
    pub fn auto_approves_tool(&self, tool_name: &str) -> bool { todo!() }

    /// Validate the auto_approve_tools configuration
    /// Returns Ok if valid, Err with a message describing the problem
    pub fn validate_auto_approve(&self) -> Result<(), String> { todo!() }

    /// Check if this rule can be used for auto-approval
    /// Rules must be proven and have valid auto-approve configuration
    pub fn can_auto_approve(&self) -> bool { todo!() }

    /// Get the list of paths configured for auto-approval
    pub fn get_auto_approve_paths(&self) -> Vec<&str> { todo!() }

    /// Check if a path matches the auto-approval patterns
    pub fn matches_auto_approve_path(&self, path: &str) -> bool { todo!() }

    /// Calculate the feedback score (helpful - harmful)
    pub fn feedback_score(&self) -> i32 { todo!() }

    /// Check if the rule is active (not retired)
    pub fn is_active(&self) -> bool { todo!() }

    /// Check if the rule needs review
    pub fn needs_review(&self) -> bool { todo!() }

    /// Get a short preview of the content
    pub fn preview(&self, max_len: usize) -> String { todo!() }
}

impl Default for Rule {
    fn default() -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::rule::*;


    #[test]
    fn test_is_active() {
        let mut rule = Rule::new("rule-001".to_string(), "test".to_string());
        assert!(rule.is_active());

        rule.status = RuleStatus::Retired;
        assert!(!rule.is_active());
    }

    #[test]
    fn test_feedback_score() {
        let mut rule = Rule::new("rule-001".to_string(), "test".to_string());
        rule.helpful_count = 10;
        rule.harmful_count = 3;
        assert_eq!(rule.feedback_score(), 7);
    }

    #[test]
    fn test_is_linter_rule() {
        let mut rule = Rule::new("rule-001".to_string(), "test".to_string());
        assert!(!rule.is_linter_rule());

        rule.hook_command = Some("cargo fmt".to_string());
        assert!(rule.is_linter_rule());
    }

    #[test]
    fn test_auto_approve_tools() {
        let mut rule = Rule::new("rule-001".to_string(), "test".to_string());
        assert!(!rule.has_auto_approve());
        assert!(rule.get_auto_approve_tools().is_empty());

        rule.auto_approve_tools = Some("Read, Glob, Grep".to_string());
        assert!(rule.has_auto_approve());
        assert_eq!(rule.get_auto_approve_tools(), vec!["Read", "Glob", "Grep"]);
        assert!(rule.auto_approves_tool("Read"));
        assert!(rule.auto_approves_tool("read")); // case insensitive
        assert!(!rule.auto_approves_tool("Write"));
    }

    #[test]
    fn test_validate_auto_approve_rejects_dangerous() {
        let mut rule = Rule::new("rule-001".to_string(), "test".to_string());

        // Safe tools should pass
        rule.auto_approve_tools = Some("Read,Glob".to_string());
        assert!(rule.validate_auto_approve().is_ok());

        // Dangerous tools should fail
        rule.auto_approve_tools = Some("Bash".to_string());
        assert!(rule.validate_auto_approve().is_err());

        rule.auto_approve_tools = Some("Read,Write".to_string());
        assert!(rule.validate_auto_approve().is_err());

        rule.auto_approve_tools = Some("Edit".to_string());
        assert!(rule.validate_auto_approve().is_err());
    }

    #[test]
    fn test_can_auto_approve() {
        let mut rule = Rule::new("rule-001".to_string(), "test".to_string());
        rule.auto_approve_tools = Some("Read,Glob".to_string());

        // Draft rules cannot auto-approve
        assert!(!rule.can_auto_approve());

        // Proven rules with valid config can auto-approve
        rule.status = RuleStatus::Proven;
        assert!(rule.can_auto_approve());

        // Proven rules with dangerous tools cannot auto-approve
        rule.auto_approve_tools = Some("Bash".to_string());
        assert!(!rule.can_auto_approve());
    }
}
