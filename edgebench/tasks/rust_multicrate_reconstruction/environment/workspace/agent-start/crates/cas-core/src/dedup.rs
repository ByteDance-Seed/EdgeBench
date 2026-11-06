//! Deduplication using BM25 text similarity
//!
//! Uses BM25 to detect similar entries based on text matching.
//!
//! # Architecture
//!
//! This module provides BM25-based deduplication via the `Deduplicator` struct.
//! It requires a search index that implements the `SearchIndexTrait` trait.
//!
//! # Example
//!
//! ```rust,ignore
//! use cas_core::dedup::{Deduplicator, SimilarityResult};
//!
//! let dedup = Deduplicator::new(&store, &search);
//! let similar = dedup.find_similar("test content", 0.5)?;
//! ```

use chrono::Utc;

use cas_store::Store;
use cas_types::Entry;

use crate::error::CoreError;

/// Result of similarity check
#[derive(Debug, Clone)]
pub struct SimilarityResult {
    /// The similar entry
    pub entry: Entry,
    /// Similarity score (0.0-1.0)
    pub similarity: f64,
}

/// Trait for search indexes that support BM25-style search
///
/// This trait abstracts over the concrete SearchIndex implementation
/// to allow the dedup module to work with any compatible search backend.
pub trait SearchIndexTrait: Send + Sync {
    /// Search for entries matching a query
    ///
    /// Returns a list of (entry_id, bm25_score) pairs.
    fn search_for_dedup(
        &self,
        query: &str,
        limit: usize,
        entries: &[Entry],
    ) -> Result<Vec<SearchHit>, CoreError>;
}

/// A search hit from BM25 search
#[derive(Debug, Clone)]
pub struct SearchHit {
    /// Entry ID
    pub id: String,
    /// BM25 score
    pub bm25_score: f64,
}

/// Deduplicator for finding and handling similar entries using BM25 search
pub struct Deduplicator<'a, S: SearchIndexTrait> {
    store: &'a dyn Store,
    search: &'a S,
}

impl<'a, S: SearchIndexTrait> Deduplicator<'a, S> {
    /// Create a new deduplicator
    pub fn new(store: &'a dyn Store, search: &'a S) -> Self { todo!() }

    /// Find entries similar to the given content
    ///
    /// Uses normalized BM25 scores - the highest scoring entry gets 1.0,
    /// and others are scaled proportionally.
    pub fn find_similar(
        &self,
        content: &str,
        threshold: f64,
    ) -> Result<Vec<SimilarityResult>, CoreError> { todo!() }

    /// Merge new content into an existing entry
    pub fn merge_content(&self, entry_id: &str, new_content: &str) -> Result<(), CoreError> { todo!() }

    /// Check if content is a duplicate (similarity above threshold)
    pub fn is_duplicate(&self, content: &str, threshold: f64) -> Result<bool, CoreError> { todo!() }

    /// Find the most similar entry
    pub fn find_most_similar(
        &self,
        content: &str,
        threshold: f64,
    ) -> Result<Option<SimilarityResult>, CoreError> { todo!() }
}

/// Deduplication action to take
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DedupAction {
    /// Add as new entry
    Add,
    /// Skip (duplicate exists)
    Skip,
    /// Merge with existing entry
    Merge,
}

/// Result of deduplication check
#[derive(Debug, Clone)]
pub struct DedupResult {
    /// Recommended action
    pub action: DedupAction,
    /// Similar entry if found
    pub similar: Option<SimilarityResult>,
}

impl DedupResult {
    /// Check if content should be added
    pub fn should_add(&self) -> bool { todo!() }

    /// Check if content should be skipped
    pub fn should_skip(&self) -> bool { todo!() }

    /// Check if content should be merged
    pub fn should_merge(&self) -> bool { todo!() }
}

/// Check what to do with new content based on similarity
pub fn check_dedup<S: SearchIndexTrait>(
    store: &dyn Store,
    search: &S,
    content: &str,
    threshold: f64,
    force: bool,
    skip_if_similar: bool,
    merge_if_similar: bool,
) -> Result<DedupResult, CoreError> { todo!() }

#[cfg(test)]
mod tests {
    use crate::dedup::*;

    #[test]
    fn test_dedup_action_equality() {
        assert_eq!(DedupAction::Add, DedupAction::Add);
        assert_ne!(DedupAction::Add, DedupAction::Skip);
        assert_ne!(DedupAction::Skip, DedupAction::Merge);
    }


    #[test]
    fn test_search_hit_debug() {
        let hit = SearchHit {
            id: "test-id".to_string(),
            bm25_score: 0.95,
        };
        let debug_str = format!("{hit:?}");
        assert!(debug_str.contains("test-id"));
        assert!(debug_str.contains("0.95"));
    }

    #[test]
    fn test_similarity_result_clone() {
        let entry = Entry::new("test-id".to_string(), "test content".to_string());
        let result = SimilarityResult {
            entry,
            similarity: 0.85,
        };
        let cloned = result.clone();
        assert_eq!(cloned.entry.id, "test-id");
        assert_eq!(cloned.similarity, 0.85);
    }
}
