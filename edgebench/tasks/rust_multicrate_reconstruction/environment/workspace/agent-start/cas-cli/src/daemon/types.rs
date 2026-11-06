use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;

/// Configuration for the daemon.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DaemonConfig {
    /// How often to run maintenance tasks (minutes)
    pub interval_minutes: u64,
    /// Minimum idle time before running (minutes)
    pub min_idle_minutes: u64,
    /// Maximum entries to process per run
    pub batch_size: usize,
    /// Enable observation processing
    pub process_observations: bool,
    /// Enable memory consolidation
    pub consolidate_memories: bool,
    /// Enable automatic pruning
    pub auto_prune: bool,
    /// Enable memory decay
    pub apply_decay: bool,
    /// Model for AI tasks
    pub model: String,
    /// Path to CAS root
    pub cas_root: PathBuf,
    /// Enable entity summary generation
    pub update_entity_summaries: bool,
    /// Enable background code indexing
    pub index_code: bool,
    /// Paths to watch for code changes (relative to project root)
    pub code_watch_paths: Vec<PathBuf>,
    /// Code indexing interval (seconds)
    pub code_index_interval_secs: u64,
    /// Age (in hours) after which stale/shutdown agents are deleted (0 = never delete)
    pub agent_purge_age_hours: u64,
    /// Enable incremental BM25 indexing
    pub index_bm25: bool,
    /// Batch size for BM25 indexing
    pub index_batch_size: usize,
    /// Maximum entries to index per run
    pub index_max_per_run: usize,
    /// BM25 indexing interval (seconds)
    pub index_interval_secs: u64,
}

impl Default for DaemonConfig {
    fn default() -> Self { todo!() }
}

/// Status of the daemon.
#[derive(Debug, Clone, Serialize, Deserialize, Default)]
pub struct DaemonStatus {
    /// Whether daemon is running
    pub running: bool,
    /// Last run timestamp
    pub last_run: Option<DateTime<Utc>>,
    /// Next scheduled run
    pub next_run: Option<DateTime<Utc>>,
    /// Number of observations processed
    pub observations_processed: usize,
    /// Number of memories consolidated
    pub memories_consolidated: usize,
    /// Number of entries pruned
    pub entries_pruned: usize,
    /// Number of entries with decay applied
    pub decay_applied: usize,
    /// Last error if any
    pub last_error: Option<String>,
}

/// Result of a single daemon run.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DaemonRunResult {
    /// Start time
    pub started_at: DateTime<Utc>,
    /// End time
    pub ended_at: DateTime<Utc>,
    /// Duration in seconds
    pub duration_secs: f64,
    /// Observations processed
    pub observations_processed: usize,
    /// Consolidation suggestions applied
    pub consolidations_applied: usize,
    /// Entries pruned
    pub entries_pruned: usize,
    /// Entries with decay applied
    pub decay_applied: usize,
    /// Entries indexed in BM25
    pub entries_indexed: usize,
    /// Indexing errors
    pub indexing_errors: Vec<String>,
    /// Entity summaries updated
    pub entity_summaries_updated: usize,
    /// Stale agents cleaned (marked dead and leases reclaimed)
    pub agents_cleaned: usize,
    /// Old stale/shutdown agents permanently deleted
    pub agents_purged: usize,
    /// Tasks with interruption notes added (leases released while in progress)
    pub tasks_interrupted: usize,
    /// Orphaned worktrees cleaned up
    pub worktrees_cleaned: usize,
    /// Errors encountered
    pub errors: Vec<String>,
}

/// Result of embedding generation (stub for compatibility).
#[derive(Debug, Clone, Default)]
pub struct EmbeddingResult {
    /// Number of embeddings generated (always 0 - daemon removed)
    pub generated: usize,
    /// Errors encountered
    pub errors: Vec<(String, String)>,
}

/// Result of a code indexing run.
#[derive(Debug, Clone, Default)]
pub struct CodeIndexResult {
    /// Number of files indexed
    pub files_indexed: usize,
    /// Number of files deleted from index
    pub files_deleted: usize,
    /// Number of symbols indexed
    pub symbols_indexed: usize,
    /// Errors encountered
    pub errors: Vec<String>,
}
