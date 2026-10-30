//! MCP Tools Service for CAS
//!
//! This module exposes consolidated meta-tools:
//! - cas_memory: All memory/entry operations
//! - cas_task: All task and dependency operations
//! - cas_rule: All rule operations
//! - cas_skill: All skill operations
//! - cas_coordination: Agent, factory, and worktree operations (merged)
//! - cas_search: Search, context, and entity operations
//! - cas_system: Diagnostics, stats, and maintenance
//! - cas_verification: Task quality gates
//! - cas_team: Team collaboration
//! - cas_pattern: Personal patterns
//! - cas_spec: Specifications
//! - mcp_search: Search tools across connected upstream MCP servers
//! - mcp_execute: Execute tool calls across connected upstream MCP servers

use rmcp::handler::server::wrapper::Parameters;
use rmcp::model::{CallToolResult, ErrorCode};
#[cfg(feature = "mcp-proxy")]
use rmcp::model::Content;
use rmcp::{ErrorData as McpError, tool, tool_router};

use crate::mcp::server::CasCore;

mod imports;

// Re-export types from cas-mcp for MCP tool parameters
pub use cas_mcp::{
    AgentRequest, CoordinationRequest, ExecuteRequest, FactoryRequest, MemoryRequest,
    PatternRequest, RuleRequest, SearchContextRequest, SkillRequest, SpecRequest, SystemRequest,
    TaskRequest, TeamRequest, VerificationRequest,
};

// ============================================================================
// Git Blame Helper Types
// ============================================================================

/// A single line from git blame output
pub(super) struct GitBlameLine {
    pub(super) commit_hash: String,
    pub(super) line_number: usize,
    pub(super) author: String,
    pub(super) content: String,
}

/// Parse git blame porcelain format
pub(super) fn parse_git_blame_porcelain(content: &str) -> Vec<GitBlameLine> { todo!() }

pub(super) fn truncate_str(s: &str, max_len: usize) -> String { todo!() }

/// Internal worktree request type used by handler methods.
/// The MCP-facing type is CoordinationRequest; this is used for internal dispatch.
#[derive(Debug)]
pub struct WorktreeRequest {
    pub action: String,
    pub id: Option<String>,
    pub task_id: Option<String>,
    pub all: Option<bool>,
    pub status: Option<String>,
    pub orphans: Option<bool>,
    pub dry_run: Option<bool>,
    pub force: Option<bool>,
}

// ============================================================================
// Tool Router Implementation
// ============================================================================

use rmcp::handler::server::router::tool::ToolRouter;

/// CAS MCP service with consolidated meta-tools
///
/// Provides action-based tools that consolidate related operations,
/// reducing MCP tool context overhead. Agent, factory, and worktree
/// tools are merged into a single `coordination` tool.
///
/// When a proxy engine is configured (via `.cas/proxy.toml`), two additional
/// tools (`mcp_search` and `mcp_execute`) are exposed for routing through
/// upstream MCP servers.
#[derive(Clone)]
pub struct CasService {
    pub inner: CasCore,
    /// MCP proxy engine for upstream server aggregation (optional).
    #[cfg(feature = "mcp-proxy")]
    pub proxy: Option<std::sync::Arc<cmcp_core::ProxyEngine>>,
    /// Tool router used internally by rmcp's #[tool_router] macro
    #[allow(dead_code)]
    tool_router: ToolRouter<Self>,
}

impl CasService {
    pub fn new(
        inner: CasCore,
        #[cfg(feature = "mcp-proxy")] proxy: Option<std::sync::Arc<cmcp_core::ProxyEngine>>,
    ) -> Self { todo!() }

    #[allow(dead_code)]
    fn success(text: impl Into<String>) -> CallToolResult { todo!() }

    fn error(code: ErrorCode, message: impl Into<String>) -> McpError { todo!() }
}

#[tool_router]
impl CasService {
    // ========================================================================
    // cas_memory - All memory operations
    // ========================================================================

