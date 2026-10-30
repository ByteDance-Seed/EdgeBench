//! CAS-specific code search
//!
//! This module provides a concrete type alias and factory functions for CodeSearch,
//! wiring up the cas-search generic types with CAS-specific implementations.
//!
//! Note: Semantic/embedding-based code search is now cloud-only. Local code search
//! uses BM25 full-text and AST-based pattern matching.

use std::path::Path;
use std::sync::Arc;

use cas_search::{Bm25Index, CodeSearch, LmdbVectorStore};
use cas_store::SqliteCodeStore;

use crate::error::{MemError, Result};

/// Concrete CodeSearch type for CAS
///
/// Uses:
/// - `SqliteCodeStore` for code symbol storage
/// - `LmdbVectorStore` for vector storage (semantic search via cloud)
/// - `Bm25Index` for full-text search
pub type CasCodeSearch = CodeSearch<SqliteCodeStore, LmdbVectorStore, Bm25Index>;

/// Open a CodeSearch instance for the given CAS directory
///
/// This sets up all the necessary stores and indexes for code search:
/// - Opens the code store (SqliteCodeStore)
/// - Opens or creates the code BM25 index
/// - Opens or creates the code vector store (for cloud sync)
///
/// Note: Local semantic search is disabled. Use cloud API for semantic code search.
pub fn open_code_search(cas_root: &Path) -> Result<CasCodeSearch> { todo!() }

/// Open a CodeSearch instance without reranking (faster for bulk queries)
///
/// Note: This is now identical to open_code_search since semantic search is cloud-only.
pub fn open_code_search_fast(cas_root: &Path) -> Result<CasCodeSearch> { todo!() }

fn open_code_search_internal(cas_root: &Path) -> Result<CasCodeSearch> { todo!() }

/// Check if code search is available (has indexed symbols)
pub fn code_search_available(cas_root: &Path) -> bool { todo!() }

#[cfg(test)]
mod tests {
    use crate::hybrid_search::code::*;
    use tempfile::TempDir;

    #[test]
    fn test_code_search_available_false_when_no_index() {
        let temp = TempDir::new().unwrap();
        assert!(!code_search_available(temp.path()));
    }
}
