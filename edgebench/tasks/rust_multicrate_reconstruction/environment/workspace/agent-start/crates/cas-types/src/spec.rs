//! Spec type definitions
//!
//! Specs are structured documents that define requirements for epics, features,
//! APIs, components, and migrations.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;
use crate::scope::Scope;

/// Status of a spec in its lifecycle
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum SpecStatus {
    /// Initial draft, still being written
    #[default]
    Draft,
    /// Submitted for review
    UnderReview,
    /// Approved and ready for implementation
    Approved,
    /// Replaced by a newer version
    Superseded,
    /// Rejected, not to be implemented
    Rejected,
}

impl fmt::Display for SpecStatus {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for SpecStatus {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Type of spec document
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum SpecType {
    /// Large feature or project spanning multiple tasks
    #[default]
    Epic,
    /// Single feature or capability
    Feature,
    /// API design specification
    Api,
    /// Component or module design
    Component,
    /// Database or system migration
    Migration,
}

impl fmt::Display for SpecType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for SpecType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// A specification document for a feature, epic, API, etc.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Spec {
    /// Unique identifier (e.g., spec-a1b2c3d4)
    pub id: String,

    /// Storage scope (global or project)
    #[serde(default)]
    pub scope: Scope,

    /// Spec title
    pub title: String,

    /// Brief summary of what this spec covers
    #[serde(default)]
    pub summary: String,

    /// Goals and objectives
    #[serde(default)]
    pub goals: Vec<String>,

    /// What is in scope for this spec
    #[serde(default)]
    pub in_scope: Vec<String>,

    /// What is explicitly out of scope
    #[serde(default)]
    pub out_of_scope: Vec<String>,

    /// Target users or personas
    #[serde(default)]
    pub users: Vec<String>,

    /// Technical requirements and constraints
    #[serde(default)]
    pub technical_requirements: Vec<String>,

    /// Acceptance criteria for completion
    #[serde(default)]
    pub acceptance_criteria: Vec<String>,

    /// Design notes and decisions
    #[serde(default)]
    pub design_notes: String,

    /// Additional notes or context
    #[serde(default)]
    pub additional_notes: String,

    /// Type of spec
    #[serde(default)]
    pub spec_type: SpecType,

    /// Current status
    #[serde(default)]
    pub status: SpecStatus,

    /// Version number (starts at 1)
    #[serde(default = "default_version")]
    pub version: u32,

    /// ID of the previous version if this supersedes another spec
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub previous_version_id: Option<String>,

    /// Associated task ID (e.g., epic task)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub task_id: Option<String>,

    /// Source entry IDs this spec was derived from
    #[serde(default)]
    pub source_ids: Vec<String>,

    /// When the spec was created
    pub created_at: DateTime<Utc>,

    /// When the spec was last updated
    pub updated_at: DateTime<Utc>,

    /// When the spec was approved
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub approved_at: Option<DateTime<Utc>>,

    /// Who approved the spec (agent or user ID)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub approved_by: Option<String>,

    /// Team ID this spec belongs to
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub team_id: Option<String>,

    /// Tags for categorization
    #[serde(default)]
    pub tags: Vec<String>,
}

fn default_version() -> u32 { todo!() }

impl Spec {
    /// Create a new spec with the given ID and title (defaults to project scope)
    pub fn new(id: String, title: String) -> Self { todo!() }

    /// Create a new spec with explicit scope
    pub fn with_scope(id: String, title: String, scope: Scope) -> Self { todo!() }

    /// Create a new epic spec
    pub fn epic(id: String, title: String) -> Self { todo!() }

    /// Check if the spec is approved
    pub fn is_approved(&self) -> bool { todo!() }

    /// Check if the spec is active (not superseded or rejected)
    pub fn is_active(&self) -> bool { todo!() }

    /// Get a short preview of the summary
    pub fn preview(&self, max_len: usize) -> String { todo!() }
}

impl Default for Spec {
    fn default() -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::spec::*;

    #[test]
    fn test_spec_status_from_str() {
        assert_eq!(SpecStatus::from_str("draft").unwrap(), SpecStatus::Draft);
        assert_eq!(
            SpecStatus::from_str("under_review").unwrap(),
            SpecStatus::UnderReview
        );
        assert_eq!(
            SpecStatus::from_str("under-review").unwrap(),
            SpecStatus::UnderReview
        );
        assert_eq!(
            SpecStatus::from_str("approved").unwrap(),
            SpecStatus::Approved
        );
        assert_eq!(
            SpecStatus::from_str("superseded").unwrap(),
            SpecStatus::Superseded
        );
        assert_eq!(
            SpecStatus::from_str("rejected").unwrap(),
            SpecStatus::Rejected
        );
        assert!(SpecStatus::from_str("invalid").is_err());
    }

    #[test]
    fn test_spec_status_display() {
        assert_eq!(SpecStatus::Draft.to_string(), "draft");
        assert_eq!(SpecStatus::UnderReview.to_string(), "under_review");
        assert_eq!(SpecStatus::Approved.to_string(), "approved");
        assert_eq!(SpecStatus::Superseded.to_string(), "superseded");
        assert_eq!(SpecStatus::Rejected.to_string(), "rejected");
    }

    #[test]
    fn test_spec_type_from_str() {
        assert_eq!(SpecType::from_str("epic").unwrap(), SpecType::Epic);
        assert_eq!(SpecType::from_str("feature").unwrap(), SpecType::Feature);
        assert_eq!(SpecType::from_str("api").unwrap(), SpecType::Api);
        assert_eq!(
            SpecType::from_str("component").unwrap(),
            SpecType::Component
        );
        assert_eq!(
            SpecType::from_str("migration").unwrap(),
            SpecType::Migration
        );
        assert!(SpecType::from_str("invalid").is_err());
    }

    #[test]
    fn test_spec_type_display() {
        assert_eq!(SpecType::Epic.to_string(), "epic");
        assert_eq!(SpecType::Feature.to_string(), "feature");
        assert_eq!(SpecType::Api.to_string(), "api");
        assert_eq!(SpecType::Component.to_string(), "component");
        assert_eq!(SpecType::Migration.to_string(), "migration");
    }

    #[test]
    fn test_spec_new() {
        let spec = Spec::new("spec-001".to_string(), "Test Spec".to_string());
        assert_eq!(spec.id, "spec-001");
        assert_eq!(spec.title, "Test Spec");
        assert_eq!(spec.scope, Scope::Project);
        assert_eq!(spec.status, SpecStatus::Draft);
        assert_eq!(spec.version, 1);
    }

    #[test]
    fn test_spec_epic() {
        let spec = Spec::epic("spec-002".to_string(), "Epic Spec".to_string());
        assert_eq!(spec.spec_type, SpecType::Epic);
        assert_eq!(spec.status, SpecStatus::Draft);
    }

    #[test]
    fn test_is_approved() {
        let mut spec = Spec::new("spec-001".to_string(), "test".to_string());
        assert!(!spec.is_approved());

        spec.status = SpecStatus::Approved;
        assert!(spec.is_approved());
    }

    #[test]
    fn test_is_active() {
        let mut spec = Spec::new("spec-001".to_string(), "test".to_string());
        assert!(spec.is_active());

        spec.status = SpecStatus::UnderReview;
        assert!(spec.is_active());

        spec.status = SpecStatus::Approved;
        assert!(spec.is_active());

        spec.status = SpecStatus::Superseded;
        assert!(!spec.is_active());

        spec.status = SpecStatus::Rejected;
        assert!(!spec.is_active());
    }

}
