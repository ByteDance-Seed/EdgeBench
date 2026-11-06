use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// Unified search, context, and entity operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct SearchContextRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'search', 'context', 'context_for_subagent', 'observe', 'entity_list', 'entity_show', 'entity_extract', 'code_search', 'code_show', 'grep', 'blame'"
    )]
    pub action: String,

    /// Search query (for search)
    #[schemars(description = "Search query")]
    #[serde(default)]
    pub query: Option<String>,

    /// Document type filter: entry, task, rule, skill, code_symbol, code_file
    #[schemars(
        description = "Filter by type: 'entry', 'task', 'rule', 'skill', 'code_symbol', 'code_file'"
    )]
    #[serde(default)]
    pub doc_type: Option<String>,

    /// Task ID (for context with task focus)
    #[schemars(description = "Task ID for focused context")]
    #[serde(default)]
    pub task_id: Option<String>,

    /// Max tokens for context
    #[schemars(description = "Maximum tokens for context")]
    #[serde(default)]
    pub max_tokens: Option<usize>,

    /// Include related memories
    #[schemars(description = "Include related memories")]
    #[serde(default)]
    pub include_memories: Option<bool>,

    /// Observation content (for observe)
    #[schemars(description = "Content of the observation")]
    #[serde(default)]
    pub content: Option<String>,

    /// Observation type: general, decision, bugfix, feature, refactor, discovery
    #[schemars(
        description = "Observation type: 'general', 'decision', 'bugfix', 'feature', 'refactor', 'discovery'"
    )]
    #[serde(default)]
    pub observation_type: Option<String>,

    /// Source tool (for observe)
    #[schemars(description = "Tool that made the observation")]
    #[serde(default)]
    pub source_tool: Option<String>,

    /// Entity ID (for entity_show)
    #[schemars(description = "Entity ID")]
    #[serde(default)]
    pub id: Option<String>,

    /// Entity type filter: person, project, technology, file, concept, organization, domain
    #[schemars(
        description = "Entity type: 'person', 'project', 'technology', 'file', 'concept', 'organization', 'domain'"
    )]
    #[serde(default)]
    pub entity_type: Option<String>,

    /// Tags filter
    #[schemars(description = "Comma-separated tags")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Scope filter
    #[schemars(description = "Scope: 'global', 'project', or 'all'")]
    #[serde(default)]
    pub scope: Option<String>,

    /// Limit for list/search
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Sort field (for search)
    #[schemars(description = "Sort by: 'relevance' (default), 'created', 'updated'")]
    #[serde(default)]
    pub sort: Option<String>,

    /// Sort order (for search)
    #[schemars(description = "Sort order: 'asc' or 'desc' (default: desc)")]
    #[serde(default)]
    pub sort_order: Option<String>,

    // ========== Code Search Fields ==========
    /// Symbol kind filter (for code_search): function, struct, trait, enum, impl, method, const, type, module
    #[schemars(
        description = "Filter by symbol kind: 'function', 'struct', 'trait', 'enum', 'impl', 'method', 'const', 'type', 'module'"
    )]
    #[serde(default)]
    pub kind: Option<String>,

    /// Language filter (for code_search): rust, typescript, python, go
    #[schemars(description = "Filter by language: 'rust', 'typescript', 'python', 'go'")]
    #[serde(default)]
    pub language: Option<String>,

    /// Include source code in results (for code_search/code_show)
    #[schemars(description = "Include source code in results")]
    #[serde(default)]
    pub include_source: Option<bool>,

    /// Regex pattern for grep search
    #[schemars(description = "Regex pattern for grep action")]
    #[serde(default)]
    pub pattern: Option<String>,

    /// File glob pattern for grep (e.g., "*.rs", "src/**/*.ts")
    #[schemars(description = "File glob pattern to filter files (e.g., '*.rs', 'src/**/*.ts')")]
    #[serde(default)]
    pub glob: Option<String>,

    /// Lines of context before match (for grep)
    #[schemars(description = "Lines of context before each match (grep -B)")]
    #[serde(default)]
    pub before_context: Option<usize>,

    /// Lines of context after match (for grep)
    #[schemars(description = "Lines of context after each match (grep -A)")]
    #[serde(default)]
    pub after_context: Option<usize>,

    /// Case insensitive search (for grep)
    #[schemars(description = "Case insensitive search")]
    #[serde(default)]
    pub case_insensitive: Option<bool>,

    // ========== Blame Fields ==========
    /// File path for blame action (can include :line or :start-end)
    #[schemars(description = "File path to blame (optionally with :line or :start-end)")]
    #[serde(default)]
    pub file_path: Option<String>,

    /// Start line for blame range
    #[schemars(description = "Start line number for blame range")]
    #[serde(default)]
    pub line_start: Option<usize>,

    /// End line for blame range
    #[schemars(description = "End line number for blame range")]
    #[serde(default)]
    pub line_end: Option<usize>,

    /// Filter to only AI-generated lines (for blame)
    #[schemars(description = "Show only AI-generated lines")]
    #[serde(default)]
    pub ai_only: Option<bool>,

    /// Include full prompts in blame output
    #[schemars(description = "Include full prompts in blame output")]
    #[serde(default)]
    pub include_prompts: Option<bool>,

    /// Filter by session ID (for blame)
    #[schemars(description = "Filter blame by session ID")]
    #[serde(default)]
    pub session_id: Option<String>,
}

