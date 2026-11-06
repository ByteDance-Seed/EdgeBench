//! Observation and entity extraction pipeline
//!
//! Extracts learnings, preferences, rule suggestions, and knowledge graph entities
//! from raw observations using AI-powered analysis.
//!
//! # Overview
//!
//! This module defines extraction pipelines for:
//! - Converting raw observations into structured entries (learnings, preferences, rules)
//! - Extracting entities and relationships for the knowledge graph
//!
//! # Implementations
//!
//! - `DeferredExtractor` - Marks observations for later processing (default)
//! - `AIExtractor` - Uses Claude SDK for AI-powered extraction (requires `ai` feature)
//! - `EntityExtractor` - Extracts entities and relationships for knowledge graph
//! - `PatternEntityExtractor` - Simple pattern-based entity extraction (no AI)
//!
//! # Usage
//!
//! ```rust,ignore
//! use cas_core::extraction::{Extractor, AIExtractor, AIExtractorConfig};
//!
//! // Create AI extractor
//! let config = AIExtractorConfig::default();
//! let extractor = AIExtractor::new(config);
//!
//! // Extract from observation (async)
//! let result = extractor.extract_async(&observation).await?;
//! ```

// Entity extraction module for knowledge graph feature
pub mod entities;

// Entity summary generation (Hindsight observation network)
pub mod summary;

// Task knowledge extraction - extracts learnings from task close_reason and notes
pub mod tasks;

// Re-export commonly used types
pub use entities::{
    EntityExtractionResult, EntityExtractor, EntityExtractorConfig, ExtractedEntity,
    ExtractedRelationship, PatternEntityExtractor,
};
pub use summary::{ExtractedFact, SummaryConfig, SummaryGenerator, update_entity_summaries};
pub use tasks::{
    ExtractedDecision, ExtractedLearning, SuggestedRule, TaskExtractionResult,
    build_task_extraction_prompt, extract_from_task, learnings_to_entries,
};

use crate::error::CoreError;
use cas_types::Entry;

/// Result of extraction from an observation
#[derive(Debug, Clone, Default)]
pub struct ExtractionResult {
    /// Extracted learnings (facts and patterns)
    pub learnings: Vec<ExtractedItem>,

    /// Extracted preferences (user preferences and style)
    pub preferences: Vec<ExtractedItem>,

    /// Suggested rules (patterns to promote)
    pub rules: Vec<ExtractedItem>,

    /// Whether extraction was deferred for later processing
    pub deferred: bool,
}

/// A single extracted item
#[derive(Debug, Clone)]
pub struct ExtractedItem {
    /// The extracted content
    pub content: String,

    /// Confidence score (0.0 - 1.0)
    pub confidence: f32,

    /// Quality score (1-10) - only items with score >= 6 should be kept
    pub quality_score: Option<u8>,

    /// Tags to apply
    pub tags: Vec<String>,

    /// Source observation ID
    pub source_id: String,

    /// Whether this should become a rule
    pub should_be_rule: bool,

    /// Glob pattern for rule paths (if should_be_rule is true)
    pub rule_paths: Option<String>,
}

/// Trait for extraction implementations
pub trait Extractor: Send + Sync {
    /// Extract structured information from an observation (sync, may defer)
    fn extract(&self, observation: &Entry) -> Result<ExtractionResult, CoreError>;

    /// Process multiple observations in batch (default: process individually)
    fn extract_batch(&self, observations: &[Entry]) -> Result<Vec<ExtractionResult>, CoreError> { todo!() }

    /// Extract from multiple observations with shared context (batched for quality)
    /// This is the preferred method - provides context across observations
    fn extract_batched(&self, observations: &[Entry]) -> Result<ExtractionResult, CoreError> { todo!() }
}

/// Placeholder extractor that marks entries for later processing
///
/// This is the default extractor when no AI extraction is available.
/// It simply marks observations as pending and returns empty results.
pub struct DeferredExtractor;

impl Extractor for DeferredExtractor {
    fn extract(&self, _observation: &Entry) -> Result<ExtractionResult, CoreError> { todo!() }
}

/// Configuration for AI-powered extraction
#[derive(Debug, Clone)]
pub struct AIExtractorConfig {
    /// Model to use for extraction
    pub model: String,

    /// Maximum thinking tokens for complex analysis
    pub max_thinking_tokens: u32,

    /// Whether to extract learnings
    pub extract_learnings: bool,

    /// Whether to extract preferences
    pub extract_preferences: bool,

    /// Whether to suggest rules
    pub suggest_rules: bool,
}

impl Default for AIExtractorConfig {
    fn default() -> Self { todo!() }
}

/// AI-powered extractor using Claude SDK
///
/// Uses Claude to analyze observations and extract structured information.
/// This struct provides the configuration and prompt building logic.
/// Actual AI calls must be performed by the application layer.
///
/// # Example
///
/// ```rust,ignore
/// use cas_core::extraction::{AIExtractor, AIExtractorConfig};
///
/// let config = AIExtractorConfig::default();
/// let extractor = AIExtractor::new(config);
///
/// // Build prompt for AI call
/// let prompt = extractor.build_prompt(&observation);
/// // Application layer makes AI call and parses response
/// let result = extractor.parse_response(&response_text, &observation.id)?;
/// ```
pub struct AIExtractor {
    /// Configuration for extraction
    config: AIExtractorConfig,
}

impl AIExtractor {
    /// Create a new AI extractor with the given configuration
    pub fn new(config: AIExtractorConfig) -> Self { todo!() }

    /// Get the model name for this extractor
    pub fn model(&self) -> &str { todo!() }

    /// Get the max thinking tokens setting
    pub fn max_thinking_tokens(&self) -> u32 { todo!() }

    /// Build the extraction prompt for Claude (single observation)
    pub fn build_prompt(&self, observation: &Entry) -> String { todo!() }

    /// Build the extraction prompt for batched observations
    /// Batching provides better context for quality assessment
    pub fn build_batch_prompt(&self, observations: &[Entry]) -> String { todo!() }

    /// Parse Claude's JSON response into ExtractionResult
    pub fn parse_response(
        &self,
        response: &str,
        source_id: &str,
    ) -> Result<ExtractionResult, CoreError> { todo!() }

    /// Parse a single extracted item from JSON
    fn parse_item(&self, value: &serde_json::Value, source_id: &str) -> Option<ExtractedItem> { todo!() }
}

impl Extractor for AIExtractor {
    fn extract(&self, _observation: &Entry) -> Result<ExtractionResult, CoreError> { todo!() }
}

/// Get the default extractor
pub fn default_extractor() -> Box<dyn Extractor> { todo!() }

/// Get an AI extractor with default config
pub fn ai_extractor() -> AIExtractor { todo!() }

#[cfg(test)]
mod tests;
