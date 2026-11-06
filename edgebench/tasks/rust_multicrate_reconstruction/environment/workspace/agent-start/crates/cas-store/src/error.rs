//! Error types for CAS store

use thiserror::Error;

#[derive(Error, Debug)]
pub enum StoreError {
    #[error("not initialized")]
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

    #[error("entity not found: {0}")]
    EntityNotFound(String),

    #[error("relationship not found: {0}")]
    RelationshipNotFound(String),

    #[error("entry already exists: {0}")]
    EntryExists(String),

    #[error("cyclic dependency would be created: {0} -> {1}")]
    CyclicDependency(String, String),

    #[error("circular dependency would be created: {0} -> {1}")]
    CircularDependency(String, String),

    #[error("database error: {0}")]
    Database(#[from] rusqlite::Error),

    #[error("io error: {0}")]
    Io(#[from] std::io::Error),

    #[error("yaml error: {0}")]
    Yaml(#[from] serde_yaml::Error),

    #[error("json error: {0}")]
    Json(#[from] serde_json::Error),

    #[error("parse error: {0}")]
    Parse(String),

    #[error("{0}")]
    Other(String),
}

pub type Result<T> = std::result::Result<T, StoreError>;
