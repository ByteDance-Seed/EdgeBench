//! Core business logic for CAS (Coding Agent System)
//!
//! This crate provides the core business logic layer for CAS, independent of
//! CLI or MCP concerns. It can be used as a library by external tools.
//!
//! # Architecture
//!
//! `cas-core` sits between the storage/embedding layers and the application layers:
//!
//! ```text
//! ┌─────────────────────────────────────────┐
//! │  Applications (CLI, MCP, Web)           │
//! └─────────────────────────────────────────┘
//!                     │
//!                     ▼
//! ┌─────────────────────────────────────────┐
//! │  cas-core (business logic)              │ <-- This crate
//! └─────────────────────────────────────────┘
//!                     │
//!             ┌───────┴───────┐
//!             ▼               ▼
//!       ┌───────────┐   ┌───────────┐
//!       │ cas-store │   │ cas-types │
//!       └───────────┘   └───────────┘
//! ```
//!
//! # Features
//!
//! - Unified error handling across all CAS subsystems
//! - Business logic for memory, task, rule, and skill management
//! - No CLI or MCP dependencies - usable as a library
//!
//! # Example
//!
//! ```rust,ignore
//! use cas_core::{CoreError, Result};
//!
//! fn process_entry() -> Result<()> {
//!     // Business logic here
//!     Ok(())
//! }
//! ```

pub mod dedup;
pub mod error;
pub mod extraction;
pub mod hooks;
pub mod migration;
pub mod search;
pub mod sync;

// Re-export error types for convenience
pub use error::{CoreError, Result};

// Re-export dedup types for convenience
pub use dedup::{
    DedupAction, DedupResult, Deduplicator, SearchHit, SearchIndexTrait, SimilarityResult,
    check_dedup,
};

// Re-export sync types for convenience
pub use sync::{SkillSyncReport, SkillSyncer, SpecSyncReport, SpecSyncer, SyncReport, Syncer};

// Re-export search types for convenience
pub use search::{
    DocType,
    EntityHistory,
    EntitySnapshot,
    HistoryEventType,
    LatencyTimer,
    MethodComparison,
    MethodMetrics,
    MetricsStore,
    QueryFeatures,
    QueryType,
    RelationshipEvent,
    ResultFeedback,
    SearchEvent,
    SearchIndex,
    SearchMethod,
    SearchOptions,
    SearchResult,
    SearchWeights,
    TemporalEntryResult,
    TemporalParseError,
    TemporalQuery,
    TemporalRelation,
    TemporalRetriever,
    TimePeriod,
    // Scorer types
    calibrate_scores,
    combine_multi_channel,
    combine_scores,
    extract_id_patterns,
    // Temporal types
    filter_entities_by_time,
    filter_entries_by_time,
    filter_relationships_by_time,
    // Metrics types
    generate_event_id,
    normalize_scores,
    parse_date_flexible,
    percentile_normalize,
    reciprocal_rank_fusion,
    rrf_with_magnitude,
};

// Re-export extraction types for convenience
pub use extraction::{
    // Core extraction
    AIExtractor,
    AIExtractorConfig,
    DeferredExtractor,
    // Entity extraction
    EntityExtractionResult,
    EntityExtractor,
    EntityExtractorConfig,
    ExtractedDecision,
    ExtractedEntity,
    // Summary generation
    ExtractedFact,
    ExtractedItem,
    ExtractedLearning,
    ExtractedRelationship,
    ExtractionResult,
    Extractor,
    PatternEntityExtractor,
    SuggestedRule,
    SummaryConfig,
    SummaryGenerator,
    TaskExtractionResult,
    ai_extractor,
    // Task extraction
    build_task_extraction_prompt,
    default_extractor,
    extract_from_task,
    learnings_to_entries,
    update_entity_summaries,
};

// Re-export hooks types for convenience
pub use hooks::{
    ContextItem, ContextItemType, ContextStats, ContextStores, DefaultHooksConfig, HookInput,
    HookOutput, HookSpecificOutput, HooksConfig, PlanModeConfig, SurfacedItemCallback,
    build_context_with_stores, build_plan_context_with_stores, check_promise_in_transcript,
    estimate_tokens, get_last_assistant_text, get_recent_assistant_messages, rule_matches_path,
    token_display, truncate,
};

// Re-export types from dependency crates for convenience
pub use cas_store;
pub use cas_types;
