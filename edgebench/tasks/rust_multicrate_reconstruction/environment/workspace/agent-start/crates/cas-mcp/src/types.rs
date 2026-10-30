//! MCP Request Types for CAS
//!
//! These types define the schema for the 7 consolidated MCP tools:
//! - cas_memory: Memory/entry operations
//! - cas_task: Task and dependency operations
//! - cas_rule: Rule operations
//! - cas_skill: Skill operations
//! - cas_agent: Agent and loop operations
//! - cas_search: Search, context, and entity operations
//! - cas_system: Diagnostics, stats, and maintenance

use schemars::JsonSchema;
use serde::{Deserialize, Serialize};

/// Unified memory operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct MemoryRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'remember', 'get', 'list', 'update', 'delete', 'archive', 'unarchive', 'helpful', 'harmful', 'recent', 'set_tier', 'opinion_reinforce', 'opinion_weaken', 'opinion_contradict'"
    )]
    pub action: String,

    /// Entry ID (for get, update, delete, archive, unarchive, helpful, harmful, set_tier, opinion_*)
    #[schemars(description = "Entry ID for operations that target a specific entry")]
    #[serde(default)]
    pub id: Option<String>,

    /// Content (for remember, update, opinion_*)
    #[schemars(description = "Content for remember or update, or evidence for opinion operations")]
    #[serde(default)]
    pub content: Option<String>,

    /// Entry type (for remember): learning, preference, context, observation
    #[schemars(
        description = "Entry type for remember: 'learning' (default), 'preference', 'context', 'observation'"
    )]
    #[serde(default)]
    pub entry_type: Option<String>,

    /// Tags (comma-separated)
    #[schemars(description = "Comma-separated tags")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Title (for remember)
    #[schemars(description = "Optional title for the entry")]
    #[serde(default)]
    pub title: Option<String>,

    /// Importance score (0.0-1.0)
    #[schemars(description = "Importance score from 0.0 to 1.0")]
    #[serde(default)]
    pub importance: Option<f32>,

    /// Memory tier (for set_tier): working, cold, archive
    #[schemars(description = "Memory tier: 'working', 'cold', 'archive'")]
    #[serde(default)]
    pub tier: Option<String>,

    /// Limit for list/recent
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Scope filter
    #[schemars(description = "Scope: 'global', 'project', or 'all'")]
    #[serde(default)]
    pub scope: Option<String>,

    /// Team ID filter (for list/recent - filters to team-shared entries)
    #[schemars(description = "Team ID to filter entries shared with a specific team")]
    #[serde(default)]
    pub team_id: Option<String>,

    /// Sort field (for list)
    #[schemars(description = "Sort by: 'created', 'updated', 'importance', 'title'")]
    #[serde(default)]
    pub sort: Option<String>,

    /// Sort order (for list)
    #[schemars(description = "Sort order: 'asc' or 'desc' (default: desc)")]
    #[serde(default)]
    pub sort_order: Option<String>,

    /// Valid from (RFC3339 timestamp for temporal validity)
    #[schemars(
        description = "When this fact becomes valid (RFC3339 format, e.g., 2025-01-01T00:00:00Z)"
    )]
    #[serde(default)]
    pub valid_from: Option<String>,

    /// Valid until (RFC3339 timestamp for temporal validity)
    #[schemars(
        description = "When this fact expires (RFC3339 format, e.g., 2025-12-31T23:59:59Z)"
    )]
    #[serde(default)]
    pub valid_until: Option<String>,
}