/// Unified system operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct SystemRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'version', 'doctor', 'stats', 'info', 'reindex', 'maintenance_run', 'maintenance_status', 'config_docs', 'config_search', 'report_cas_bug', 'proxy_add', 'proxy_remove', 'proxy_list'"
    )]
    pub action: String,

    /// Rebuild BM25 index (for reindex)
    #[schemars(description = "Rebuild BM25 full-text search index")]
    #[serde(default)]
    pub bm25: Option<bool>,

    /// Regenerate embeddings (deprecated - semantic search via cloud only)
    #[schemars(
        description = "Deprecated: embeddings are now cloud-only. This parameter is ignored."
    )]
    #[serde(default)]
    pub embeddings: Option<bool>,

    /// Only generate for entries missing embeddings (deprecated)
    #[schemars(
        description = "Deprecated: embeddings are now cloud-only. This parameter is ignored."
    )]
    #[serde(default)]
    pub missing_only: Option<bool>,

    /// Force maintenance run even if not idle
    #[schemars(description = "Force maintenance run even if not idle")]
    #[serde(default)]
    pub force: Option<bool>,

    /// Search query for config_search action
    #[schemars(
        description = "Search query for config_search (searches keys, descriptions, keywords, use cases)"
    )]
    #[serde(default)]
    pub query: Option<String>,

    // ========== Bug Reporting Fields (report_cas_bug) ==========
    /// Bug title (for report_cas_bug)
    #[schemars(
        description = "Brief title describing the bug (anonymize any project-specific info)"
    )]
    #[serde(default)]
    pub title: Option<String>,

    /// Bug description (for report_cas_bug)
    #[schemars(
        description = "Detailed description including steps to reproduce. IMPORTANT: Anonymize paths, remove credentials, avoid proprietary code"
    )]
    #[serde(default)]
    pub description: Option<String>,

    /// Expected behavior (for report_cas_bug)
    #[schemars(description = "What you expected to happen")]
    #[serde(default)]
    pub expected: Option<String>,

    /// Actual behavior (for report_cas_bug)
    #[schemars(description = "What actually happened (anonymize any sensitive output)")]
    #[serde(default)]
    pub actual: Option<String>,

    // ========== Proxy Management Fields (proxy_add/proxy_remove/proxy_list) ==========
    /// Server name for proxy operations
    #[schemars(description = "Server name for proxy_add/proxy_remove")]
    #[serde(default)]
    pub name: Option<String>,

    /// Transport type for proxy_add: 'stdio', 'http', or 'sse'
    #[schemars(description = "Transport type: 'stdio', 'http', or 'sse' (default: stdio)")]
    #[serde(default)]
    pub transport: Option<String>,

    /// URL for http/sse proxy servers
    #[schemars(description = "URL for http/sse transport")]
    #[serde(default)]
    pub url: Option<String>,

    /// Command for stdio proxy servers
    #[schemars(description = "Command for stdio transport")]
    #[serde(default)]
    pub command: Option<String>,

    /// Arguments for stdio proxy command (JSON array of strings)
    #[schemars(
        description = "Arguments for stdio command (JSON array of strings, e.g. '[\"--port\", \"3000\"]')"
    )]
    #[serde(default)]
    pub args: Option<String>,

    /// Environment variables for stdio proxy (JSON object)
    #[schemars(
        description = "Environment variables for stdio command (JSON object, e.g. '{\"API_KEY\": \"...\"}')"
    )]
    #[serde(default)]
    pub env: Option<String>,

    /// Auth token for http/sse proxy servers
    #[schemars(description = "Bearer auth token for http/sse transport")]
    #[serde(default)]
    pub auth: Option<String>,
}

