//! MCP Server implementation for CAS

use std::borrow::Cow;
use std::path::PathBuf;
use std::sync::{Arc, OnceLock, RwLock};

use rmcp::ErrorData as McpError;
use rmcp::model::{CallToolResult, Content, ErrorCode};
use rmcp::service::Peer;
use rmcp::service::RoleServer;

use crate::config::Config;
use crate::harness_policy::verification_required_for_task_type;
use crate::store::{
    AgentStore, EntityStore, RuleStore, SkillStore, Store, TaskStore, VerificationStore,
    WorktreeStore, open_agent_store, open_entity_store, open_rule_store, open_skill_store,
    open_store, open_task_store, open_verification_store, open_worktree_store,
};
use crate::types::TaskStatus;
use cas_core::SearchIndex;
use cas_core::{SkillSyncer, Syncer};
use tracing::{debug, info, warn};

use crate::mcp::daemon::{ActivityTracker, EmbeddedDaemon, EmbeddedDaemonStatus};

/// Core CAS service - provides store access and helper methods
///
/// Supports two-tier storage architecture:
/// - Global store (~/.config/cas/) - user preferences, general learnings
///
/// CAS requires a project-scoped `.cas/` directory (created via `cas init`).
///
/// Store instances are cached in `OnceLock` fields so each store type is
/// opened exactly once per MCP server lifetime, eliminating repeated
/// connection opens on every tool call.
#[derive(Clone)]
pub struct CasCore {
    /// Project CAS directory (./.cas/)
    pub(crate) cas_root: PathBuf,
    /// Activity tracker for idle detection
    pub(crate) activity: Option<Arc<ActivityTracker>>,
    /// Reference to the embedded daemon (if running)
    pub(crate) daemon: Option<Arc<EmbeddedDaemon>>,
    /// Agent ID for multi-agent coordination (lazily initialized on first tool call)
    pub(crate) agent_id: OnceLock<Option<String>>,
    /// Peer reference for sending MCP notifications (Claude Code 2.1.0+)
    /// Captured on first request, used to notify client of resource changes
    pub(crate) peer: Arc<RwLock<Option<Peer<RoleServer>>>>,
    // Cached store instances (lazily initialized, one per store type)
    pub(crate) cached_store: OnceLock<Arc<dyn Store>>,
    pub(crate) cached_rule_store: OnceLock<Arc<dyn RuleStore>>,
    pub(crate) cached_task_store: OnceLock<Arc<dyn TaskStore>>,
    pub(crate) cached_skill_store: OnceLock<Arc<dyn SkillStore>>,
    pub(crate) cached_entity_store: OnceLock<Arc<dyn EntityStore>>,
    pub(crate) cached_agent_store: OnceLock<Arc<dyn AgentStore>>,
    pub(crate) cached_verification_store: OnceLock<Arc<dyn VerificationStore>>,
    pub(crate) cached_worktree_store: OnceLock<Arc<dyn WorktreeStore>>,
}

impl CasCore {
    /// Helper: get cached store or initialize it.
    /// Safe for concurrent access — if two threads race, one wins and the other
    /// gets the canonical instance from `get()`.
    fn cached_or_init<T: Clone>(
        cell: &OnceLock<T>,
        init: impl FnOnce() -> Result<T, McpError>,
    ) -> Result<T, McpError> { todo!() }

    /// Get store (cached — opened once per server lifetime)
    pub(crate) fn open_store(&self) -> Result<Arc<dyn Store>, McpError> { todo!() }

    /// Get rule store (cached)
    pub(crate) fn open_rule_store(&self) -> Result<Arc<dyn RuleStore>, McpError> { todo!() }

    /// Get task store (cached)
    pub(crate) fn open_task_store(&self) -> Result<Arc<dyn TaskStore>, McpError> { todo!() }

    /// Get skill store (cached)
    pub(crate) fn open_skill_store(&self) -> Result<Arc<dyn SkillStore>, McpError> { todo!() }

    /// Get entity store (cached)
    pub(crate) fn open_entity_store(&self) -> Result<Arc<dyn EntityStore>, McpError> { todo!() }

    /// Get agent store (cached)
    pub(crate) fn open_agent_store(&self) -> Result<Arc<dyn AgentStore>, McpError> { todo!() }

    /// Get verification store (cached)
    pub(crate) fn open_verification_store(&self) -> Result<Arc<dyn VerificationStore>, McpError> { todo!() }

    /// Get worktree store (cached)
    pub(crate) fn open_worktree_store(&self) -> Result<Arc<dyn WorktreeStore>, McpError> { todo!() }

    /// Get worktree manager (for workspace lifecycle operations)
    pub(crate) fn worktree_manager(&self) -> Option<crate::worktree::WorktreeManager> { todo!() }

    /// Detect current worktree branch for scoping entries
    ///
    /// Returns Some(branch) if:
    /// 1. Worktrees are enabled in config
    /// 2. We're currently in a CAS-managed git worktree
    ///
    /// This is used to auto-set the branch field on new entries for virtual isolation.
    pub(crate) fn current_worktree_branch(&self) -> Option<String> { todo!() }

