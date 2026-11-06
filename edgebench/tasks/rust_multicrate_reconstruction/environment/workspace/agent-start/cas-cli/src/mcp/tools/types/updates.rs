use rmcp::schemars::JsonSchema;
use serde::Deserialize;

#[derive(Debug, Deserialize, JsonSchema)]
pub struct EntryUpdateRequest {
    /// Entry ID to update
    #[schemars(description = "ID of the entry to update")]
    pub id: String,

    /// New content (optional)
    #[schemars(description = "New content for the entry")]
    #[serde(default)]
    pub content: Option<String>,

    /// New tags (optional)
    #[schemars(description = "Comma-separated tags (replaces existing)")]
    #[serde(default)]
    pub tags: Option<String>,

    /// New importance (optional)
    #[schemars(description = "New importance score (0.0-1.0)")]
    #[serde(default)]
    pub importance: Option<f32>,
}

#[derive(Debug, Deserialize, JsonSchema)]
pub struct RuleUpdateRequest {
    /// Rule ID
    #[schemars(description = "ID of the rule to update")]
    pub id: String,

    /// New content (optional)
    #[schemars(description = "New content for the rule")]
    #[serde(default)]
    pub content: Option<String>,

    /// New paths (optional)
    #[schemars(description = "New glob pattern for file matching")]
    #[serde(default)]
    pub paths: Option<String>,

    /// New tags (optional)
    #[schemars(description = "Comma-separated tags (replaces existing)")]
    #[serde(default)]
    pub tags: Option<String>,

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
// Skill Update Request
// ============================================================================

#[derive(Debug, Deserialize, JsonSchema)]
pub struct SkillUpdateRequest {
    /// Skill ID
    #[schemars(description = "ID of the skill to update")]
    pub id: String,

    /// New name (optional)
    #[schemars(description = "New name for the skill")]
    #[serde(default)]
    pub name: Option<String>,

    /// New description (optional) - full body content
    #[schemars(description = "Full skill instructions/content (goes in SKILL.md body)")]
    #[serde(default)]
    pub description: Option<String>,

    /// New invocation (optional)
    #[schemars(description = "New invocation command")]
    #[serde(default)]
    pub invocation: Option<String>,

    /// New tags (optional)
    #[schemars(description = "Comma-separated tags (replaces existing)")]
    #[serde(default)]
    pub tags: Option<String>,

    /// New summary (optional) - short trigger description for frontmatter
    #[schemars(
        description = "Short trigger description (1-2 lines) for SKILL.md frontmatter. Describes WHEN to use the skill."
    )]
    #[serde(default)]
    pub summary: Option<String>,

    /// Disable model invocation (Claude Code 2.1.3+)
    #[schemars(description = "Prevent skill from invoking the model (for command-only skills)")]
    #[serde(default)]
    pub disable_model_invocation: Option<bool>,
}