/// Unified task operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct TaskRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'create', 'show', 'update', 'start', 'close', 'reopen', 'delete', 'list', 'ready', 'blocked', 'notes', 'dep_add', 'dep_remove', 'dep_list', 'claim', 'release', 'transfer', 'available', 'mine'"
    )]
    pub action: String,

    /// Task ID (for most operations except create, list, ready, blocked, available, mine)
    #[schemars(description = "Task ID for operations targeting a specific task")]
    #[serde(default)]
    pub id: Option<String>,

    /// Title (for create)
    #[schemars(description = "Task title for create")]
    #[serde(default)]
    pub title: Option<String>,

    /// Description (for create)
    #[schemars(description = "Task description")]
    #[serde(default)]
    pub description: Option<String>,

    /// Priority 0-4 (for create, update)
    #[schemars(description = "Priority: 0=Critical, 1=High, 2=Medium, 3=Low, 4=Backlog")]
    #[serde(default)]
    pub priority: Option<u8>,

    /// Task type (for create): task, bug, feature, epic, chore
    #[schemars(description = "Task type: 'task', 'bug', 'feature', 'epic', 'chore'")]
    #[serde(default)]
    pub task_type: Option<String>,

    /// Labels (comma-separated)
    #[schemars(description = "Comma-separated labels")]
    #[serde(default)]
    pub labels: Option<String>,

    /// Notes (for create, update, notes)
    #[schemars(description = "Notes content or notes to append")]
    #[serde(default)]
    pub notes: Option<String>,

    /// Note type (for notes action): progress, blocker, decision, discovery, question
    #[schemars(
        description = "Note type: 'progress', 'blocker', 'decision', 'discovery', 'question'"
    )]
    #[serde(default)]
    pub note_type: Option<String>,

    /// Close reason (for close action). IMPORTANT: Verification must pass before close.
    #[schemars(
        description = "Reason for closing. IMPORTANT: Verification must pass BEFORE close. Workers should attempt close first; if close returns verification-required guidance, follow the indicated verifier ownership workflow."
    )]
    #[serde(default)]
    pub reason: Option<String>,

    /// Include dependencies (for show)
    #[schemars(description = "Include dependency information")]
    #[serde(default)]
    pub with_deps: Option<bool>,

    /// Blocked by task IDs (for create)
    #[schemars(description = "Comma-separated task IDs that block this task")]
    #[serde(default)]
    pub blocked_by: Option<String>,

    /// Target task ID (for dep_add, dep_remove)
    #[schemars(description = "Target task ID for dependency operations")]
    #[serde(default)]
    pub to_id: Option<String>,

    /// Dependency type: blocks, related, parent, duplicate
    #[schemars(description = "Dependency type: 'blocks', 'related', 'parent', 'duplicate'")]
    #[serde(default)]
    pub dep_type: Option<String>,

    /// Lease duration in seconds (for claim)
    #[schemars(description = "Lease duration in seconds (default: 600)")]
    #[serde(default)]
    pub duration_secs: Option<i64>,

    /// Target agent ID (for transfer)
    #[schemars(description = "Target agent ID for transfer")]
    #[serde(default)]
    pub to_agent: Option<String>,

    /// Limit for list operations
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Scope filter
    #[schemars(description = "Scope: 'global', 'project', or 'all'")]
    #[serde(default)]
    pub scope: Option<String>,

    /// Design notes (for create, update)
    #[schemars(description = "Design notes or technical approach")]
    #[serde(default)]
    pub design: Option<String>,

    /// Acceptance criteria (for create, update)
    #[schemars(description = "Acceptance criteria for task completion")]
    #[serde(default)]
    pub acceptance_criteria: Option<String>,

    /// Demo statement (for create, update) - what can be demonstrated when task is complete
    #[schemars(
        description = "What can be demonstrated when this task is complete (e.g., 'Type a query, results filter live')"
    )]
    #[serde(default)]
    pub demo_statement: Option<String>,

    /// External reference (for create, update)
    #[schemars(description = "External reference (URL, ticket ID, etc.)")]
    #[serde(default)]
    pub external_ref: Option<String>,

    /// Assignee (for create, update)
    #[schemars(description = "Assignee identifier (agent ID or name)")]
    #[serde(default)]
    pub assignee: Option<String>,

    /// Status (for list: filter; for update: set new status)
    #[schemars(
        description = "Filter by status (for list) or set new status (for update): 'open', 'in_progress', 'closed', 'blocked'"
    )]
    #[serde(default)]
    pub status: Option<String>,

    /// Epic ID (for create, update) - adds ParentChild dependency to link task to an epic
    #[schemars(
        description = "Epic task ID to associate this task with (creates ParentChild dependency)"
    )]
    #[serde(default)]
    pub epic: Option<String>,

    /// Sort field (for list, ready, blocked)
    #[schemars(description = "Sort by: 'created', 'updated', 'priority', 'title'")]
    #[serde(default)]
    pub sort: Option<String>,

    /// Sort order (for list, ready, blocked)
    #[schemars(
        description = "Sort order: 'asc' or 'desc' (default: desc for dates, asc for priority)"
    )]
    #[serde(default)]
    pub sort_order: Option<String>,

    /// Epic verification owner (for update on epics)
    #[schemars(
        description = "Agent ID responsible for epic verification (supervisor in factory mode)"
    )]
    #[serde(default)]
    pub epic_verification_owner: Option<String>,
}

