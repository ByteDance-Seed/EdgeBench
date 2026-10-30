use crate::mcp::tools::core::imports::*;

impl CasCore {
    /// Create a new CAS service with daemon support
    pub fn with_daemon(
        cas_root: std::path::PathBuf,
        activity: Option<std::sync::Arc<ActivityTracker>>,
        daemon: Option<std::sync::Arc<EmbeddedDaemon>>,
    ) -> Self { todo!() }

    /// Get the project store path
    pub fn project_path(&self) -> &std::path::Path { todo!() }

    /// Pre-set the agent ID (for testing where no daemon is running)
    ///
    /// In production, the agent_id is discovered lazily via daemon socket query.
    /// In tests, there's no daemon, so we pre-set the agent_id directly.
    pub fn set_agent_id_for_testing(&self, agent_id: String) { todo!() }

    // ========================================================================
    // Workflow Guidance (injected on task start/claim)
    // ========================================================================

    /// Generate workflow guidance to show when starting or claiming a task
    pub(super) fn workflow_guidance() -> String { todo!() }

    // ========================================================================
    // Memory Tools (12)
    // ========================================================================

    /// Store a new memory
    pub async fn cas_remember(
        &self,
        Parameters(req): Parameters<RememberRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Get an entry by ID
    ///
    /// Also tracks access for session-aware context boosting:
    /// - Updates `last_accessed` timestamp
    /// - Increments `access_count`
    /// - Reinforces memory stability
    pub async fn cas_get(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Mark entry as helpful
    pub async fn cas_helpful(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Mark entry as harmful
    pub async fn cas_harmful(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Mark entry as reviewed (sets last_reviewed timestamp)
    pub async fn cas_mark_reviewed(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List recent entries
    pub async fn cas_recent(
        &self,
        Parameters(req): Parameters<RecentRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Delete an entry
    pub async fn cas_delete(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// List all entries
    pub async fn cas_list(
        &self,
        Parameters(req): Parameters<LimitRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Archive an entry
    pub async fn cas_archive(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Unarchive an entry
    pub async fn cas_unarchive(
        &self,
        Parameters(req): Parameters<IdRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    /// Update an entry
    pub async fn cas_update(
        &self,
        Parameters(req): Parameters<EntryUpdateRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}
