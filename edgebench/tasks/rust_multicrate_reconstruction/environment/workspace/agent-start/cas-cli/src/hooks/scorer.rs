//! Context scorer using BM25 search
//!
//! This module provides a ContextScorer implementation that uses BM25
//! text search combined with temporal scoring for context selection.
//! Semantic/embedding-based scoring has been removed.

use std::collections::HashMap;
use std::path::Path;

use cas_core::hooks::{BasicContextScorer, ContextQuery, ContextScorer};
use cas_types::Entry;

use crate::error::Result;
use crate::hybrid_search::{HybridSearch, HybridSearchOptions, SearchOptions};

/// Context scorer using BM25 + temporal search
///
/// Uses BM25 text matching and temporal signals to score entries for
/// context selection. Falls back to basic scoring if search fails.
pub struct HybridContextScorer {
    hybrid_search: HybridSearch,
}

impl HybridContextScorer {
    /// Create a new hybrid context scorer
    pub fn new(hybrid_search: HybridSearch) -> Self { todo!() }

    /// Try to open hybrid context scorer from a CAS directory
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    /// Try to open with graph retriever for better context awareness
    pub fn open_with_graph(cas_dir: &Path) -> Result<Self> { todo!() }

    /// Score entries using hybrid search
    fn score_with_hybrid(&self, entries: &[Entry], query: &str) -> Result<Vec<(String, f32)>> { todo!() }
}

impl ContextScorer for HybridContextScorer {
    fn score_entries(&self, entries: &[Entry], context: &ContextQuery) -> Vec<(Entry, f32)> { todo!() }

    fn name(&self) -> &'static str { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::hooks::scorer::*;
    use cas_types::EntryType;

    #[test]
    fn test_context_query_empty() {
        let context = ContextQuery::default();
        assert!(!context.has_content());
        assert!(
            context.to_query_string().is_empty() || context.to_query_string().trim().is_empty()
        );
    }


    #[test]
    fn test_fallback_to_basic() {
        // Without a real hybrid search, we can only test the fallback behavior
        let entries = vec![Entry {
            id: "1".to_string(),
            entry_type: EntryType::Learning,
            created: chrono::Utc::now(),
            ..Default::default()
        }];

        // Empty context should use basic scoring
        let context = ContextQuery::default();
        let scored = BasicContextScorer.score_entries(&entries, &context);
        assert_eq!(scored.len(), 1);
        assert!(scored[0].1 > 0.0);
    }
}
