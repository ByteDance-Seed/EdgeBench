use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Trace event type
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
pub enum TraceEventType {
    /// Context injection at session start
    ContextInjection,
    /// Search query and results
    Search,
    /// Rule application/match
    RuleApplication,
    /// AI extraction from observations
    Extraction,
    /// Memory retrieval for context
    MemoryRetrieval,
    /// Skill invocation
    SkillInvocation,
    /// CLI command execution
    CommandExecution,
    /// Claude API call (prompt/response)
    ClaudeApiCall,
    /// Store operation (add, update, delete, get)
    StoreOperation,
    /// Hook event (SessionStart, Stop, etc.)
    HookEvent,
}

impl std::fmt::Display for TraceEventType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

impl TraceEventType {
    pub fn parse(s: &str) -> Option<Self> { todo!() }
}

/// A trace event for AI operations
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TraceEvent {
    /// Unique event ID
    pub id: String,
    /// Event type
    pub event_type: TraceEventType,
    /// Timestamp
    pub timestamp: DateTime<Utc>,
    /// Session ID if available
    pub session_id: Option<String>,
    /// Duration in milliseconds
    pub duration_ms: u64,
    /// Input data (JSON)
    pub input: String,
    /// Output data (JSON)
    pub output: String,
    /// Metadata (JSON) - additional context
    pub metadata: String,
    /// Success flag
    pub success: bool,
    /// Error message if any
    pub error: Option<String>,
}

/// Context injection trace details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ContextInjectionTrace {
    /// Current working directory
    pub cwd: String,
    /// Number of tasks included
    pub tasks_included: usize,
    /// Number of rules included
    pub rules_included: usize,
    /// Number of skills included
    pub skills_included: usize,
    /// Number of memories included
    pub memories_included: usize,
    /// Number of pinned memories included (in-context tier)
    pub pinned_included: usize,
    /// Total tokens estimated
    pub total_tokens: usize,
    /// Token budget
    pub token_budget: usize,
    /// Items that were omitted due to budget
    pub items_omitted: usize,
}

/// Rule application trace details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct RuleApplicationTrace {
    /// Rule ID
    pub rule_id: String,
    /// Rule content preview
    pub rule_preview: String,
    /// Path that matched
    pub matched_path: String,
    /// Whether rule was applied
    pub applied: bool,
    /// Reason if not applied
    pub skip_reason: Option<String>,
}

/// Extraction trace details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ExtractionTrace {
    /// Observation ID
    pub observation_id: String,
    /// Original content length
    pub content_length: usize,
    /// Extraction model/method used
    pub method: String,
    /// Number of memories extracted
    pub memories_extracted: usize,
    /// Quality score (0.0-1.0) if available
    pub quality_score: Option<f32>,
    /// Tags extracted
    pub tags_extracted: Vec<String>,
}

/// Skill invocation trace details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SkillInvocationTrace {
    /// Skill ID
    pub skill_id: String,
    /// Skill name
    pub skill_name: String,
    /// Invocation context
    pub context: String,
    /// Result summary
    pub result_summary: Option<String>,
}

/// Command execution trace details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CommandExecutionTrace {
    /// Command name (e.g., "add", "search", "task")
    pub command: String,
    /// Command arguments (sanitized - no sensitive data)
    pub args: Vec<String>,
    /// Whether command succeeded
    pub success: bool,
    /// Error message if failed
    pub error: Option<String>,
    /// Exit code if available
    pub exit_code: Option<i32>,
}

/// Claude API call trace details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ClaudeApiTrace {
    /// Model used (e.g., "claude-haiku-4-5", "sonnet")
    pub model: String,
    /// Full prompt text
    pub prompt: String,
    /// Claude's response
    pub response: String,
    /// Input tokens used
    pub input_tokens: Option<u32>,
    /// Output tokens used
    pub output_tokens: Option<u32>,
    /// Estimated cost in USD
    pub cost_usd: Option<f64>,
    /// Whether the call succeeded
    pub success: bool,
    /// Error message if failed
    pub error: Option<String>,
    /// Caller context (e.g., "consolidation", "extraction", "hook_summary")
    pub caller: String,
}

/// Store operation trace details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct StoreOperationTrace {
    /// Operation type (add, update, delete, get, list)
    pub operation: String,
    /// Store type (sqlite, markdown)
    pub store_type: String,
    /// Item IDs involved
    pub item_ids: Vec<String>,
    /// Number of items affected
    pub affected: usize,
    /// Whether the operation succeeded
    pub success: bool,
    /// Error message if failed
    pub error: Option<String>,
}

/// Hook event trace details
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct HookEventTrace {
    /// Hook name (SessionStart, Stop, PostToolUse)
    pub hook_name: String,
    /// Input JSON (session_id, cwd, etc.)
    pub input: serde_json::Value,
    /// Output JSON (continue, context, etc.)
    pub output: serde_json::Value,
    /// Context injected (for SessionStart)
    pub context_injected: Option<String>,
    /// Token count of context
    pub context_tokens: Option<usize>,
}

/// A surfaced item tracked for feedback
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct SurfacedItem {
    pub session_id: String,
    pub item_id: String,
    pub item_type: String, // "memory", "rule", "task", "skill"
    pub item_preview: Option<String>,
    pub surfaced_at: DateTime<Utc>,
    pub feedback_given: bool,
}

/// A buffered observation awaiting synthesis
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BufferedObservation {
    pub session_id: String,
    pub tool_name: String,
    pub file_path: Option<String>,
    pub content: String,
    pub exit_code: Option<i32>,
    pub is_error: bool,
    pub timestamp: DateTime<Utc>,
}

/// Aggregated trace statistics
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct TraceStats {
    pub event_type: TraceEventType,
    pub count: u64,
    pub avg_duration_ms: f64,
    pub success_count: u64,
    pub failure_count: u64,
}

impl TraceStats {
    /// Calculate success rate
    pub fn success_rate(&self) -> f64 { todo!() }
}
