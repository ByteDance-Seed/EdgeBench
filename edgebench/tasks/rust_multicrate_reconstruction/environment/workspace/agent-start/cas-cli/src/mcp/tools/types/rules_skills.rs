use rmcp::schemars::JsonSchema;
use serde::Deserialize;

use crate::mcp::tools::types::defaults::{
    default_scope_global, default_scope_project, default_skill_type,
};

#[derive(Debug, Deserialize, JsonSchema)]
pub struct RuleCreateRequest {
    /// Rule content
    #[schemars(description = "The rule content/instruction")]
    pub content: String,

    /// Path patterns
    #[schemars(description = "Glob patterns for files this rule applies to (e.g., 'src/**/*.rs')")]
    #[serde(default)]
    pub paths: Option<String>,

    /// Tags
    #[schemars(description = "Comma-separated tags for categorization")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Storage scope
    #[schemars(
        description = "Scope: 'global' (user style) or 'project' (default, project conventions)"
    )]
    #[serde(default = "default_scope_project")]
    pub scope: String,

    /// Auto-approve tools
    #[schemars(
        description = "Tools to auto-approve (comma-separated, e.g., 'Read,Glob,Grep'). Only safe tools allowed."
    )]
    #[serde(default)]
    pub auto_approve_tools: Option<String>,

    /// Auto-approve paths
    #[schemars(description = "Path patterns for auto-approval (comma-separated globs)")]
    #[serde(default)]
    pub auto_approve_paths: Option<String>,
}

// ============================================================================
// Skill Create Request
// ============================================================================

#[derive(Debug, Deserialize, JsonSchema)]
pub struct SkillCreateRequest {
    /// Skill name
    #[schemars(description = "Human-readable name for the skill")]
    pub name: String,

    /// Description - full body content
    #[schemars(
        description = "Full skill instructions/content (goes in SKILL.md body). Include commands, code examples, guidelines."
    )]
    pub description: String,

    /// Invocation
    #[schemars(description = "How to invoke the skill (command, tool name, etc.)")]
    pub invocation: String,

    /// Skill type
    #[schemars(description = "Type: 'command' (default), 'mcp', 'plugin', 'internal'")]
    #[serde(default = "default_skill_type")]
    pub skill_type: String,

    /// Tags
    #[schemars(description = "Comma-separated tags")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Storage scope
    #[schemars(description = "Scope: 'global' (default) or 'project'")]
    #[serde(default = "default_scope_global")]
    pub scope: String,

    /// Short summary - trigger description for frontmatter
    #[schemars(
        description = "Short trigger description (1-2 lines) for SKILL.md frontmatter. Describes WHEN to use the skill."
    )]
    #[serde(default)]
    pub summary: Option<String>,

    /// Example usage
    #[schemars(description = "Example usage")]
    #[serde(default)]
    pub example: Option<String>,

    /// Pre-conditions (comma-separated)
    #[schemars(description = "Pre-conditions required")]
    #[serde(default)]
    pub preconditions: Option<String>,

    /// Post-conditions (comma-separated)
    #[schemars(description = "Expected post-conditions")]
    #[serde(default)]
    pub postconditions: Option<String>,

    /// Validation script
    #[schemars(description = "Script to check availability")]
    #[serde(default)]
    pub validation_script: Option<String>,

    /// Invokable via slash command
    #[schemars(description = "Enable /skill-name invocation")]
    #[serde(default)]
    pub invokable: bool,

    /// Argument hint
    #[schemars(description = "Argument hint for invocation")]
    #[serde(default)]
    pub argument_hint: Option<String>,

    /// Context mode
    #[schemars(description = "Context mode: 'fork' for forked context")]
    #[serde(default)]
    pub context_mode: Option<String>,

    /// Agent type
    #[schemars(description = "Agent type: 'Explore', 'code-reviewer', etc.")]
    #[serde(default)]
    pub agent_type: Option<String>,

    /// Allowed tools (comma-separated)
    #[schemars(description = "Allowed tools")]
    #[serde(default)]
    pub allowed_tools: Option<String>,

    /// Start as draft
    #[schemars(description = "Create as draft (not enabled)")]
    #[serde(default)]
    pub draft: bool,

    /// Disable model invocation (Claude Code 2.1.3+)
    #[schemars(description = "Prevent skill from invoking the model (for command-only skills)")]
    #[serde(default)]
    pub disable_model_invocation: bool,
}
