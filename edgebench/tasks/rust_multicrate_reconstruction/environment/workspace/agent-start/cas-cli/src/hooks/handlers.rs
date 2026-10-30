//! Hook event handlers
//!
//! Implements handlers for each Claude Code hook event.

use std::path::Path;
use tracing::{debug, info, warn};

use crate::config::Config;
use crate::error::MemError;
use crate::otel::OtelContext;
use crate::store::{
    RuleStore, SqliteStore, Store, open_agent_store, open_commit_link_store,
    open_file_change_store, open_loop_store, open_prompt_store, open_rule_store, open_store,
    open_task_store, open_worktree_store,
};
use crate::tracing::{DevTracer, ToolTrace, TraceTimer};
use crate::types::RuleStatus;
use crate::types::{
    Agent, AgentRole, ChangeType, CommitLink, DependencyType, Entry, EntryType, FileChange,
    ObservationType, Prompt, Rule, Session, Task, TaskStatus, TaskType,
};
use cas_core::SearchIndex;

use crate::hooks::transcript::check_promise_in_transcript;

use crate::hooks::context::{build_context, build_context_ai, build_plan_context};
use crate::hooks::types::{HookInput, HookOutput};

/// Session summary result from AI analysis
#[derive(Debug, Clone, Default, serde::Serialize, serde::Deserialize)]
pub struct SessionSummary {
    /// Brief summary of what was accomplished
    pub summary: String,
    /// Key decisions made during the session
    pub decisions: Vec<String>,
    /// Tasks that were completed
    pub tasks_completed: Vec<String>,
    /// Important learnings or discoveries
    pub key_learnings: Vec<String>,
    /// Suggested follow-up tasks
    pub follow_up_tasks: Vec<String>,
}

/// Extracted learning from transcript analysis
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ExtractedLearning {
    /// The rule/convention content
    pub content: String,
    /// File path pattern this applies to (e.g., "**/*.tsx", "lib/cas_cloud_web/**")
    pub path_pattern: Option<String>,
    /// Confidence score (0.0-1.0)
    pub confidence: f32,
    /// Tags for categorization
    pub tags: Vec<String>,
}

/// Extracted preference from user prompt analysis
#[derive(Debug, Clone, serde::Serialize, serde::Deserialize)]
pub struct ExtractedPreference {
    /// The rule content in imperative form
    pub content: String,
    /// Scope: "global" (user preference) or "project" (project-specific)
    pub scope: String,
    /// Confidence score (0.0-1.0)
    pub confidence: f32,
    /// Optional file path pattern this applies to
    #[serde(default)]
    pub path_pattern: Option<String>,
}

/// Tools worth capturing observations from
const CAPTURE_TOOLS: &[&str] = &["Write", "Edit", "Bash", "Read"];

/// Maximum number of recent files to track per session
const MAX_RECENT_FILES: usize = 10;

pub(crate) fn truncate_display(s: &str, max_len: usize) -> String { todo!() }

mod handlers_session;
mod handlers_state;

#[cfg(test)]
pub(crate) use handlers_session::estimate_tokens;
pub(crate) use handlers_session::{extract_learnings_sync, generate_session_summary_sync};
pub use handlers_session::{generate_session_title_sync, handle_session_end, handle_session_start};
pub(crate) use handlers_state::{
    cleanup_agent_leases, cleanup_orphaned_tasks, clear_session_files, current_agent_id,
    detect_significant_activity, extract_activity_entity_id, get_exit_blockers, track_session_file,
};
pub use handlers_state::{get_session_files, handle_subagent_start, handle_subagent_stop};

mod handlers_middle;
pub use handlers_middle::{handle_post_tool_use, handle_stop, handle_user_prompt_submit};

mod handlers_events;
pub use handlers_events::{
    handle_notification, handle_permission_request, handle_pre_compact, handle_pre_tool_use,
};

#[cfg(test)]
mod handlers_tests;

#[cfg(test)]
use handlers_events::*;
#[cfg(test)]
use handlers_middle::*;