    #[tool(
        description = "Memory operations. Actions: remember (store new), get (by ID), list, update, delete, archive, unarchive, helpful, harmful, recent, set_tier (working/cold/archive), opinion_reinforce, opinion_weaken, opinion_contradict."
    )]
    pub async fn memory(
        &self,
        Parameters(req): Parameters<MemoryRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_task - All task operations
    // ========================================================================

    #[tool(
        description = "Task operations. Actions: create, show, update, start, close, reopen, delete, list, ready (actionable), blocked, notes (add progress), dep_add, dep_remove, dep_list, claim, release, transfer, available, mine. Prefer `start` for normal worker execution; use `claim` for manual lease control/recovery. IMPORTANT for 'close': verification must pass first. Workers should attempt close; if close returns verification-required guidance, follow the indicated verifier ownership workflow."
    )]
    pub async fn task(
        &self,
        Parameters(req): Parameters<TaskRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_rule - All rule operations
    // ========================================================================

    #[tool(
        description = "Rule operations. Actions: create, show, update, delete, list (proven only), list_all, helpful (promotes to proven), harmful, sync (to .claude/rules/), check_similar (find similar existing rules)."
    )]
    pub async fn rule(
        &self,
        Parameters(req): Parameters<RuleRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_skill - All skill operations
    // ========================================================================

    #[tool(
        description = "Skill operations. Actions: create, show, update, delete, list (enabled), list_all, enable, disable, sync (to .claude/skills/), use (record usage)."
    )]
    pub async fn skill(
        &self,
        Parameters(req): Parameters<SkillRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_coordination - Agent, factory, and worktree operations (merged)
    // ========================================================================

    #[tool(
        description = "Coordination operations combining agent, factory, and worktree management. Agent actions: register, unregister, whoami, heartbeat, agent_list, agent_cleanup, session_start, session_end, loop_start, loop_cancel, loop_status, lease_history, queue_notify, queue_poll, queue_peek, queue_ack, message. Factory actions: spawn_workers, shutdown_workers, worker_status, worker_activity, clear_context, my_context, sync_all_workers, gc_report, gc_cleanup, remind, remind_list, remind_cancel. Worktree actions: worktree_create, worktree_list, worktree_show, worktree_cleanup, worktree_merge, worktree_status. Only available in factory mode. For shutdown_workers, supervisor should verify worktree cleanliness/policy before issuing shutdown."
    )]
    pub async fn coordination(
        &self,
        Parameters(req): Parameters<CoordinationRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_search - Search, context, and entity operations
    // ========================================================================

    #[tool(
        description = "Search and context operations. Actions: search (BM25 full-text), context (session context), context_for_subagent, observe (record observation), entity_list, entity_show, entity_extract, code_search (search code symbols), code_show (show symbol details), grep, blame."
    )]
    pub async fn search(
        &self,
        Parameters(req): Parameters<SearchContextRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_system - System and maintenance operations
    // ========================================================================

    #[tool(
        description = "System operations. Actions: version (CAS version info), doctor (diagnostics), stats, info (system info), reindex (BM25 index), maintenance_run, maintenance_status, config_docs (full config reference), config_search (search configs by query), report_cas_bug (submit CAS bug to GitHub - ANONYMIZE DATA: remove paths, credentials, proprietary code before submitting), proxy_add (add upstream MCP server), proxy_remove (remove server), proxy_list (list servers)."
    )]
    pub async fn system(
        &self,
        Parameters(req): Parameters<SystemRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_verification - Verification operations (task quality gates)
    // ========================================================================

    #[tool(
        description = "Verification operations (task quality gates). Actions: add (record verification result), show (verification details), list (verifications for task), latest (most recent for task)."
    )]
    pub async fn verification(
        &self,
        Parameters(req): Parameters<VerificationRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_team - Team operations for multi-user collaboration
    // ========================================================================

    #[tool(
        description = "Team operations. Actions: list (teams user belongs to), show (team details and stats), members (list team members with roles), sync (trigger team push + pull)."
    )]
    pub async fn team(
        &self,
        Parameters(req): Parameters<TeamRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_pattern - Personal patterns (cross-project conventions)
    // ========================================================================

    #[tool(
        description = "Personal pattern operations (cross-project conventions). Actions: create (new pattern), list (with filters), show (by ID), update (modify fields), archive (soft delete), adopt (from rule), helpful (increment), harmful (increment). Team actions (require team_id): team_suggestions (list), team_new_suggestions (pending only), team_create_suggestion, team_share (share personal pattern), team_adopt (adopt suggestion), team_dismiss, team_recommend, team_archive_suggestion, team_suggestion_analytics."
    )]
    pub async fn pattern(
        &self,
        Parameters(req): Parameters<PatternRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // cas_spec - All spec operations
    // ========================================================================

    #[tool(
        description = "Spec operations. Actions: create, show, update, delete, list, approve, reject, supersede, link, unlink, sync."
    )]
    pub async fn spec(
        &self,
        Parameters(req): Parameters<SpecRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // mcp_search - Search across all connected MCP servers
    // ========================================================================

    #[tool(
        description = "Search across all tools from all connected MCP servers. Write TypeScript code to filter the tool catalog. A typed `tools` array is available with { server, name, description, input_schema } fields."
    )]
    pub async fn mcp_search(
        &self,
        #[allow(unused_variables)] Parameters(req): Parameters<ExecuteRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }

    // ========================================================================
    // mcp_execute - Execute tool calls across connected MCP servers
    // ========================================================================

    #[tool(
        description = "Execute TypeScript code that calls tools across all connected MCP servers. Each server is a typed global object (e.g. `canva`, `figma`) where every tool is an async function with typed parameters: `await server.tool_name({ param: value })`. Chain calls sequentially or run them in parallel with Promise.all across different servers."
    )]
    pub async fn mcp_execute(
        &self,
        #[allow(unused_variables)] Parameters(req): Parameters<ExecuteRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}

// ============================================================================
// Backwards-compatible wrapper methods for tests
// These are not exposed as MCP tools; use `coordination` tool instead.
// ============================================================================

impl CasService {
    /// Wrapper for factory operations (used by tests). Delegates to coordination.
    #[allow(dead_code)]
    pub async fn factory(
        &self,
        Parameters(req): Parameters<FactoryRequest>,
    ) -> Result<CallToolResult, McpError> { todo!() }
}

// ============================================================================
// Implementation methods - delegate to inner CasService
// ============================================================================

mod agent_search_system;
mod core;
mod factory_ops;
mod factory_remind;
mod pattern_ops;
mod server_handler;
mod spec_ops;
mod worktree_verification_team_ops;