/// Unified verification operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct VerificationRequest {
    /// Action to perform
    #[schemars(description = "Action: 'add', 'show', 'list', 'latest'")]
    pub action: String,

    /// Verification ID (for show)
    #[schemars(description = "Verification ID")]
    #[serde(default)]
    pub id: Option<String>,

    /// Task ID (for add, list, latest)
    #[schemars(description = "Task ID")]
    #[serde(default)]
    pub task_id: Option<String>,

    /// Status (for add): approved, rejected, error, skipped
    #[schemars(description = "Status: 'approved', 'rejected', 'error', 'skipped'")]
    #[serde(default)]
    pub status: Option<String>,

    /// Summary (for add)
    #[schemars(description = "Verification summary")]
    #[serde(default)]
    pub summary: Option<String>,

    /// Confidence score 0.0-1.0 (for add)
    #[schemars(description = "Confidence score from 0.0 to 1.0")]
    #[serde(default)]
    pub confidence: Option<f32>,

    /// Issues found as JSON array (for add)
    #[schemars(description = "JSON array of issues found")]
    #[serde(default)]
    pub issues: Option<String>,

    /// Files reviewed, comma-separated (for add)
    #[schemars(description = "Comma-separated list of files reviewed")]
    #[serde(default)]
    pub files: Option<String>,

    /// Duration of verification in milliseconds (for add)
    #[schemars(description = "Duration in milliseconds")]
    #[serde(default)]
    pub duration_ms: Option<u64>,

    /// Limit for list
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Verification type: 'task' (default) or 'epic'
    #[schemars(description = "Verification type: 'task' (default) or 'epic'")]
    #[serde(default)]
    pub verification_type: Option<String>,
}

/// Unified team operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct TeamRequest {
    /// Action to perform
    #[schemars(description = "Action: 'list', 'show', 'members', 'sync'")]
    pub action: String,

    /// Team ID (for show, members, sync)
    #[schemars(description = "Team ID for operations targeting a specific team")]
    #[serde(default)]
    pub team_id: Option<String>,

    /// Limit for list operations
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,
}

