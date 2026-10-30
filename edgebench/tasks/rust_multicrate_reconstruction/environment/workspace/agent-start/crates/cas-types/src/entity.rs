//! Entity and relationship types for the knowledge graph
//!
//! This module defines the core types for CAS's knowledge graph feature,
//! inspired by Graphiti's temporal knowledge graph patterns.
//!
//! # Node Types (Entities)
//!
//! - **Person** - People mentioned in memories (teammates, users, etc.)
//! - **Project** - Projects, repositories, or codebases
//! - **Concept** - Abstract concepts (authentication, caching, etc.)
//! - **File** - Files and directories in the codebase
//! - **Tool** - Tools, libraries, and technologies
//! - **Organization** - Companies, teams, or groups
//!
//! # Integration Status
//! Entity extraction and graph building ready for GraphRetriever integration.

// Dead code check enabled - all items used

//! # Edge Types (Relationships)
//!
//! - **WorksOn** - Person works on project
//! - **Uses** - Entity uses tool/technology
//! - **MentionedIn** - Entity is mentioned in memory entry
//! - **RelatedTo** - General semantic relationship
//! - **PartOf** - Hierarchy/composition (file part of project)
//! - **DependsOn** - Dependency relationship
//! - **Created** - Entity created something
//! - **Modified** - Entity modified something

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;

/// Types of entities (nodes) in the knowledge graph
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default, Hash)]
#[serde(rename_all = "lowercase")]
pub enum EntityType {
    /// A person (teammate, user, contributor)
    Person,
    /// A project, repository, or codebase
    Project,
    /// An abstract concept (authentication, caching, design pattern)
    #[default]
    Concept,
    /// A file or directory
    File,
    /// A tool, library, or technology
    Tool,
    /// A company, team, or organization
    Organization,
}

impl fmt::Display for EntityType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for EntityType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Types of relationships (edges) between entities
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default, Hash)]
#[serde(rename_all = "snake_case")]
pub enum RelationType {
    /// Person works on project
    WorksOn,
    /// Entity uses tool/technology
    Uses,
    /// Entity is mentioned in a memory entry
    MentionedIn,
    /// General semantic relationship
    #[default]
    RelatedTo,
    /// Hierarchy/composition (file part of project)
    PartOf,
    /// Dependency relationship
    DependsOn,
    /// Entity created something
    Created,
    /// Entity modified something
    Modified,
    /// Entity knows/is associated with another entity
    Knows,
    /// Entity owns something
    Owns,
    /// Entity implements something (interface, pattern)
    Implements,
}

impl fmt::Display for RelationType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for RelationType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// An entity (node) in the knowledge graph
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Entity {
    /// Unique identifier (e.g., "ent-001" or derived from name hash)
    pub id: String,

    /// The canonical name of the entity
    pub name: String,

    /// Type of entity
    #[serde(rename = "type")]
    pub entity_type: EntityType,

    /// Alternative names/aliases for this entity
    #[serde(default)]
    pub aliases: Vec<String>,

    /// Optional description or summary
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    /// When the entity was first observed
    pub created: DateTime<Utc>,

    /// When the entity was last updated
    pub updated: DateTime<Utc>,

    /// Number of times this entity appears in memories
    #[serde(default)]
    pub mention_count: i32,

    /// Confidence score for this entity (0.0-1.0)
    /// Higher values indicate more certain entity identification
    #[serde(default = "default_confidence")]
    pub confidence: f32,

    /// Whether this entity is archived/inactive
    #[serde(default)]
    pub archived: bool,

    /// Optional metadata as key-value pairs
    #[serde(default, skip_serializing_if = "std::collections::HashMap::is_empty")]
    pub metadata: std::collections::HashMap<String, String>,

    /// Auto-generated summary from accumulated facts (Hindsight observation network)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub summary: Option<String>,

    /// When the summary was last generated/updated
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub summary_updated: Option<DateTime<Utc>>,
}

fn default_confidence() -> f32 { todo!() }

impl Entity {
    /// Create a new entity with the given name and type
    pub fn new(id: String, name: String, entity_type: EntityType) -> Self { todo!() }

    /// Add an alias for this entity
    pub fn add_alias(&mut self, alias: String) { todo!() }

    /// Check if a name matches this entity (including aliases)
    pub fn matches_name(&self, name: &str) -> bool { todo!() }

    /// Increment the mention count
    pub fn record_mention(&mut self) { todo!() }

    /// Generate a deterministic ID from the entity name and type
    pub fn generate_id(name: &str, entity_type: EntityType) -> String { todo!() }
}

impl Default for Entity {
    fn default() -> Self { todo!() }
}

