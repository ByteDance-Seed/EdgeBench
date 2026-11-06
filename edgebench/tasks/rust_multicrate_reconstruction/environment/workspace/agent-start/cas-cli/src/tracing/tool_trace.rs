use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Rich tool trace for learning loop detection
///
/// Captures detailed information about tool usage to detect patterns like:
/// - Edit -> Fail -> Investigate -> Fix -> Success
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct ToolTrace {
    /// Unique trace ID
    pub id: String,
    /// Session ID
    pub session_id: String,
    /// Timestamp
    pub timestamp: DateTime<Utc>,
    /// Tool name (Edit, Write, Bash, Read, Grep, Glob, WebFetch, Task, etc.)
    pub tool_name: String,
    /// Sequence position within session (for ordering)
    pub sequence_pos: u32,
    /// File path (for Edit/Write/Read)
    pub file_path: Option<String>,
    /// Whether file is in deps/dependencies
    pub is_dependency: bool,
    /// Command (for Bash)
    pub command: Option<String>,
    /// Command type classification (build, test, run, other)
    pub command_type: Option<String>,
    /// Exit code (for Bash)
    pub exit_code: Option<i32>,
    /// Whether operation succeeded
    pub success: bool,
    /// Error snippet (first 500 chars of error output)
    pub error_snippet: Option<String>,
    /// Classified error type (type_error, import_error, syntax_error, runtime_error, etc.)
    pub error_type: Option<String>,
    /// Output snippet (first 500 chars for Bash)
    pub output_snippet: Option<String>,
    /// Lines added (for Edit/Write)
    pub lines_added: Option<u32>,
    /// Lines removed (for Edit)
    pub lines_removed: Option<u32>,
    /// Old content for Edit (truncated to 1000 chars, for seeing what changed)
    pub old_content: Option<String>,
    /// New content for Edit/Write (truncated to 1000 chars)
    pub new_content: Option<String>,
    /// Hash of old content (for dedup when content is large)
    pub old_content_hash: Option<String>,
    /// Hash of new content
    pub new_content_hash: Option<String>,
    /// Search pattern (for Grep/Glob)
    pub search_pattern: Option<String>,
    /// Number of search results (for Grep/Glob)
    pub search_results_count: Option<u32>,
    /// URL (for WebFetch)
    pub url: Option<String>,
    /// Previous tool in sequence
    pub prev_tool: Option<String>,
    /// Whether previous tool failed
    pub prev_failed: bool,
    /// Time since last tool (ms)
    pub time_since_prev_ms: Option<u64>,
    /// Attempt ID - groups related operations (e.g., all ops trying to fix same error)
    pub attempt_id: Option<String>,
}

impl ToolTrace {
    /// Create a new tool trace
    pub fn new(session_id: String, tool_name: String, sequence_pos: u32) -> Self { todo!() }

    /// Compute a simple hash of content for dedup
    pub fn hash_content(content: &str) -> String { todo!() }

    /// Classify error type from error message
    pub fn classify_error(error: &str) -> &'static str { todo!() }

    /// Classify bash command type
    pub fn classify_command(cmd: &str) -> &'static str { todo!() }

    /// Check if path looks like a dependency
    pub fn is_dep_path(path: &str) -> bool { todo!() }
}
