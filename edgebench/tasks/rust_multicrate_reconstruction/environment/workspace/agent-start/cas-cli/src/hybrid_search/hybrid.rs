//! Hybrid search combining BM25, semantic, temporal, graph, and code search (Hindsight-inspired)
//!
//! This module provides a 6-channel hybrid search:
//! 1. BM25 (lexical) - traditional text matching
//! 2. Semantic - embedding-based similarity
//! 3. Temporal - time-aware retrieval using valid_from/valid_until
//! 4. Graph - spreading activation over entity relationships
//! 5. Code - semantic code search over indexed symbols
//! 6. Reranking (optional) - ML-based score refinement

use std::hash::{Hash, Hasher};
use std::path::Path;
use std::sync::Arc;

use std::path::Path as StdPath;

use crate::hybrid_search::cache::SearchCache;
use crate::hybrid_search::code::{CasCodeSearch, open_code_search};
use crate::hybrid_search::graph::{GraphRetriever, SpreadingActivationConfig};
use crate::hybrid_search::scorer::{
    SearchWeights, calibrate_scores, combine_multi_channel, rrf_with_magnitude,
};
use crate::hybrid_search::temporal::{TemporalRetriever, TimePeriod};
use crate::hybrid_search::{DocType, SearchIndex, SearchOptions, SearchResult};
// Note: Local embeddings have been removed. Semantic search is now cloud-only.
// The hybrid search continues to support BM25, temporal, graph, and code search locally.
use crate::error::Result;
use crate::store::EntityStore;
use crate::types::Entry;
use cas_search::CodeSearchOptions;

/// Options specific to hybrid search
#[derive(Debug, Clone)]
pub struct HybridSearchOptions {
    /// Base search options (query, limit, filters)
    pub base: SearchOptions,

    /// Enable semantic search component
    pub enable_semantic: bool,

    /// Enable temporal search component (Hindsight-inspired)
    pub enable_temporal: bool,

    /// Enable graph-based search component (Hindsight-inspired)
    pub enable_graph: bool,

    /// Enable code search component (searches indexed code symbols)
    pub enable_code: bool,

    /// Weight for BM25 score (0.0-1.0) - only used if use_adaptive_weights is false
    pub bm25_weight: f32,

    /// Weight for semantic score (0.0-1.0) - only used if use_adaptive_weights is false
    pub semantic_weight: f32,

    /// Weight for temporal score (0.0-1.0) - only used if use_adaptive_weights is false
    pub temporal_weight: f32,

    /// Weight for graph score (0.0-1.0) - only used if use_adaptive_weights is false
    pub graph_weight: f32,

    /// Weight for code score (0.0-1.0) - only used if use_adaptive_weights is false
    pub code_weight: f32,

    /// Enable reranking of top results
    pub enable_rerank: bool,

    /// Number of candidates to fetch before reranking
    pub rerank_candidates: usize,

    /// Use Reciprocal Rank Fusion instead of weighted sum
    pub use_rrf: bool,

    /// RRF constant (typically 60)
    pub rrf_k: f64,

    /// Explicit temporal period to search (overrides auto-extraction)
    pub temporal_period: Option<TimePeriod>,

    /// Use adaptive weights based on query analysis (recommended)
    pub use_adaptive_weights: bool,

    /// Calibrate final scores to meaningful 0-1 range
    pub calibrate_scores: bool,
}

impl Default for HybridSearchOptions {
    fn default() -> Self { todo!() }
}

impl HybridSearchOptions {
    /// Compute a hash of the search options for cache keying
    pub fn cache_key(&self) -> u64 { todo!() }
}

/// Extended search result with hybrid scores
#[derive(Debug, Clone)]
pub struct HybridSearchResult {
    /// Entry ID
    pub id: String,
    /// Final combined score
    pub score: f64,
    /// BM25 component score (normalized)
    pub bm25_score: f64,
    /// Semantic component score (cosine similarity)
    pub semantic_score: f64,
    /// Temporal component score (time-relevance)
    pub temporal_score: f64,
    /// Graph component score (spreading activation)
    pub graph_score: f64,
    /// Code search component score
    pub code_score: f64,
    /// Rerank score (if reranking enabled)
    pub rerank_score: Option<f64>,
}

/// Consolidated channel scores for a single result
///
/// Instead of 5 separate HashMaps, we use a single map with this struct
/// to reduce memory allocation and simplify score merging logic.
#[derive(Debug, Clone, Default)]
struct ChannelScores {
    bm25: f64,
    semantic: f64,
    temporal: f64,
    graph: f64,
    code: f64,
}

impl From<HybridSearchResult> for SearchResult {
    fn from(h: HybridSearchResult) -> Self { todo!() }
}

/// Hybrid search orchestrator combining BM25, temporal, graph, and code search
///
/// Note: Local semantic/embedding search has been removed and is now cloud-only.
/// This orchestrator still supports BM25 full-text search, temporal filtering,
/// knowledge graph traversal, and code symbol search.
pub struct HybridSearch {
    bm25_index: SearchIndex,
    graph_retriever: Option<GraphRetriever>,
    /// Code search for semantic code symbol search
    code_search: Option<CasCodeSearch>,
    /// Query and results cache for performance
    cache: Arc<SearchCache>,
}

impl HybridSearch {
    /// Create a new hybrid search instance
    pub fn new(bm25_index: SearchIndex) -> Self { todo!() }

