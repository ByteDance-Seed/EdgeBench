//! Entity extraction from memory entries
//!
//! Extracts entities (people, projects, concepts, files, tools) and their
//! relationships from memory content using AI-powered analysis.

use crate::error::CoreError;
use cas_types::{Entity, EntityMention, EntityType, Entry, RelationType, Relationship};

/// Result of entity extraction from an entry
#[derive(Debug, Clone, Default)]
pub struct EntityExtractionResult {
    /// Extracted entities
    pub entities: Vec<ExtractedEntity>,

    /// Extracted relationships between entities
    pub relationships: Vec<ExtractedRelationship>,

    /// Whether extraction was deferred for later processing
    pub deferred: bool,
}

/// An extracted entity before storage
#[derive(Debug, Clone)]
pub struct ExtractedEntity {
    /// Entity name
    pub name: String,

    /// Entity type
    pub entity_type: EntityType,

    /// Alternative names/aliases found
    pub aliases: Vec<String>,

    /// Description from context
    pub description: Option<String>,

    /// Confidence score (0.0 - 1.0)
    pub confidence: f32,

    /// Position in the source text (character offset)
    pub position: Option<usize>,

    /// The matched text in the source
    pub matched_text: Option<String>,
}

impl ExtractedEntity {
    /// Convert to an Entity for storage
    pub fn to_entity(&self, id: String) -> Entity { todo!() }

    /// Create an EntityMention for linking to an entry
    pub fn to_mention(&self, entity_id: String, entry_id: String) -> EntityMention { todo!() }
}

/// An extracted relationship before storage
#[derive(Debug, Clone)]
pub struct ExtractedRelationship {
    /// Source entity name
    pub source_name: String,

    /// Target entity name
    pub target_name: String,

    /// Relationship type
    pub relation_type: RelationType,

    /// Description/context
    pub description: Option<String>,

    /// Confidence score (0.0 - 1.0)
    pub confidence: f32,
}

impl ExtractedRelationship {
    /// Convert to a Relationship for storage (requires entity IDs to be resolved)
    pub fn to_relationship(
        &self,
        id: String,
        source_id: String,
        target_id: String,
        entry_id: &str,
    ) -> Relationship { todo!() }
}

/// Configuration for entity extraction
#[derive(Debug, Clone)]
pub struct EntityExtractorConfig {
    /// Model to use for extraction
    pub model: String,

    /// Minimum confidence threshold to include entities
    pub min_confidence: f32,

    /// Maximum entities to extract per entry
    pub max_entities: usize,

    /// Maximum relationships to extract per entry
    pub max_relationships: usize,
}

impl Default for EntityExtractorConfig {
    fn default() -> Self { todo!() }
}

/// Entity extractor using Claude
pub struct EntityExtractor {
    config: EntityExtractorConfig,
}

impl EntityExtractor {
    /// Create a new entity extractor
    pub fn new(config: EntityExtractorConfig) -> Self { todo!() }

    /// Create with default configuration
    pub fn default_extractor() -> Self { todo!() }

    /// Get the model name for this extractor
    pub fn model(&self) -> &str { todo!() }

    /// Get the minimum confidence threshold
    pub fn min_confidence(&self) -> f32 { todo!() }

    /// Build the extraction prompt
    pub fn build_prompt(&self, entry: &Entry) -> String { todo!() }

    /// Parse the extraction response
    pub fn parse_response(
        &self,
        response: &str,
        _entry_id: &str,
    ) -> Result<EntityExtractionResult, CoreError> { todo!() }

    fn parse_entity(&self, value: &serde_json::Value) -> Option<ExtractedEntity> { todo!() }

    fn parse_relationship(&self, value: &serde_json::Value) -> Option<ExtractedRelationship> { todo!() }

    /// Sync extraction (always defers to async)
    pub fn extract(&self, _entry: &Entry) -> Result<EntityExtractionResult, CoreError> { todo!() }
}

/// Simple pattern-based entity extractor (no AI required)
///
/// Uses regex patterns to identify common entity types without AI.
pub struct PatternEntityExtractor {
    /// Minimum entity name length
    pub min_name_length: usize,
}

impl Default for PatternEntityExtractor {
    fn default() -> Self { todo!() }
}

impl PatternEntityExtractor {
    /// Extract entities using simple patterns
    pub fn extract(&self, entry: &Entry) -> EntityExtractionResult { todo!() }

    fn extract_files(&self, content: &str) -> Vec<ExtractedEntity> { todo!() }

    fn extract_tools(&self, content: &str) -> Vec<ExtractedEntity> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::extraction::entities::*;
    use cas_types::EntryType;