/// Unified factory operations request for dynamic worker management
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct FactoryRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'spawn_workers', 'shutdown_workers', 'worker_status', 'worker_activity', 'clear_context', 'my_context', 'sync_all_workers', 'gc_report', 'gc_cleanup', 'remind' (create reminder), 'remind_list' (list reminders), 'remind_cancel' (cancel a reminder)"
    )]
    pub action: String,

    /// Number of workers to spawn/shutdown
    #[schemars(
        description = "Number of workers (for spawn: how many to create, for shutdown: how many to stop, 0 = all)"
    )]
    #[serde(default)]
    pub count: Option<i32>,

    /// Specific worker names (comma-separated)
    #[schemars(
        description = "Comma-separated worker names (optional for spawn, specific targets for shutdown)"
    )]
    #[serde(default)]
    pub worker_names: Option<String>,

    /// Target agent for clear_context or remind
    #[schemars(
        description = "Target agent name for clear_context/remind (or 'all_workers' for broadcast). For remind: agent who receives the reminder (defaults to self)"
    )]
    #[serde(default)]
    pub target: Option<String>,

    /// Message text for remind
    #[schemars(description = "Message text for remind operations")]
    #[serde(default)]
    pub message: Option<String>,

    /// Supervisor policy hint for shutdown safety checks
    #[schemars(
        description = "Supervisor should verify worktree state before shutdown. Kept for compatibility (default: false)."
    )]
    #[serde(default)]
    pub force: Option<bool>,

    /// Branch/ref target for sync operations
    #[schemars(description = "Target branch/ref for sync actions (e.g., 'epic/my-epic')")]
    #[serde(default)]
    pub branch: Option<String>,

    /// Threshold used by cleanup/report actions (seconds)
    #[schemars(description = "Optional threshold in seconds for cleanup/report actions")]
    #[serde(default)]
    pub older_than_secs: Option<i64>,

    /// Whether spawned workers need isolated worktrees (git worktree per worker)
    #[schemars(
        description = "Whether workers need to be isolated in their own git worktrees. When true, each worker gets its own branch and working directory. When false or omitted, workers share the main working directory."
    )]
    #[serde(default)]
    pub isolate: Option<bool>,

    /// Reminder message to deliver when triggered
    #[schemars(description = "Reminder message to deliver when triggered")]
    #[serde(default)]
    pub remind_message: Option<String>,

    /// Delay in seconds before reminder fires (time-based trigger)
    #[schemars(description = "Delay in seconds before reminder fires (time-based trigger)")]
    #[serde(default)]
    pub remind_delay_secs: Option<i64>,

    /// Event type that triggers the reminder (event-based trigger)
    #[schemars(
        description = "Event type that triggers reminder: 'task_completed', 'task_blocked', 'worker_idle', 'epic_completed', etc."
    )]
    #[serde(default)]
    pub remind_event: Option<String>,

    /// JSON filter for event matching
    #[schemars(
        description = "JSON filter for event matching, e.g. '{\"task_id\":\"cas-a1b2\"}' or '{\"worker\":\"worker-3\"}'"
    )]
    #[serde(default)]
    pub remind_filter: Option<String>,

    /// Reminder ID for cancel operations
    #[schemars(description = "Reminder ID for cancel operations")]
    #[serde(default)]
    pub remind_id: Option<i64>,

    /// TTL in seconds for the reminder (default: 3600)
    #[schemars(
        description = "Time-to-live in seconds for the reminder before auto-expiry (default: 3600)"
    )]
    #[serde(default)]
    pub remind_ttl_secs: Option<i64>,
}

