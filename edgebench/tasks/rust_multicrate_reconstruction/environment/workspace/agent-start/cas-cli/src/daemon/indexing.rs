use std::path::{Path, PathBuf};
use std::sync::Arc;

use crate::daemon::{CodeIndexResult, CodeWatcher, DaemonConfig, EmbeddingResult, WatchEvent};
use crate::error::CasError;
use crate::store::Store;

/// Run embedding-only maintenance cycle (no-op - daemon removed).
pub fn run_embedding_cycle(_config: &DaemonConfig) -> Result<EmbeddingResult, CasError> { todo!() }

pub(crate) fn generate_bm25_index(
    store: &Arc<dyn Store>,
    config: &DaemonConfig,
) -> Result<crate::hybrid_search::IndexingResult, CasError> { todo!() }

/// Run indexing-only maintenance cycle (for incremental BM25 updates).
pub fn run_indexing_cycle(
    config: &DaemonConfig,
) -> Result<crate::hybrid_search::IndexingResult, CasError> { todo!() }

/// Index changed code files (called by file watcher or periodic task).
pub fn index_code_files(files: &[PathBuf], cas_root: &Path) -> Result<CodeIndexResult, CasError> { todo!() }

/// Run code indexing cycle (for periodic background indexing).
pub fn run_code_index_cycle(
    watcher: &CodeWatcher,
    cas_root: &Path,
) -> Result<CodeIndexResult, CasError> { todo!() }
