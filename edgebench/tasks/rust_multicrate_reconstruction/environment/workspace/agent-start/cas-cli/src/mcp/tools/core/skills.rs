use crate::mcp::tools::core::imports::*;

impl CasCore {
    // ========================================================================
    // Skill Tools (10)
    // ========================================================================

    /// List enabled skills
    pub async fn cas_skill_list(&self) -> Result<CallToolResult, McpError> { todo!() }

    /// Show skill details
    /// Checks database first, then falls back to .claude/skills/ files
    pub async fn cas_skill_show(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Create a new skill
    pub async fn cas_skill_create(
        &self,
        Parameters(req): Parameters<SkillCreateRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Enable a skill
    pub async fn cas_skill_enable(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Disable a skill
    pub async fn cas_skill_disable(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Record skill usage
    pub async fn cas_skill_use(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Sync skills to Claude Code
    pub async fn cas_skill_sync(&self) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // Additional Skill Tools
    // ========================================================================

    /// Update a skill
    pub async fn cas_skill_update(
        &self,
        Parameters(req): Parameters<SkillUpdateRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Delete a skill
    pub async fn cas_skill_delete(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List all skills (including disabled)
    /// Merges skills from database and .claude/skills/ directory
    pub async fn cas_skill_list_all(
        &self,
        Parameters(req): Parameters<LimitRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