/// Unified coordination operations request combining agent, factory, and worktree operations.
///
/// Agent actions: register, unregister, whoami, heartbeat, agent_list, agent_cleanup,
///   session_start, session_end, loop_start, loop_cancel, loop_status, lease_history,
///   queue_notify, queue_poll, queue_peek, queue_ack, message.
/// Factory actions: spawn_workers, shutdown_workers, worker_status, worker_activity,
///   clear_context, my_context, sync_all_workers, gc_report, gc_cleanup,
///   remind, remind_list, remind_cancel.
/// Worktree actions: worktree_create, worktree_list, worktree_show, worktree_cleanup,
///   worktree_merge, worktree_status.
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct CoordinationRequest {
    /// Action to perform
    #[schemars(
        description = "Action: agent ops (register, unregister, whoami, heartbeat, agent_list, agent_cleanup, session_start, session_end, loop_start, loop_cancel, loop_status, lease_history, queue_notify, queue_poll, queue_peek, queue_ack, message), factory ops (spawn_workers, shutdown_workers, worker_status, worker_activity, clear_context, my_context, sync_all_workers, gc_report, gc_cleanup, remind, remind_list, remind_cancel), worktree ops (worktree_create, worktree_list, worktree_show, worktree_cleanup, worktree_merge, worktree_status). Only available in factory mode. For shutdown_workers, supervisor should verify worktree cleanliness/policy before issuing shutdown."
    )]
    pub action: String,

    // ========== Shared Fields ==========
    /// Agent ID, worktree ID, or branch name
    #[schemars(description = "Agent ID or worktree ID/branch name")]
    #[serde(default)]
    pub id: Option<String>,

    /// Task ID (for loop_start, worktree_create)
    #[schemars(description = "Task ID")]
    #[serde(default)]
    pub task_id: Option<String>,

    /// Target agent name for clear_context/message/remind (or 'all_workers'/'supervisor')
    #[schemars(
        description = "Target agent name for clear_context/message/remind (or 'all_workers' for broadcast). For remind: agent who receives the reminder (defaults to self)"
    )]
    #[serde(default)]
    pub target: Option<String>,

    /// Message content for message action
    #[schemars(
        description = "Message text to send to the target agent, or content for message action"
    )]
    #[serde(default)]
    pub message: Option<String>,

    /// Short summary of the message (shown in UI notifications)
    #[schemars(
        description = "A short one-line summary of the message, shown as a preview in the UI"
    )]
    #[serde(default)]
    pub summary: Option<String>,

    /// Force operation (shutdown, worktree cleanup/merge, gc_cleanup)
    #[schemars(description = "Force operation even with uncommitted changes")]
    #[serde(default)]
    pub force: Option<bool>,

    /// Maximum items to return
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    // ========== Agent Fields ==========
    /// Human-readable agent name (for register)
    #[schemars(description = "Human-readable name for the agent")]
    #[serde(default)]
    pub name: Option<String>,

    /// Agent type: primary, sub_agent, worker, ci
    #[schemars(description = "Agent type: 'primary', 'sub_agent', 'worker', 'ci'")]
    #[serde(default)]
    pub agent_type: Option<String>,

    /// Parent agent ID (for sub-agents)
    #[schemars(description = "Parent agent ID if this is a sub-agent")]
    #[serde(default)]
    pub parent_id: Option<String>,

    /// Session ID from Claude Code (used as agent ID)
    #[schemars(description = "Session ID from Claude Code (used as agent ID)")]
    #[serde(default)]
    pub session_id: Option<String>,

    /// Loop prompt (for loop_start)
    #[schemars(description = "The prompt to repeat each iteration")]
    #[serde(default)]
    pub prompt: Option<String>,

    /// Max iterations (for loop_start, 0 = unlimited)
    #[schemars(description = "Maximum iterations (0 = unlimited)")]
    #[serde(default)]
    pub max_iterations: Option<u32>,

    /// Completion promise (for loop_start)
    #[schemars(description = "Text that signals completion")]
    #[serde(default)]
    pub completion_promise: Option<String>,

    /// Reason (for loop_cancel)
    #[schemars(description = "Reason for cancelling")]
    #[serde(default)]
    pub reason: Option<String>,

    /// Stale threshold seconds (for agent_cleanup)
    #[schemars(description = "Seconds since last heartbeat to consider stale")]
    #[serde(default)]
    pub stale_threshold_secs: Option<i64>,

    /// Supervisor ID (for queue operations)
    #[schemars(description = "Supervisor agent ID for queue operations")]
    #[serde(default)]
    pub supervisor_id: Option<String>,

    /// Event type (for queue_notify)
    #[schemars(
        description = "Event type for notification: 'task_completed', 'task_blocked', 'worker_died', 'worker_idle'"
    )]
    #[serde(default)]
    pub event_type: Option<String>,

    /// Payload (for queue_notify)
    #[schemars(description = "JSON payload containing event details")]
    #[serde(default)]
    pub payload: Option<String>,

    /// Notification priority (for queue_notify)
    #[schemars(
        description = "Notification priority: 'critical' (0), 'high' (1), 'normal' (2, default)"
    )]
    #[serde(default)]
    pub priority: Option<String>,

    /// Notification ID (for queue_ack)
    #[schemars(description = "Notification ID to acknowledge")]
    #[serde(default)]
    pub notification_id: Option<i64>,

    // ========== Factory Fields ==========
    /// Number of workers (for spawn/shutdown)
    #[schemars(
        description = "Number of workers (for spawn: how many to create, for shutdown: how many to stop, 0 = all)"
    )]
    #[serde(default)]
    pub count: Option<i32>,

    /// Comma-separated worker names
    #[schemars(
        description = "Comma-separated worker names (optional for spawn, specific targets for shutdown)"
    )]
    #[serde(default)]
    pub worker_names: Option<String>,

    /// Target branch/ref for sync actions
    #[schemars(description = "Target branch/ref for sync actions (e.g., 'epic/my-epic')")]
    #[serde(default)]
    pub branch: Option<String>,

    /// Threshold in seconds for cleanup/report actions
    #[schemars(description = "Optional threshold in seconds for cleanup/report actions")]
    #[serde(default)]
    pub older_than_secs: Option<i64>,

    /// Whether workers need isolated git worktrees
    #[schemars(
        description = "Whether workers need to be isolated in their own git worktrees. When true, each worker gets its own branch and working directory. When false or omitted, workers share the main working directory."
    )]
    #[serde(default)]
    pub isolate: Option<bool>,

    /// Reminder message to deliver when triggered
    #[schemars(description = "Reminder message to deliver when triggered")]
    #[serde(default)]
    pub remind_message: Option<String>,

    /// Delay in seconds before reminder fires (time-based trigger)
    #[schemars(description = "Delay in seconds before reminder fires (time-based trigger)")]
    #[serde(default)]
    pub remind_delay_secs: Option<i64>,

    /// Event type that triggers reminder
    #[schemars(
        description = "Event type that triggers reminder: 'task_completed', 'task_blocked', 'worker_idle', 'epic_completed', etc."
    )]
    #[serde(default)]
    pub remind_event: Option<String>,

    /// JSON filter for event matching
    #[schemars(
        description = "JSON filter for event matching, e.g. '{\"task_id\":\"cas-a1b2\"}' or '{\"worker\":\"worker-3\"}'"
    )]
    #[serde(default)]
    pub remind_filter: Option<String>,

    /// Reminder ID for cancel operations
    #[schemars(description = "Reminder ID for cancel operations")]
    #[serde(default)]
    pub remind_id: Option<i64>,

    /// Time-to-live in seconds for the reminder (default: 3600)
    #[schemars(
        description = "Time-to-live in seconds for the reminder before auto-expiry (default: 3600)"
    )]
    #[serde(default)]
    pub remind_ttl_secs: Option<i64>,

    // ========== Worktree Fields ==========
    /// Show all worktrees including removed/merged (for worktree_list)
    #[schemars(description = "Show all worktrees including removed/merged")]
    #[serde(default)]
    pub all: Option<bool>,

    /// Worktree status filter (for worktree_list)
    #[schemars(
        description = "Filter by status: 'active', 'merged', 'abandoned', 'conflict', 'removed'"
    )]
    #[serde(default)]
    pub status: Option<String>,

    /// Show only orphaned worktrees (for worktree_list)
    #[schemars(description = "Show only orphaned worktrees")]
    #[serde(default)]
    pub orphans: Option<bool>,

    /// Preview cleanup without making changes (for worktree_cleanup)
    #[schemars(description = "Preview cleanup without making changes")]
    #[serde(default)]
    pub dry_run: Option<bool>,
}