/// Unified rule operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct RuleRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'create', 'show', 'update', 'delete', 'list', 'list_all', 'helpful', 'harmful', 'sync', 'check_similar'"
    )]
    pub action: String,

    /// Rule ID (for get, update, delete, helpful, harmful)
    #[schemars(description = "Rule ID for operations targeting a specific rule")]
    #[serde(default)]
    pub id: Option<String>,

    /// Content (for create, update)
    #[schemars(description = "Rule content/instruction")]
    #[serde(default)]
    pub content: Option<String>,

    /// Paths pattern (for create, update)
    #[schemars(description = "Glob patterns for files this rule applies to")]
    #[serde(default)]
    pub paths: Option<String>,

    /// Tags (comma-separated)
    #[schemars(description = "Comma-separated tags")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Limit for list operations
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Scope filter
    #[schemars(description = "Scope: 'global' or 'project'")]
    #[serde(default)]
    pub scope: Option<String>,

    /// Auto-approve tools (for create, update)
    #[schemars(description = "Tools to auto-approve (comma-separated, e.g., 'Read,Glob,Grep')")]
    #[serde(default)]
    pub auto_approve_tools: Option<String>,

    /// Auto-approve paths (for create, update)
    #[schemars(description = "Path patterns for auto-approval (comma-separated globs)")]
    #[serde(default)]
    pub auto_approve_paths: Option<String>,

    /// Similarity threshold (for check_similar)
    #[schemars(description = "Similarity threshold for check_similar (0.0-1.0, default: 0.75)")]
    #[serde(default)]
    pub threshold: Option<f32>,
}

