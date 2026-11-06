//! Error types for CAS
//!
//! Provides detailed error messages with suggestions for resolution.

// Dead code check enabled - all variants should be used

use thiserror::Error;

#[derive(Error, Debug)]
pub enum CasError {
    #[error("CAS not initialized")]
    NotInitialized,

    #[error("not found: {0}")]
    NotFound(String),

    #[error("entry not found: {0}")]
    EntryNotFound(String),

    #[error("rule not found: {0}")]
    RuleNotFound(String),

    #[error("task not found: {0}")]
    TaskNotFound(String),

    #[error("skill not found: {0}")]
    SkillNotFound(String),

    #[error("entry already exists: {0}")]
    EntryExists(String),

    #[error("cyclic dependency would be created: {0} -> {1}")]
    CyclicDependency(String, String),

    #[error("entity not found: {0}")]
    EntityNotFound(String),

    #[error("relationship not found: {0}")]
    RelationshipNotFound(String),

    #[error("invalid entry type: {0}")]
    InvalidEntryType(String),

    #[error("invalid rule status: {0}")]
    InvalidRuleStatus(String),

    #[error("invalid task status: {0}")]
    InvalidTaskStatus(String),

    #[error("invalid rule category: {0}")]
    InvalidRuleCategory(String),

    #[error("invalid transaction state: {0}")]
    InvalidState(String),

    #[error("rollback failed: {0}")]
    RollbackFailed(String),

    #[error("similar entry exists: {id} (similarity: {similarity:.0}%)")]
    SimilarEntryExists { id: String, similarity: f64 },

    #[error("circular dependency would be created: {0} -> {1}")]
    CircularDependency(String, String),

    #[error("database error: {0}")]
    Database(#[from] rusqlite::Error),

    #[error("search error: {0}")]
    Search(#[from] tantivy::TantivyError),

    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    #[error("yaml error: {0}")]
    Yaml(#[from] serde_yaml::Error),

    #[error("json error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("type error: {0}")]
    Type(#[from] cas_types::TypeError),

    #[error("store error: {0}")]
    StoreErr(#[from] cas_store::StoreError),

    #[error("parse error: {0}")]
    Parse(String),

    #[error("embedding error: {0}")]
    Embedding(String),

    #[error("vector store error: {0}")]
    VectorStore(String),

    #[error("model loading error: {0}")]
    ModelLoad(String),

    #[error("rerank error: {0}")]
    Rerank(String),

    #[error(
        "embedding dimension mismatch: stored dimension is {stored_dimension} (model: {stored_model}), but configured model '{configured_model}' has dimension {configured_dimension}"
    )]
    EmbeddingMigrationNeeded {
        stored_model: String,
        stored_dimension: usize,
        configured_model: String,
        configured_dimension: usize,
    },

    #[error("migration failed: {name} - {reason}")]
    MigrationFailed { name: String, reason: String },

    #[error("database schema outdated: v{current} -> v{required}. Run 'cas update --schema-only'")]
    SchemaOutdated { current: u32, required: u32 },

    #[error("{0}")]
    Other(String),

    #[error("core error: {0}")]
    Core(#[from] cas_core::CoreError),
}

impl CasError {
    /// Get a helpful suggestion for how to resolve this error
    pub fn suggestion(&self) -> Option<&'static str> { todo!() }

    /// Format the error with suggestion for display
    pub fn with_suggestion(&self) -> String { todo!() }
}

pub type Result<T> = std::result::Result<T, CasError>;

/// Backwards compatibility alias
pub type MemError = CasError;