/// Request type for MCP proxy execute/search operations.
///
/// Used by both `mcp_search` (discover tools) and `mcp_execute` (call tools).
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
#[schemars(title = "ExecuteRequest")]
pub struct ExecuteRequest {
    /// TypeScript code to execute.
    ///
    /// For `mcp_search`: filter code against a typed `tools` array.
    /// For `mcp_execute`: call tools across connected servers as typed async functions.
    #[schemars(
        description = "TypeScript code to execute. Each connected server is a typed global object where every tool is an async function. Type declarations are auto-generated from tool schemas. Chain calls sequentially: await chrome_devtools.navigate_page({ url: \"https://example.com\" }); const screenshot = await chrome_devtools.take_screenshot({ format: \"png\" }); return screenshot; Or run calls in parallel with Promise.all: const [issues, designs] = await Promise.all([github.list_issues({ repo: \"myorg/app\" }), canva.list_designs({})]);"
    )]
    pub code: String,

    /// Max response length in characters. Default: 40000.
    #[schemars(
        description = "Max response length in characters. Default: 40000. Use your code to extract only what you need rather than increasing this."
    )]
    #[serde(default)]
    pub max_length: Option<usize>,
}

impl CoordinationRequest {
    /// Convert to AgentRequest, mapping agent_list→list, agent_cleanup→cleanup
    pub fn to_agent_request(&self, action: &str) -> super::AgentRequest { todo!() }

    /// Convert to FactoryRequest
    pub fn to_factory_request(&self) -> super::FactoryRequest { todo!() }
}