    /// Create a new hybrid search instance with a shared cache
    pub fn with_cache(bm25_index: SearchIndex, cache: Arc<SearchCache>) -> Self { todo!() }

    /// Create a new hybrid search instance with graph retriever
    pub fn with_graph(bm25_index: SearchIndex, entity_store: Arc<dyn EntityStore>) -> Self { todo!() }

    /// Create a new hybrid search instance with custom graph config
    pub fn with_graph_config(
        bm25_index: SearchIndex,
        entity_store: Arc<dyn EntityStore>,
        graph_config: SpreadingActivationConfig,
    ) -> Self { todo!() }

    /// Open hybrid search from a CAS directory
    ///
    /// Note: Local semantic search has been removed and is now cloud-only.
    /// This opens BM25 search only.
    pub fn open(cas_dir: &Path) -> Result<Self> { todo!() }

    /// Open hybrid search with graph retriever (knowledge graph enabled)
    pub fn open_with_graph(cas_dir: &Path) -> Result<Self> { todo!() }

    /// Open hybrid search with graph retriever enabled
    ///
    /// Note: Local reranker has been removed and is now cloud-only.
    /// This is now equivalent to `open_with_graph`.
    pub fn open_full(cas_dir: &Path) -> Result<Self> { todo!() }

    /// Set the graph retriever (requires entity store)
    pub fn set_graph_retriever(&mut self, entity_store: Arc<dyn EntityStore>) { todo!() }

    /// Set the graph retriever with custom config
    pub fn set_graph_retriever_with_config(
        &mut self,
        entity_store: Arc<dyn EntityStore>,
        config: SpreadingActivationConfig,
    ) { todo!() }

    /// Set the code search from a CAS directory path
    ///
    /// Opens all required components (code store, vector store, BM25 index, embedder)
    /// and wires them together into a CasCodeSearch instance.
    pub fn set_code_search_from_path(&mut self, cas_dir: &StdPath) -> Result<()> { todo!() }

    /// Set the code search directly from an existing instance
    pub fn set_code_search(&mut self, code_search: CasCodeSearch) { todo!() }

    /// Perform hybrid search (6-channel: BM25 + semantic + temporal + graph + code + rerank)
    pub fn search(
        &self,
        opts: &HybridSearchOptions,
        entries: &[Entry],
    ) -> Result<Vec<HybridSearchResult>> { todo!() }

    /// Generate recency scores for entries (fallback when no explicit temporal query)
    fn recency_scores(&self, entries: &[Entry], limit: usize) -> Vec<(String, f64)> { todo!() }

    /// Perform semantic-only search (with caching)
    /// Semantic search is now cloud-only. Returns empty results.
    ///
    /// Note: Local embeddings have been removed. For semantic search,
    /// use the cloud API via CAS Cloud.
    fn semantic_search(&self, _query: &str, _k: usize) -> Result<Vec<(String, f32)>> { todo!() }

    /// Index a single entry (BM25 only - embeddings are now cloud-only)
    pub fn index_entry(&self, entry: &Entry) -> Result<()> { todo!() }

    /// Delete from BM25 index
    pub fn delete(&self, id: &str) -> Result<()> { todo!() }

    /// Reindex all entries (BM25 only - embeddings are now cloud-only)
    pub fn reindex(&self, entries: &[Entry]) -> Result<()> { todo!() }

    /// Check if reranker is available
    ///
    /// Note: Local reranking has been removed and is now cloud-only.
    /// Always returns false.
    pub fn has_reranker(&self) -> bool { todo!() }

    /// Check if graph retriever is available
    pub fn has_graph_retriever(&self) -> bool { todo!() }

    /// Check if code search is available
    pub fn has_code_search(&self) -> bool { todo!() }

    /// Get a reference to the search cache
    pub fn cache(&self) -> &Arc<SearchCache> { todo!() }

    /// Get cache statistics
    pub fn cache_stats(&self) -> super::cache::SearchCacheStats { todo!() }

    /// Invalidate cache entries for a specific entry ID
    ///
    /// Should be called when an entry is archived or otherwise modified
    /// outside of the index_entry/delete methods.
    pub fn invalidate_cache(&self, entry_id: &str) { todo!() }

    /// Clear all caches
    pub fn clear_cache(&self) { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::hybrid_search::hybrid::*;

    #[test]
    fn test_hybrid_search_options_default() {
        let opts = HybridSearchOptions::default();
        assert!(opts.enable_semantic);
        assert!(opts.enable_temporal);
        assert!(opts.enable_graph);
        assert!(!opts.enable_code); // Code search disabled by default
        assert_eq!(opts.bm25_weight, 0.30);
        assert_eq!(opts.semantic_weight, 0.30);
        assert_eq!(opts.temporal_weight, 0.15);
        assert_eq!(opts.graph_weight, 0.15);
        assert_eq!(opts.code_weight, 0.10);
        assert!(!opts.enable_rerank);
        assert!(!opts.use_rrf);
        assert!(opts.use_adaptive_weights);
        assert!(opts.calibrate_scores);
    }


    #[test]
    fn test_temporal_query_extraction() {
        // Test that temporal expressions are extracted from queries
        let query = "what did I learn last week about rust";
        if let Some((cleaned, period)) = TemporalRetriever::extract_temporal_query(query) {
            assert!(!cleaned.contains("last week"));
            // Period should cover ~7 days ago to now
            assert!(period.start < chrono::Utc::now());
        }
    }
}