/// A relationship (edge) between two entities
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Relationship {
    /// Unique identifier for this relationship
    pub id: String,

    /// Source entity ID
    pub source_id: String,

    /// Target entity ID
    pub target_id: String,

    /// Type of relationship
    #[serde(rename = "type")]
    pub relation_type: RelationType,

    /// When this relationship was established
    pub created: DateTime<Utc>,

    /// When this relationship became valid (for temporal graphs)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub valid_from: Option<DateTime<Utc>>,

    /// When this relationship stopped being valid (for temporal graphs)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub valid_until: Option<DateTime<Utc>>,

    /// Weight/strength of the relationship (0.0-1.0)
    #[serde(default = "default_weight")]
    pub weight: f32,

    /// Number of times this relationship was observed
    #[serde(default)]
    pub observation_count: i32,

    /// Optional description or context for the relationship
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,

    /// Entry IDs where this relationship was observed
    #[serde(default)]
    pub source_entries: Vec<String>,
}

fn default_weight() -> f32 { todo!() }

impl Relationship {
    /// Create a new relationship between two entities
    pub fn new(
        id: String,
        source_id: String,
        target_id: String,
        relation_type: RelationType,
    ) -> Self { todo!() }

    /// Check if this relationship is currently valid (within temporal bounds)
    pub fn is_valid(&self) -> bool { todo!() }

    /// Record an observation of this relationship
    pub fn record_observation(&mut self, entry_id: Option<&str>) { todo!() }

    /// Set temporal validity bounds
    pub fn set_validity(
        &mut self,
        valid_from: Option<DateTime<Utc>>,
        valid_until: Option<DateTime<Utc>>,
    ) { todo!() }

    /// Generate a deterministic ID from source, target, and type
    pub fn generate_id(source_id: &str, target_id: &str, relation_type: RelationType) -> String { todo!() }
}

impl Default for Relationship {
    fn default() -> Self { todo!() }
}

/// Link between an entity and a memory entry
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct EntityMention {
    /// Entity ID
    pub entity_id: String,

    /// Entry ID where the entity was mentioned
    pub entry_id: String,

    /// Position in the entry content (character offset)
    #[serde(default)]
    pub position: Option<usize>,

    /// The exact text that matched the entity
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub matched_text: Option<String>,

    /// Confidence of this mention (0.0-1.0)
    #[serde(default = "default_confidence")]
    pub confidence: f32,

    /// When this mention was recorded
    pub created: DateTime<Utc>,
}

impl EntityMention {
    /// Create a new entity mention
    pub fn new(entity_id: String, entry_id: String) -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::entity::*;



    #[test]
    fn test_entity_creation() {
        let entity = Entity::new(
            "ent-001".to_string(),
            "Alice".to_string(),
            EntityType::Person,
        );
        assert_eq!(entity.name, "Alice");
        assert_eq!(entity.entity_type, EntityType::Person);
        assert_eq!(entity.mention_count, 1);
    }

    #[test]
    fn test_entity_aliases() {
        let mut entity = Entity::new(
            "ent-001".to_string(),
            "CAS".to_string(),
            EntityType::Project,
        );
        entity.add_alias("Coding Agent System".to_string());
        entity.add_alias("cas-project".to_string());

        assert!(entity.matches_name("CAS"));
        assert!(entity.matches_name("cas"));
        assert!(entity.matches_name("Coding Agent System"));
        assert!(!entity.matches_name("unknown"));
    }

    #[test]
    fn test_entity_id_generation() {
        let id1 = Entity::generate_id("Alice", EntityType::Person);
        let id2 = Entity::generate_id("alice", EntityType::Person);
        let id3 = Entity::generate_id("Alice", EntityType::Project);

        // Same name (case-insensitive) and type should produce same ID
        assert_eq!(id1, id2);
        // Different type should produce different ID
        assert_ne!(id1, id3);
    }


    #[test]
    fn test_relationship_temporal_validity() {
        use chrono::Duration;

        let mut rel = Relationship::new(
            "rel-001".to_string(),
            "ent-001".to_string(),
            "ent-002".to_string(),
            RelationType::WorksOn,
        );

        // No bounds - always valid
        assert!(rel.is_valid());

        // Set to expired period
        let past = Utc::now() - Duration::days(10);
        let yesterday = Utc::now() - Duration::days(1);
        rel.set_validity(Some(past), Some(yesterday));
        assert!(!rel.is_valid());

        // Set to future period
        let tomorrow = Utc::now() + Duration::days(1);
        let future = Utc::now() + Duration::days(10);
        rel.set_validity(Some(tomorrow), Some(future));
        assert!(!rel.is_valid());

        // Set to current period
        let past = Utc::now() - Duration::days(1);
        let future = Utc::now() + Duration::days(1);
        rel.set_validity(Some(past), Some(future));
        assert!(rel.is_valid());
    }

}
