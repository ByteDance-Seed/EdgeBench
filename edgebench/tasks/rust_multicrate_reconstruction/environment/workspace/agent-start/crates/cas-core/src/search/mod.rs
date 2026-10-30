//! Full-text search using Tantivy
//!
//! This module provides comprehensive search capabilities for CAS:
//!
//! - **BM25 Search** - Traditional text search using Tantivy
//! - **Hybrid Search** - Combines BM25 with semantic embeddings
//! - **Reranking** - Optional ML-powered result reranking
//!
//! # Search Features
//!
//! - Feedback boosting (higher score for helpful entries)
//! - Recency boosting (exponential decay based on age)
//! - Importance boosting (based on priority/stability scores)
//! - Tag and type filtering
//! - Multi-type search (entries, tasks, rules, skills)
//!
//! # Usage
//!
//! ```rust,ignore
//! use cas_core::search::{SearchIndex, SearchOptions};
//!
//! // BM25-only search
//! let index = SearchIndex::open(&index_dir)?;
//! let opts = SearchOptions {
//!     query: "rust testing".to_string(),
//!     limit: 10,
//!     boost_feedback: true,
//!     ..Default::default()
//! };
//! let results = index.search(&opts, &entries)?;
//! ```
//!
//! # Score Normalization
//!
//! The [`scorer`] module provides utilities for normalizing and combining
//! scores from different search methods, including Reciprocal Rank Fusion (RRF).

mod index_ops;
mod query_ops;
#[cfg(test)]
mod tests;

pub mod metrics;
pub mod scorer;
pub mod temporal;

pub use metrics::{
    LatencyTimer, MethodComparison, MethodMetrics, MetricsStore, ResultFeedback, SearchEvent,
    SearchMethod, generate_event_id,
};
pub use scorer::{
    QueryFeatures, QueryType, SearchWeights, calibrate_scores, combine_multi_channel,
    combine_scores, normalize_scores, percentile_normalize, reciprocal_rank_fusion,
    rrf_with_magnitude,
};
pub use temporal::{
    EntityHistory, EntitySnapshot, HistoryEventType, RelationshipEvent, TemporalEntryResult,
    TemporalParseError, TemporalQuery, TemporalRelation, TemporalRetriever, TimePeriod,
    filter_entities_by_time, filter_entries_by_time, filter_relationships_by_time,
    parse_date_flexible,
};

use chrono::Duration;
use regex::Regex;
use std::path::Path;
use tantivy::schema::{Field, STORED, STRING, Schema, TEXT};
use tantivy::{Index, IndexWriter};

use crate::error::CoreError;

/// Extract CAS ID patterns from a query string
/// Returns (extracted_ids, remaining_query)
/// Matches patterns like: cas-XXXX, cas-sk0a, rule-041, etc.
pub fn extract_id_patterns(query: &str) -> (Vec<String>, String) { todo!() }

/// Document type for unified search
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum DocType {
    Entry,
    Task,
    Rule,
    Skill,
    Spec,
    CodeSymbol,
    CodeFile,
}

impl DocType {
    pub fn as_str(&self) -> &'static str { todo!() }

    pub fn parse(s: &str) -> Option<Self> { todo!() }
}

/// Search index backed by Tantivy
pub struct SearchIndex {
    pub(crate) index: Index,
    pub(crate) schema: Schema,
    pub(crate) id_field: Field,
    pub(crate) content_field: Field,
    pub(crate) tags_field: Field,
    pub(crate) type_field: Field,
    pub(crate) title_field: Field,
    pub(crate) doc_type_field: Field,
}

/// Options for search queries
#[derive(Debug, Clone)]
pub struct SearchOptions {
    pub query: String,
    pub limit: usize,
    pub boost_feedback: bool,
    pub boost_recency: bool,
    pub boost_importance: bool,
    pub recency_half_life: Duration,
    pub tags: Vec<String>,
    pub types: Vec<String>,
    pub doc_types: Vec<DocType>,
    pub include_archived: bool,
}

impl Default for SearchOptions {
    fn default() -> Self { todo!() }
}

/// A search result with scoring information
#[derive(Debug, Clone)]
pub struct SearchResult {
    pub id: String,
    pub doc_type: DocType,
    pub score: f64,
    pub bm25_score: f64,
    pub boosted_score: f64,
}

impl SearchIndex {
    /// Open or create a search index
    pub fn open(index_dir: &Path) -> Result<Self, CoreError> { todo!() }

    /// Create an in-memory search index (for testing)
    pub fn in_memory() -> Result<Self, CoreError> { todo!() }

    pub(crate) fn writer(&self) -> Result<IndexWriter, CoreError> { todo!() }

    pub fn field_names(&self) -> Vec<&str> { todo!() }

    pub fn field_count(&self) -> usize { todo!() }
}