    #[test]
    fn test_entity_extractor_build_prompt() {
        let extractor = EntityExtractor::default_extractor();
        let entry = Entry {
            id: "test-001".to_string(),
            entry_type: EntryType::Learning,
            content: "The Store trait in CAS handles all database operations.".to_string(),
            tags: vec!["rust".to_string()],
            ..Default::default()
        };

        let prompt = extractor.build_prompt(&entry);
        assert!(prompt.contains("test-001"));
        assert!(prompt.contains("Store trait"));
        assert!(prompt.contains("person"));
        assert!(prompt.contains("project"));
    }

    #[test]
    fn test_parse_entity_response() {
        let extractor = EntityExtractor::default_extractor();
        let response = r#"{
            "entities": [
                {"name": "CAS", "type": "project", "description": "Coding Agent System", "confidence": 0.9},
                {"name": "Rust", "type": "tool", "confidence": 0.8}
            ],
            "relationships": [
                {"source": "CAS", "target": "Rust", "type": "uses", "confidence": 0.85}
            ]
        }"#;

        let result = extractor.parse_response(response, "test-001").unwrap();
        assert_eq!(result.entities.len(), 2);
        assert_eq!(result.entities[0].name, "CAS");
        assert_eq!(result.entities[0].entity_type, EntityType::Project);
        assert_eq!(result.relationships.len(), 1);
        assert_eq!(result.relationships[0].relation_type, RelationType::Uses);
    }

    #[test]
    fn test_pattern_extractor_files() {
        let extractor = PatternEntityExtractor::default();
        let entry = Entry {
            id: "test".to_string(),
            content: "Modified src/main.rs and tests/cli_test.rs".to_string(),
            ..Default::default()
        };

        let result = extractor.extract(&entry);
        let file_entities: Vec<_> = result
            .entities
            .iter()
            .filter(|e| e.entity_type == EntityType::File)
            .collect();

        assert!(file_entities.len() >= 2);
    }

    #[test]
    fn test_pattern_extractor_tools() {
        let extractor = PatternEntityExtractor::default();
        let entry = Entry {
            id: "test".to_string(),
            content: "Using Rust and SQLite for the database layer".to_string(),
            ..Default::default()
        };

        let result = extractor.extract(&entry);
        let tool_names: Vec<_> = result.entities.iter().map(|e| e.name.as_str()).collect();

        assert!(tool_names.contains(&"Rust"));
        assert!(tool_names.contains(&"SQLite"));
    }

    #[test]
    fn test_extracted_entity_conversion() {
        let extracted = ExtractedEntity {
            name: "CAS".to_string(),
            entity_type: EntityType::Project,
            aliases: vec!["Coding Agent System".to_string()],
            description: Some("Memory system".to_string()),
            confidence: 0.9,
            position: Some(10),
            matched_text: Some("CAS".to_string()),
        };

        let entity = extracted.to_entity("ent-001".to_string());
        assert_eq!(entity.name, "CAS");
        assert_eq!(entity.entity_type, EntityType::Project);
        assert_eq!(entity.aliases, vec!["Coding Agent System"]);

        let mention = extracted.to_mention("ent-001".to_string(), "entry-001".to_string());
        assert_eq!(mention.entity_id, "ent-001");
        assert_eq!(mention.position, Some(10));
    }

    #[test]
    fn test_extracted_relationship_conversion() {
        let extracted = ExtractedRelationship {
            source_name: "CAS".to_string(),
            target_name: "Rust".to_string(),
            relation_type: RelationType::Uses,
            description: Some("CAS is built with Rust".to_string()),
            confidence: 0.9,
        };

        let rel = extracted.to_relationship(
            "rel-001".to_string(),
            "ent-001".to_string(),
            "ent-002".to_string(),
            "entry-001",
        );

        assert_eq!(rel.source_id, "ent-001");
        assert_eq!(rel.target_id, "ent-002");
        assert_eq!(rel.relation_type, RelationType::Uses);
        assert!(rel.source_entries.contains(&"entry-001".to_string()));
    }

    #[test]
    fn test_entity_extractor_sync_defers() {
        let extractor = EntityExtractor::default_extractor();
        let entry = Entry {
            id: "test".to_string(),
            content: "Test content".to_string(),
            ..Default::default()
        };

        let result = extractor.extract(&entry).unwrap();
        assert!(result.deferred);
    }

    #[test]
    fn test_confidence_filtering() {
        let extractor = EntityExtractor::new(EntityExtractorConfig {
            min_confidence: 0.7,
            ..Default::default()
        });

        let response = r#"{
            "entities": [
                {"name": "HighConf", "type": "project", "confidence": 0.9},
                {"name": "LowConf", "type": "project", "confidence": 0.5}
            ],
            "relationships": []
        }"#;

        let result = extractor.parse_response(response, "test").unwrap();
        assert_eq!(result.entities.len(), 1);
        assert_eq!(result.entities[0].name, "HighConf");
    }
}
