//! Entity-aware search for knowledge graph queries
//!
//! Enables queries like:
//! - "memories about project X"
//! - "what did person Y work on"
//! - "entries mentioning tool Z"
//!
//! Combines entity lookup with traditional text search.

use std::sync::Arc;

/// Maximum number of related entities to return in search results.
/// Prevents memory issues when entities have many relationships.
const MAX_RELATED_ENTITIES: usize = 50;

use crate::error::CasError;
use crate::store::EntityStore;
use crate::types::{Entity, EntityType};

/// Parsed entity query
#[derive(Debug, Clone)]
pub struct EntityQuery {
    /// Entity name or pattern to search for
    pub entity_name: String,

    /// Optional entity type filter
    pub entity_type: Option<EntityType>,

    /// Query intent (about, by, uses, etc.)
    pub intent: QueryIntent,

    /// Remaining text query to combine with entity search
    pub text_query: Option<String>,
}

/// Intent of the entity query
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum QueryIntent {
    /// Find entries about/mentioning an entity
    About,
    /// Find entries created by a person
    By,
    /// Find entities that use something
    Uses,
    /// Find entities related to something
    RelatedTo,
    /// Find entities working on something
    WorksOn,
    /// General entity mention
    Mentions,
}

impl EntityQuery {
    /// Parse a query string for entity references
    ///
    /// Supported formats:
    /// - `about:entity_name` - entries about the entity
    /// - `by:person_name` - entries by person
    /// - `uses:tool_name` - entities using tool
    /// - `@entity_name` - shorthand for about
    /// - `entity:type:name` - explicit type filter
    ///
    /// Returns None if no entity query pattern is found.
    pub fn parse(query: &str) -> Option<Self> { todo!() }

    fn with_intent(name: &str, intent: QueryIntent) -> Self { todo!() }

    /// Check if this query has an entity component
    pub fn has_entity(&self) -> bool { todo!() }
}

/// Result of an entity-aware search
#[derive(Debug, Clone)]
pub struct EntitySearchResult {
    /// Matched entity (if found)
    pub entity: Option<Entity>,

    /// Entry IDs that mention this entity
    pub entry_ids: Vec<String>,

    /// Related entities (via relationships)
    pub related_entities: Vec<Entity>,

    /// Confidence of the entity match
    pub confidence: f32,
}

/// Entity-aware search engine
pub struct EntitySearch {
    entity_store: Arc<dyn EntityStore>,
}

impl EntitySearch {
    /// Create a new entity search engine
    pub fn new(entity_store: Arc<dyn EntityStore>) -> Self { todo!() }

    /// Search for entries related to an entity
    pub fn search(
        &self,
        query: &EntityQuery,
        limit: usize,
    ) -> Result<EntitySearchResult, CasError> { todo!() }

    /// Get entries for a specific entity ID
    pub fn get_entity_entries(
        &self,
        entity_id: &str,
        limit: usize,
    ) -> Result<Vec<String>, CasError> { todo!() }

    /// Find entities matching a pattern
    pub fn find_entities(
        &self,
        query: &str,
        entity_type: Option<EntityType>,
    ) -> Result<Vec<Entity>, CasError> { todo!() }
}

/// Combine entity search with text search results
pub fn combine_results(
    entity_result: &EntitySearchResult,
    text_result_ids: &[String],
    entity_weight: f32,
) -> Vec<(String, f32)> { todo!() }

#[cfg(test)]
mod tests {
    use crate::hybrid_search::entity_search::*;


    #[test]
    fn test_parse_by_query() {
        let query = EntityQuery::parse("by:Alice").unwrap();
        assert_eq!(query.entity_name, "Alice");
        assert_eq!(query.entity_type, Some(EntityType::Person));
        assert_eq!(query.intent, QueryIntent::By);
    }

    #[test]
    fn test_parse_uses_query() {
        let query = EntityQuery::parse("uses:Rust").unwrap();
        assert_eq!(query.entity_name, "Rust");
        assert_eq!(query.entity_type, Some(EntityType::Tool));
        assert_eq!(query.intent, QueryIntent::Uses);
    }

    #[test]
    fn test_parse_at_shorthand() {
        let query = EntityQuery::parse("@SQLite").unwrap();
        assert_eq!(query.entity_name, "SQLite");
        assert_eq!(query.intent, QueryIntent::Mentions);
    }



    #[test]
    fn test_parse_natural_about() {
        let query = EntityQuery::parse("memories about CAS").unwrap();
        assert_eq!(query.entity_name, "CAS");
        assert_eq!(query.intent, QueryIntent::About);
    }

    #[test]
    fn test_parse_natural_works_on() {
        let query = EntityQuery::parse("what did Alice work on").unwrap();
        assert_eq!(query.entity_name, "Alice");
        assert_eq!(query.intent, QueryIntent::WorksOn);
    }

    #[test]
    fn test_parse_mentioning() {
        let query = EntityQuery::parse("entries mentioning Rust").unwrap();
        assert_eq!(query.entity_name, "Rust");
        assert_eq!(query.intent, QueryIntent::Mentions);
    }

    #[test]
    fn test_no_entity_query() {
        let result = EntityQuery::parse("regular search query");
        assert!(result.is_none());
    }

}
