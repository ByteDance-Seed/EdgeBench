//! Background maintenance operations
//!
//! Provides maintenance tasks that run during idle time:
//! - Process pending observations
//! - Consolidate related memories
//! - Prune stale entries
//! - Apply memory decay
//! - Generate embeddings
//! - Index code files (via file watcher)
//!
//! Note: The standalone daemon has been removed. Maintenance now runs via:
//! - Embedded daemon in the MCP server (automatic, idle-based)
//! - `cas daemon run` for one-off maintenance runs

pub mod queue;
pub mod watcher;

mod decay;
mod indexing;
mod maintenance;
mod observation;
#[cfg(test)]
mod tests;
mod types;

pub use indexing::{
    index_code_files, run_code_index_cycle, run_embedding_cycle, run_indexing_cycle,
};
pub use maintenance::{run_maintenance, run_once};
pub use queue::{
    MaintenanceTask, TaskQueue, TaskType, global_queue, queue_embedding_task,
    queue_observation_task, queue_scheduled_maintenance,
};
pub use types::{CodeIndexResult, DaemonConfig, DaemonRunResult, DaemonStatus, EmbeddingResult};
pub use watcher::{CodeWatcher, WatchEvent, WatcherConfig};