/// Unified skill operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct SkillRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'create', 'show', 'update', 'delete', 'list', 'list_all', 'enable', 'disable', 'sync', 'use'"
    )]
    pub action: String,

    /// Skill ID (for get, update, delete, enable, disable, use)
    #[schemars(description = "Skill ID for operations targeting a specific skill")]
    #[serde(default)]
    pub id: Option<String>,

    /// Name (required for create)
    #[schemars(description = "Human-readable name for the skill (required for create)")]
    #[serde(default)]
    pub name: Option<String>,

    /// Description (required for create, optional for update) - full body content
    #[schemars(
        description = "Full skill instructions/content (goes in SKILL.md body). Include commands, code examples, guidelines. Required for create."
    )]
    #[serde(default)]
    pub description: Option<String>,

    /// Invocation (required for create, optional for update)
    #[schemars(
        description = "How to invoke the skill (required for create). Examples: '/my-skill', 'cargo fmt', 'npm test'"
    )]
    #[serde(default)]
    pub invocation: Option<String>,

    /// Skill type: command, mcp, plugin, internal
    #[schemars(description = "Skill type: 'command', 'mcp', 'plugin', 'internal'")]
    #[serde(default)]
    pub skill_type: Option<String>,

    /// Tags (comma-separated)
    #[schemars(description = "Comma-separated tags")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Limit for list operations
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Scope filter
    #[schemars(description = "Scope: 'global' or 'project'")]
    #[serde(default)]
    pub scope: Option<String>,

    /// Short summary - trigger description for frontmatter
    #[schemars(
        description = "Short trigger description (1-2 lines) for SKILL.md frontmatter. Describes WHEN to use the skill. Example: 'Run E2E tests. Use when running tests or debugging failures.'"
    )]
    #[serde(default)]
    pub summary: Option<String>,

    /// Example usage
    #[schemars(description = "Example usage of the skill")]
    #[serde(default)]
    pub example: Option<String>,

    /// Pre-conditions (comma-separated)
    #[schemars(description = "Pre-conditions required (comma-separated)")]
    #[serde(default)]
    pub preconditions: Option<String>,

    /// Post-conditions (comma-separated)
    #[schemars(description = "Expected post-conditions (comma-separated)")]
    #[serde(default)]
    pub postconditions: Option<String>,

    /// Validation script
    #[schemars(description = "Script to check if skill is available")]
    #[serde(default)]
    pub validation_script: Option<String>,

    /// Make skill invokable via slash command
    #[schemars(description = "Enable /skill-name invocation")]
    #[serde(default)]
    pub invokable: Option<bool>,

    /// Argument hint for invokable skills
    #[schemars(description = "Argument hint (e.g., '[query]', '[file] [line]')")]
    #[serde(default)]
    pub argument_hint: Option<String>,

    /// Context mode for execution
    #[schemars(description = "Context mode: 'fork' for forked sub-agent")]
    #[serde(default)]
    pub context_mode: Option<String>,

    /// Agent type for execution
    #[schemars(description = "Agent type: 'Explore', 'code-reviewer', etc.")]
    #[serde(default)]
    pub agent_type: Option<String>,

    /// Allowed tools (comma-separated)
    #[schemars(description = "Allowed tools (comma-separated, e.g., 'Read,Grep,Glob')")]
    #[serde(default)]
    pub allowed_tools: Option<String>,

    /// Start as draft
    #[schemars(description = "Create skill as draft (not enabled)")]
    #[serde(default)]
    pub draft: Option<bool>,

    /// Disable model invocation (Claude Code 2.1.3+)
    #[schemars(description = "Prevent skill from invoking the model (for command-only skills)")]
    #[serde(default)]
    pub disable_model_invocation: Option<bool>,
}

/// Unified spec operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct SpecRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'create', 'show', 'update', 'delete', 'list', 'approve', 'reject', 'supersede', 'link', 'unlink', 'sync', 'get_for_task'"
    )]
    pub action: String,

    /// Spec ID (for show, update, delete, approve, reject, supersede, link, unlink)
    #[schemars(description = "Spec ID for operations targeting a specific spec")]
    #[serde(default)]
    pub id: Option<String>,

    /// Title (for create, update)
    #[schemars(description = "Spec title")]
    #[serde(default)]
    pub title: Option<String>,

    /// Summary (for create, update)
    #[schemars(description = "Brief summary of what this spec covers")]
    #[serde(default)]
    pub summary: Option<String>,

    /// Goals (comma-separated, for create, update)
    #[schemars(description = "Goals and objectives (comma-separated)")]
    #[serde(default)]
    pub goals: Option<String>,

    /// In scope items (comma-separated, for create, update)
    #[schemars(description = "What is in scope for this spec (comma-separated)")]
    #[serde(default)]
    pub in_scope: Option<String>,

    /// Out of scope items (comma-separated, for create, update)
    #[schemars(description = "What is explicitly out of scope (comma-separated)")]
    #[serde(default)]
    pub out_of_scope: Option<String>,

    /// Target users (comma-separated, for create, update)
    #[schemars(description = "Target users or personas (comma-separated)")]
    #[serde(default)]
    pub users: Option<String>,

    /// Technical requirements (comma-separated, for create, update)
    #[schemars(description = "Technical requirements and constraints (comma-separated)")]
    #[serde(default)]
    pub technical_requirements: Option<String>,

    /// Acceptance criteria (comma-separated, for create, update)
    #[schemars(description = "Acceptance criteria for completion (comma-separated)")]
    #[serde(default)]
    pub acceptance_criteria: Option<String>,

    /// Design notes (for create, update)
    #[schemars(description = "Design notes and decisions")]
    #[serde(default)]
    pub design_notes: Option<String>,

    /// Additional notes (for create, update)
    #[schemars(description = "Additional notes or context")]
    #[serde(default)]
    pub additional_notes: Option<String>,

    /// Spec type (for create, update, list)
    #[schemars(description = "Spec type: 'epic', 'feature', 'api', 'component', 'migration'")]
    #[serde(default)]
    pub spec_type: Option<String>,

    /// Status (for list filter)
    #[schemars(
        description = "Filter by status: 'draft', 'under_review', 'approved', 'superseded', 'rejected'"
    )]
    #[serde(default)]
    pub status: Option<String>,

    /// Associated task ID (for create, update, link, unlink)
    #[schemars(description = "Associated task ID (e.g., epic task)")]
    #[serde(default)]
    pub task_id: Option<String>,

    /// Source entry IDs (comma-separated, for create, update)
    #[schemars(description = "Source entry IDs this spec was derived from (comma-separated)")]
    #[serde(default)]
    pub source_ids: Option<String>,

    /// ID of spec being superseded (for supersede action)
    #[schemars(description = "ID of the spec being superseded")]
    #[serde(default)]
    pub supersedes_id: Option<String>,

    /// Create new version instead of modifying (for update)
    #[schemars(description = "Create a new version instead of modifying in place")]
    #[serde(default)]
    pub new_version: Option<bool>,

    /// Tags (comma-separated)
    #[schemars(description = "Comma-separated tags")]
    #[serde(default)]
    pub tags: Option<String>,

    /// Scope filter
    #[schemars(description = "Scope: 'global' or 'project'")]
    #[serde(default)]
    pub scope: Option<String>,

    /// Limit for list operations
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,
}

