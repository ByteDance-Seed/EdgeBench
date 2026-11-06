//! Observation and entity extraction pipeline
//!
//! This module re-exports extraction types from `cas-core` and extends them
//! with async AI-powered extraction methods using the `claude_rs` SDK.
//!
//! # Architecture
//!
//! - Core types and sync methods: `cas_core::extraction`
//! - Async AI extraction: This module (extensions)
//!
//! # Usage
//!
//! ```rust,ignore
//! use crate::extraction::{AIExtractor, AIExtractorConfig};
//!
//! // Create AI extractor
//! let config = AIExtractorConfig::default();
//! let extractor = AIExtractor::new(config);
//!
//! // Build prompt (from cas-core)
//! let prompt = extractor.build_prompt(&observation);
//!
//! // Run async extraction (from this module)
//! let result = extractor.extract_async(&observation).await?;
//! ```

// Re-export everything from cas_core::extraction
pub use cas_core::extraction::*;

// Re-export submodules from cas_core for backward compatibility
pub mod entities {
    pub use cas_core::extraction::entities::*;

    // Extension trait for async entity extraction
    use crate::error::CasError;
    use cas_types::Entry;

    /// Extension trait for async entity extraction
    #[allow(async_fn_in_trait)]
    pub trait EntityExtractorAsync {
        /// Async extraction using claude_rs SDK
        async fn extract_async(
            &self,
            entry: &Entry,
        ) -> Result<cas_core::extraction::EntityExtractionResult, CasError>;
    }

    impl EntityExtractorAsync for cas_core::extraction::EntityExtractor {
        async fn extract_async(
            &self,
            entry: &Entry,
        ) -> Result<cas_core::extraction::EntityExtractionResult, CasError> { todo!() }
    }
}

pub mod summary {
    pub use cas_core::extraction::summary::*;
}

pub mod tasks {
    pub use cas_core::extraction::tasks::*;
}

// Extension trait for async AI extraction
use crate::error::MemError;
use cas_types::Entry;

/// Extension trait for async AI extraction
#[allow(async_fn_in_trait)]
pub trait AIExtractorAsync {
    /// Async extraction using claude_rs SDK (single observation)
    async fn extract_async(&self, observation: &Entry) -> Result<ExtractionResult, MemError>;

    /// Async batched extraction (multiple observations with shared context)
    async fn extract_batch_async(
        &self,
        observations: &[Entry],
    ) -> Result<ExtractionResult, MemError>;
}

impl AIExtractorAsync for AIExtractor {
    async fn extract_async(&self, observation: &Entry) -> Result<ExtractionResult, MemError> { todo!() }

    async fn extract_batch_async(
        &self,
        observations: &[Entry],
    ) -> Result<ExtractionResult, MemError> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::extraction::*;
    use cas_types::EntryType;

    #[test]
    fn test_deferred_extractor() {
        let extractor = DeferredExtractor;
        let observation = Entry {
            id: "test".to_string(),
            entry_type: EntryType::Observation,
            content: "Test observation".to_string(),
            ..Default::default()
        };

        let result = extractor.extract(&observation).unwrap();
        assert!(result.deferred);
        assert!(result.learnings.is_empty());
    }


    #[test]
    fn test_extraction_result_default() {
        let result = ExtractionResult::default();
        assert!(result.learnings.is_empty());
        assert!(result.preferences.is_empty());
        assert!(result.rules.is_empty());
        assert!(!result.deferred);
    }

    #[test]
    fn test_build_prompt() {
        let extractor = AIExtractor::new(AIExtractorConfig::default());
        let observation = Entry {
            id: "2024-01-15-001".to_string(),
            entry_type: EntryType::Observation,
            content: "Write: src/main.rs - added new handler for API endpoints".to_string(),
            source_tool: Some("Write".to_string()),
            ..Default::default()
        };

        let prompt = extractor.build_prompt(&observation);
        assert!(prompt.contains("Quality Standards"));
        assert!(prompt.contains("quality_score"));
        assert!(prompt.contains("Project-specific"));
        assert!(prompt.contains("[Write]"));
    }




    #[test]
    fn test_ai_extractor_constructor() {
        let extractor = ai_extractor();
        let observation = Entry {
            id: "test".to_string(),
            entry_type: EntryType::Observation,
            content: "Test observation for extraction".to_string(),
            ..Default::default()
        };

        let result = extractor.extract(&observation).unwrap();
        assert!(result.deferred);
    }

    #[test]
    fn test_extractor_trait_batch() {
        let extractor = DeferredExtractor;
        let observations = vec![
            Entry {
                id: "obs1".to_string(),
                entry_type: EntryType::Observation,
                content: "First observation".to_string(),
                ..Default::default()
            },
            Entry {
                id: "obs2".to_string(),
                entry_type: EntryType::Observation,
                content: "Second observation".to_string(),
                ..Default::default()
            },
        ];

        let results = extractor.extract_batch(&observations).unwrap();
        assert_eq!(results.len(), 2);
        assert!(results[0].deferred);
        assert!(results[1].deferred);
    }
}
