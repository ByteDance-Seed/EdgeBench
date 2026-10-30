//! Real-world search scoring tests for CAS use cases
//!
//! These tests verify that the search scoring algorithm produces
//! meaningful, well-calibrated scores for typical CAS queries.
//!
//! ## Search Tests
//!
//! Search uses BM25 text-based matching. Local semantic search has been
//! removed in favor of cloud-based semantic search.

use std::process::Command;
use tempfile::TempDir;

/// Check if embedding model is available for testing
/// Always returns false - local embeddings have been removed
fn embeddings_available() -> bool { todo!() }

/// Skip test if embeddings aren't available (use in non-ignored tests)
/// Local embeddings have been removed - these tests are always skipped
macro_rules! skip_without_embeddings {
    () => {
        if !embeddings_available() {
            eprintln!("Skipping: local embeddings have been removed (cloud-only)");
            return;
        }
    };
}

/// Helper to run CAS commands in a temp directory
fn cas_cmd(dir: &TempDir) -> Command { todo!() }

/// Initialize CAS in a temp directory
fn init_cas(dir: &TempDir) { todo!() }

/// Add a memory entry with optional title and tags
fn add_memory(dir: &TempDir, content: &str, title: Option<&str>, tags: Option<&str>) -> String { todo!() }

/// Generate embeddings for semantic search
/// Always returns false - local embeddings have been removed
fn generate_embeddings(_dir: &TempDir) -> bool { todo!() }

/// Search with full hybrid (BM25 + semantic) - returns results with scores
fn search_hybrid(dir: &TempDir, query: &str) -> Vec<(String, f64)> { todo!() }

/// Search using BM25 only (no semantic)
fn search_bm25(dir: &TempDir, query: &str) -> Vec<(String, f64)> { todo!() }

/// Parse JSON search results
fn parse_search_results(stdout: &str) -> Vec<(String, f64)> { todo!() }

// ============================================================================
// Real-World CAS Use Case Tests
// ============================================================================

/// Test: Exact keyword match should score highly
#[path = "search_scoring_test_cases/tests.rs"]
mod tests;
