//! Error types for CAS types
//!
//! Minimal error type for type parsing, without heavy dependencies.

use thiserror::Error;

#[derive(Error, Debug)]
pub enum TypeError {
    #[error("invalid entry type: {0}")]
    InvalidEntryType(String),

    #[error("invalid rule status: {0}")]
    InvalidRuleStatus(String),

    #[error("invalid rule category: {0}")]
    InvalidRuleCategory(String),

    #[error("invalid task status: {0}")]
    InvalidTaskStatus(String),

    #[error("invalid spec status: {0}")]
    InvalidSpecStatus(String),

    #[error("invalid spec type: {0}")]
    InvalidSpecType(String),

    #[error("parse error: {0}")]
    Parse(String),
}

pub type Result<T> = std::result::Result<T, TypeError>;