/// Unified agent and loop operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct AgentRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'register', 'unregister', 'whoami', 'heartbeat', 'list', 'cleanup', 'session_start', 'session_end', 'loop_start', 'loop_cancel', 'loop_status', 'lease_history', 'queue_notify', 'queue_poll', 'queue_peek', 'queue_ack', 'message'"
    )]
    pub action: String,

    /// Agent ID (for unregister, whoami)
    #[schemars(description = "Agent ID")]
    #[serde(default)]
    pub id: Option<String>,

    /// Name (for register)
    #[schemars(description = "Human-readable name for the agent")]
    #[serde(default)]
    pub name: Option<String>,

    /// Agent type: primary, sub_agent, worker, ci
    #[schemars(description = "Agent type: 'primary', 'sub_agent', 'worker', 'ci'")]
    #[serde(default)]
    pub agent_type: Option<String>,

    /// Parent agent ID (for sub-agents spawned by Task tool)
    #[schemars(description = "Parent agent ID if this is a sub-agent")]
    #[serde(default)]
    pub parent_id: Option<String>,

    /// Session ID (from Claude Code) - this becomes the agent ID
    #[schemars(description = "Session ID from Claude Code (used as agent ID)")]
    #[serde(default)]
    pub session_id: Option<String>,

    /// Task ID (for loop_start)
    #[schemars(description = "Task ID")]
    #[serde(default)]
    pub task_id: Option<String>,

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

    /// Cancel reason (for loop_cancel)
    #[schemars(description = "Reason for cancelling")]
    #[serde(default)]
    pub reason: Option<String>,

    /// Stale threshold seconds (for cleanup)
    #[schemars(description = "Seconds since last heartbeat to consider stale")]
    #[serde(default)]
    pub stale_threshold_secs: Option<i64>,

    /// Limit for list operations
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    // ========== Queue Operations Fields (Factory Mode) ==========
    /// Supervisor ID (for queue_notify, queue_poll, queue_peek)
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

    /// Priority (for queue_notify)
    #[schemars(
        description = "Notification priority: 'critical' (0), 'high' (1), 'normal' (2, default)"
    )]
    #[serde(default)]
    pub priority: Option<String>,

    /// Notification ID (for queue_ack)
    #[schemars(description = "Notification ID to acknowledge")]
    #[serde(default)]
    pub notification_id: Option<i64>,

    // ========== Message Queue Fields (Agent → Agent) ==========
    /// Target agent for message action (agent name, "supervisor", or "all_workers")
    #[schemars(
        description = "Target agent name, 'supervisor', or 'all_workers' for message action"
    )]
    #[serde(default)]
    pub target: Option<String>,

    /// Message content for message action (preferred over prompt for this action)
    #[schemars(
        description = "Message content to send (preferred over 'prompt' for message action)"
    )]
    #[serde(default)]
    pub message: Option<String>,

    /// Short summary of the message (shown in UI notifications)
    #[schemars(
        description = "A short one-line summary of the message, shown as a preview in the UI"
    )]
    #[serde(default)]
    pub summary: Option<String>,
}