    /// Get search index
    pub(crate) fn open_search_index(&self) -> Result<SearchIndex, McpError> { todo!() }

    /// Create success result with text content
    pub(crate) fn success(text: impl Into<String>) -> CallToolResult { todo!() }

    /// Create tool error result (tool succeeded but operation failed)
    /// This sets is_error: true so Claude knows to handle the failure
    pub(crate) fn tool_error(text: impl Into<String>) -> CallToolResult { todo!() }

    /// Create error result
    pub(crate) fn error(code: ErrorCode, message: impl Into<String>) -> McpError { todo!() }

    /// Record activity (for idle detection)
    pub(crate) fn touch(&self) { todo!() }

    /// Notify client that resource list has changed (Claude Code 2.1.0+)
    ///
    /// Call this after any state-modifying operation (create, update, delete)
    /// so Claude Code can refresh its resource list.
    pub(crate) async fn notify_resources_changed(&self) { todo!() }

    /// Get daemon status
    pub(crate) async fn daemon_status(&self) -> Option<EmbeddedDaemonStatus> { todo!() }

    /// Trigger immediate maintenance
    pub(crate) async fn trigger_maintenance(&self) -> Result<String, McpError> { todo!() }

    /// Load and return config
    pub(crate) fn load_config(&self) -> Config { todo!() }

    /// Get the registered agent ID, auto-registering if a session file exists
    ///
    /// This method implements lazy auto-registration with auto-revival:
    /// 1. If already registered, check if agent is active and revive if needed
    /// 2. If not registered, try to read session_id from PPID-keyed file (written by SessionStart hook)
    /// 3. If session file missing, try PPID fallback to find existing agent
    /// 4. Auto-register with that session_id
    ///
    /// This ensures agents are always registered and active without requiring explicit registration calls.
    pub(crate) fn get_agent_id(&self) -> Result<String, McpError> { todo!() }

    /// Ensure agent is active, reviving if necessary
    ///
    /// Called from get_agent_id() to auto-revive stale/shutdown agents on MCP tool use.
    pub(crate) fn ensure_agent_active(&self, agent_id: &str) -> Result<(), McpError> { todo!() }

    /// Register an agent with session_id as the canonical identifier
    ///
    /// This must be called before other CAS tools can be used.
    /// The session_id becomes the agent's unique identifier.
    ///
    /// The agent's role is determined from the CAS_AGENT_ROLE environment variable
    /// (set by factory mode when spawning workers/supervisors).
    pub(crate) fn register_agent(
        &self,
        session_id: String,
        name: String,
        parent_id: Option<String>,
    ) -> Result<String, McpError> { todo!() }

    pub(crate) fn register_agent_with_hints(
        &self,
        session_id: String,
        name: String,
        parent_id: Option<String>,
        agent_type_hint: Option<crate::types::AgentType>,
        role_hint: Option<crate::types::AgentRole>,
    ) -> Result<String, McpError> { todo!() }

    /// Check if a tool action is authorized for the current agent.
    ///
    /// Enforces verification jail: when an agent has pending_verification=true
    /// on any leased task, mutating operations are blocked.
    ///
    /// Policy:
    /// - Non-mutating operations: always allowed
    /// - Verification tool: always allowed (escape hatch from jail)
    /// - Agent tool: always allowed (needed for communication/coordination)
    /// - System/factory/team/worktree tools: always allowed (infrastructure)
    /// - Task notes: allowed even when jailed (progress reporting)
    /// - All other mutating operations: blocked when jailed
    ///
    /// Returns Ok(()) if allowed, or Err with VERIFICATION_JAIL_BLOCKED code if blocked.
    pub(crate) fn authorize_agent_action(
        &self,
        tool: &str,
        action: &str,
        is_mutating: bool,
    ) -> Result<(), McpError> { todo!() }

    /// Check if an agent has any tasks with pending verification
    ///
    /// Returns Some((task_id, task_title)) if the agent has an in-progress task
    /// that requires verification but hasn't been verified yet.
    /// Returns None if the agent can proceed with new tasks.
    pub(crate) fn check_pending_verification(
        &self,
        agent_id: &str,
    ) -> Result<Option<(String, String)>, McpError> { todo!() }

    /// Auto-claim a task when verification is required/failed
    /// This ensures the Stop hook can block exit for unverified tasks
    pub(crate) fn auto_claim_for_verification(
        &self,
        task_id: &str,
        task_store: &dyn TaskStore,
    ) -> Result<(), McpError> { todo!() }

    /// Sync rules to Claude Code
    pub(crate) fn sync_rules(&self) -> Result<usize, McpError> { todo!() }

    /// Sync skills to Claude Code
    pub(crate) fn sync_skills(&self) -> Result<usize, McpError> { todo!() }

    /// Promote entries from a specific branch to parent scope (clear branch field)
    ///
    /// Used when a worktree is merged - entries created in that worktree
    /// become visible in the parent context.
    pub(crate) fn promote_branch_entries(&self, branch: &str) -> Result<usize, McpError> { todo!() }
}

mod prompts;
mod resources;
mod runtime;

pub use runtime::run_server;
#[cfg(feature = "mcp-proxy")]
pub use runtime::write_proxy_catalog_cache;
