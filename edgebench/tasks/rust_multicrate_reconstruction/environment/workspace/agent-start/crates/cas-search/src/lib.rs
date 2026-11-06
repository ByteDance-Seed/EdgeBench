//! CAS Search Infrastructure
//!
//! This crate provides search capabilities for CAS:
//!
//! - **BM25 full-text search** via Tantivy ([`Bm25Index`])
//! - **Vector storage** via heed (LMDB wrapper) ([`LmdbVectorStore`])
//! - **Hybrid search** (currently BM25-only, semantic search via cloud)
//!
//! # Core Traits
//!
//! - [`SearchDocument`] - Generic document representation for indexing
//! - [`VectorStore`] - Vector storage and similarity search
//! - [`TextIndex`] - Full-text (BM25) search index
//!
//! # Score Utilities
//!
//! The [`scorer`] module provides utilities for:
//! - Score normalization (min-max, percentile)
//! - Score combination (weighted, RRF)
//! - Similarity metrics (cosine, euclidean)
//!
//! # Example
//!
//! ```rust,ignore
//! use cas_search::{Bm25Index, SearchDocument, VectorStore, TextIndex, scorer};
//!
//! // Implement SearchDocument for your types
//! struct MyDoc { /* ... */ }
//! impl SearchDocument for MyDoc { /* ... */ }
//!
//! // Create BM25 index
//! let index = Bm25Index::in_memory()?;
//! index.index(&my_doc)?;
//! let results = index.search("query", 10)?;
//!
//! // Combine BM25 and semantic scores
//! let combined = scorer::combine_weighted(&bm25_scores, &semantic_scores, 0.4, 0.6);
//! ```

pub mod bm25;
pub mod code_search;
pub mod document;
pub mod error;
pub mod grep;
pub mod hybrid;
pub mod lmdb_store;
pub mod metrics;
pub mod parallel;
pub mod scorer;
pub mod traits;

// Re-export core types
pub use bm25::{Bm25Config, Bm25Index};
pub use code_search::{CodeSearch, CodeSearchOptions, CodeSearchResult, CodeSearchStats, Embedder};
pub use error::{Result, SearchError};
pub use lmdb_store::{LmdbEnvInfo, LmdbVectorStore};
pub use traits::{ScoreSource, SearchDocument, SearchResult, TextIndex, VectorStore};

// Re-export async types when parallel feature is enabled
#[cfg(feature = "parallel")]
pub use bm25::AsyncBm25Index;
#[cfg(feature = "parallel")]
pub use traits::{AsyncEmbedder, AsyncTextIndex, AsyncVectorStore};

// Re-export scorer utilities
pub use scorer::{
    calibrate, combine_weighted, cosine_similarity, distance_to_similarity, euclidean_distance,
    normalize_min_max, normalize_percentile, reciprocal_rank_fusion,
};

// Re-export grep types
pub use grep::{GrepMatch, GrepOptions, GrepSearch};

// Re-export hybrid search types
pub use hybrid::{
    Embedder as HybridEmbedder, HybridSearch, HybridSearchOptions, HybridSearchResult,
};

// Re-export metrics types
pub use metrics::{
    LatencyTimer, MethodComparison, MethodMetrics, MetricsStore, ResultFeedback, SearchEvent,
    SearchMethod, generate_event_id,
};

// Re-export parallel search utilities
pub use parallel::{
    ChannelTimer, ParallelCoordinator, ParallelResult, ParallelStats, timed_search,
};

#[cfg(feature = "parallel")]
pub use parallel::{ParallelExecutor, SearchTask};

// Re-export external crates for consumers
/// Re-export heed for vector storage backends
pub use heed;

/// Re-export tantivy for BM25 search backends
pub use tantivy;