/// Unified personal pattern operations request
#[derive(Debug, Clone, Deserialize, Serialize, JsonSchema)]
pub struct PatternRequest {
    /// Action to perform
    #[schemars(
        description = "Action: 'create', 'list', 'show', 'update', 'archive', 'adopt', 'helpful', 'harmful', 'team_suggestions', 'team_new_suggestions', 'team_create_suggestion', 'team_share', 'team_adopt', 'team_dismiss', 'team_recommend', 'team_archive_suggestion', 'team_suggestion_analytics'"
    )]
    pub action: String,

    /// Pattern ID (for show, update, archive, helpful, harmful, team_share)
    #[schemars(description = "Pattern ID for operations targeting a specific pattern")]
    #[serde(default)]
    pub id: Option<String>,

    /// Content (for create, team_create_suggestion)
    #[schemars(description = "Pattern content/instruction text")]
    #[serde(default)]
    pub content: Option<String>,

    /// Category (for create, update, list filter, team_create_suggestion)
    #[schemars(
        description = "Category: 'convention', 'security', 'performance', 'architecture', 'error_handling', 'general'"
    )]
    #[serde(default)]
    pub category: Option<String>,

    /// Priority 0-3 (for create, update, team_create_suggestion)
    #[schemars(description = "Priority: 0=Critical, 1=High, 2=Medium (default), 3=Low")]
    #[serde(default)]
    pub priority: Option<u8>,

    /// Propagation mode (for create, update)
    #[schemars(description = "Propagation: 'all_projects' (default), 'tagged_projects'")]
    #[serde(default)]
    pub propagation: Option<String>,

    /// Propagation tags (comma-separated, for create, update when propagation=tagged_projects)
    #[schemars(
        description = "Comma-separated tags for tagged_projects propagation (e.g., 'elixir,phoenix')"
    )]
    #[serde(default)]
    pub tags: Option<String>,

    /// Status filter (for list): active, archived, all
    #[schemars(description = "Filter by status: 'active' (default), 'archived', 'all'")]
    #[serde(default)]
    pub status: Option<String>,

    /// Rule ID (for adopt action)
    #[schemars(description = "CAS rule ID to adopt as a personal pattern (for adopt action)")]
    #[serde(default)]
    pub rule_id: Option<String>,

    /// Limit for list operations
    #[schemars(description = "Maximum items to return")]
    #[serde(default)]
    pub limit: Option<usize>,

    /// Team ID (for team_* actions)
    #[schemars(description = "Team ID for team suggestion operations")]
    #[serde(default)]
    pub team_id: Option<String>,

    /// Suggestion ID (for team_adopt, team_dismiss, team_recommend, team_archive_suggestion, team_suggestion_analytics)
    #[schemars(description = "Suggestion ID for team suggestion operations")]
    #[serde(default)]
    pub suggestion_id: Option<String>,

    /// Pattern ID to share (for team_share)
    #[schemars(description = "Personal pattern ID to share as team suggestion")]
    #[serde(default)]
    pub pattern_id: Option<String>,

    /// Recommended flag (for team_recommend)
    #[schemars(description = "Whether to mark suggestion as recommended (default: true)")]
    #[serde(default)]
    pub recommended: Option<bool>,

    /// Include dismissed suggestions (for team_suggestions)
    #[schemars(description = "Include dismissed suggestions in listing (default: false)")]
    #[serde(default)]
    pub include_dismissed: Option<bool>,
}

mod ops_secondary;

pub use crate::types::ops_secondary::{
    CoordinationRequest, ExecuteRequest, FactoryRequest, SearchContextRequest, SystemRequest,
    TeamRequest, VerificationRequest,
};

#[cfg(test)]
#[path = "types_tests/tests.rs"]
mod tests;
