//! Entry type definitions

// Dead code check enabled - all items used

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;
use crate::scope::Scope;

/// Type of memory entry
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum EntryType {
    /// A learned fact or pattern
    #[default]
    Learning,
    /// A user preference
    Preference,
    /// Contextual information
    Context,
    /// Auto-captured observation from hooks
    Observation,
}

/// Epistemic type - distinguishes facts from opinions (Hindsight-inspired)
///
/// This enables the system to track not just what the agent knows, but
/// how certain it is about that knowledge and whether it's objective or subjective.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum BeliefType {
    /// Objective fact - externally verifiable information
    #[default]
    Fact,
    /// Subjective opinion - judgment formed by the agent
    Opinion,
    /// Hypothesis - tentative belief pending verification
    Hypothesis,
}

impl fmt::Display for BeliefType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for BeliefType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Subtype for observations - categorizes what kind of observation it is
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum ObservationType {
    /// General observation (default)
    #[default]
    General,
    /// Architectural or design decision made
    Decision,
    /// Bug identified and/or fixed
    Bugfix,
    /// New feature implemented
    Feature,
    /// Code restructuring
    Refactor,
    /// Learned fact about the codebase
    Discovery,
    /// File or code modification
    Change,
    /// User preference expressed
    Preference,
    /// Code pattern identified
    Pattern,
    /// Test added or modified
    Test,
    /// Configuration change
    Config,
}

impl fmt::Display for ObservationType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for ObservationType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

impl fmt::Display for EntryType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for EntryType {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Memory tier classification (MemGPT-inspired hierarchy)
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum MemoryTier {
    /// In-context blocks - always injected into every session
    /// Use for critical, pinned memories that should always be available
    #[serde(alias = "in_context", alias = "incontext")]
    InContext,
    /// Active working memory - frequently accessed, full content available
    #[default]
    Working,
    /// Cold storage - less frequently accessed, may be compressed
    Cold,
    /// Archive - rarely accessed, compressed, may require restoration
    Archive,
}

impl MemoryTier {
    /// Check if this tier means the entry is always injected
    pub fn is_always_injected(&self) -> bool { todo!() }

    /// Check if this tier is considered active (searchable without restoration)
    pub fn is_active(&self) -> bool { todo!() }
}

impl fmt::Display for MemoryTier {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for MemoryTier {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// A memory entry stored by cas
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Entry {
    /// Unique identifier in scope-YYYY-MM-DD-NNN format (e.g., g-2025-01-01-001 or p-2025-01-01-001)
    pub id: String,

    /// Storage scope (global or project)
    /// Global: user preferences, general learnings stored in ~/.config/cas/
    /// Project: technical context, codebase-specific info stored in ./.cas/
    #[serde(default)]
    pub scope: Scope,

    /// Type of entry
    #[serde(rename = "type", default)]
    pub entry_type: EntryType,

    /// Observation subtype (only used when entry_type is Observation)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub observation_type: Option<ObservationType>,

    /// Optional categorization tags
    #[serde(default)]
    pub tags: Vec<String>,

    /// When the entry was created
    pub created: DateTime<Utc>,

    /// The memory content (may be compressed summary)
    pub content: String,

    /// Raw uncompressed content (stored when content is compressed)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub raw_content: Option<String>,

    /// Whether the content has been compressed
    #[serde(default)]
    pub compressed: bool,

    /// Memory tier classification
    #[serde(default)]
    pub memory_tier: MemoryTier,

    /// Optional short description
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub title: Option<String>,

    /// Number of times marked helpful
    #[serde(default)]
    pub helpful_count: i32,

    /// Number of times marked harmful
    #[serde(default)]
    pub harmful_count: i32,

    /// Last time the entry was accessed
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub last_accessed: Option<DateTime<Utc>>,

    /// Whether the entry is archived
    #[serde(default)]
    pub archived: bool,

    /// Session ID this entry was captured in (for observations)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub session_id: Option<String>,

    /// Source tool that generated this observation
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub source_tool: Option<String>,

    /// Whether this observation needs AI extraction later
    #[serde(default)]
    pub pending_extraction: bool,

    /// Whether this entry needs embedding generation
    /// New entries start with true, set to false after embedding is generated
    #[serde(default = "default_true")]
    pub pending_embedding: bool,

    /// Memory stability score (0.0-1.0) - higher = more resistant to decay
    /// Based on forgetting curve: reinforced by access and positive feedback
    #[serde(default = "default_stability")]
    pub stability: f32,

    /// Number of times this entry was accessed/retrieved
    #[serde(default)]
    pub access_count: i32,

    /// User-defined importance/priority score (0.0-1.0)
    /// Higher values boost search ranking. Can be set with `cas priority <id> <score>`
    #[serde(default = "default_importance")]
    pub importance: f32,

    /// When this fact became valid (optional temporal bound)
    /// If None, assumes fact has always been valid
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub valid_from: Option<DateTime<Utc>>,

    /// When this fact stops being valid (optional temporal bound)
    /// If None, assumes fact is still valid indefinitely
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub valid_until: Option<DateTime<Utc>>,

    /// When this entry should be reviewed next (for spaced repetition)
    /// Calculated based on stability and access patterns
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub review_after: Option<DateTime<Utc>>,

    /// When this entry was last reviewed for rule/skill promotion
    /// Used by the learning review hook to track which entries have been analyzed
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub last_reviewed: Option<DateTime<Utc>>,

    /// Domain knowledge area (e.g., "payments", "auth", "api", "database")
    /// Used to surface relevant context when working in specific areas
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub domain: Option<String>,

    // =========================================================================
    // Hindsight-inspired epistemic fields
    // =========================================================================
    /// Epistemic type - distinguishes facts from opinions/hypotheses
    /// Enables the system to track certainty about knowledge
    #[serde(default)]
    pub belief_type: BeliefType,

    /// Confidence score (0.0-1.0) for opinions and hypotheses.
    /// Represents how strongly the agent believes this entry:
    /// - 1.0 = very strong conviction
    /// - 0.5 = moderate belief
    /// - 0.0 = weak, easily revisable
    ///
    /// For facts, this is typically 1.0.
    #[serde(default = "default_confidence")]
    pub confidence: f32,

    /// Git branch this entry is scoped to (None = visible from all branches)
    /// Used for worktree isolation - entries created in a worktree can be scoped
    /// to that branch and optionally promoted to global on merge.
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub branch: Option<String>,

    /// Team ID this entry belongs to (None = personal/not shared with team)
    /// Used for team sync - entries with team_id sync to team repository
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub team_id: Option<String>,
}

pub(crate) fn default_importance() -> f32 { todo!() }

pub(crate) fn default_stability() -> f32 { todo!() }

pub(crate) fn default_confidence() -> f32 { todo!() }

fn default_true() -> bool { todo!() }

mod behavior;

#[cfg(test)]
#[path = "entry_tests/tests.rs"]
mod tests;
