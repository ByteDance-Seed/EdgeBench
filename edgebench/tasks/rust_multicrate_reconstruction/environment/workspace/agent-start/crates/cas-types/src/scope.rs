//! Scope type definitions for two-tier (global + project) architecture
//!
//! Scope determines where data is stored:
//! - Global: User-level data in ~/.config/cas/ (preferences, general learnings)
//! - Project: Project-level data in ./.cas/ (technical context, tasks)

use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::TypeError;

/// Storage scope for CAS data
///
/// Determines whether data is stored globally (user-level) or per-project.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum Scope {
    /// Global scope - stored in ~/.config/cas/
    /// Used for: user preferences, general learnings, global skills
    Global,

    /// Project scope - stored in ./.cas/
    /// Used for: technical context, tasks, project-specific rules
    #[default]
    Project,
}

impl Scope {
    /// Get the ID prefix for this scope
    pub fn id_prefix(&self) -> &'static str { todo!() }

    /// Parse scope from ID prefix
    pub fn from_id_prefix(prefix: &str) -> Option<Self> { todo!() }

    /// Extract scope from a prefixed ID (e.g., "g-2025-01-01-001" -> Global)
    pub fn from_id(id: &str) -> Option<Self> { todo!() }

    /// Check if this is global scope
    pub fn is_global(&self) -> bool { todo!() }

    /// Check if this is project scope
    pub fn is_project(&self) -> bool { todo!() }
}

impl fmt::Display for Scope {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for Scope {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Scope filter for queries that can target one or both scopes
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum ScopeFilter {
    /// Only global scope
    Global,
    /// Only project scope
    Project,
    /// Both scopes (default for search)
    #[default]
    All,
}

impl ScopeFilter {
    /// Check if this filter includes global scope
    pub fn includes_global(&self) -> bool { todo!() }

    /// Check if this filter includes project scope
    pub fn includes_project(&self) -> bool { todo!() }

    /// Convert to optional Scope (None means both)
    pub fn as_scope(&self) -> Option<Scope> { todo!() }
}

impl From<Scope> for ScopeFilter {
    fn from(scope: Scope) -> Self { todo!() }
}

impl FromStr for ScopeFilter {
    type Err = TypeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

impl fmt::Display for ScopeFilter {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::scope::*;

    #[test]
    fn test_scope_from_str() {
        assert_eq!(Scope::from_str("global").unwrap(), Scope::Global);
        assert_eq!(Scope::from_str("GLOBAL").unwrap(), Scope::Global);
        assert_eq!(Scope::from_str("g").unwrap(), Scope::Global);
        assert_eq!(Scope::from_str("project").unwrap(), Scope::Project);
        assert_eq!(Scope::from_str("local").unwrap(), Scope::Project);
        assert!(Scope::from_str("invalid").is_err());
    }


    #[test]
    fn test_scope_id_prefix() {
        assert_eq!(Scope::Global.id_prefix(), "g");
        assert_eq!(Scope::Project.id_prefix(), "p");
    }

    #[test]
    fn test_scope_from_id() {
        assert_eq!(Scope::from_id("g-2025-01-01-001"), Some(Scope::Global));
        assert_eq!(Scope::from_id("p-2025-01-01-001"), Some(Scope::Project));
        assert_eq!(Scope::from_id("p-cas-a1b2"), Some(Scope::Project));
        assert_eq!(Scope::from_id("g-rule-001"), Some(Scope::Global));
        // Legacy IDs without prefix
        assert_eq!(Scope::from_id("2025-01-01-001"), None);
        assert_eq!(Scope::from_id("cas-a1b2"), None);
    }

    #[test]
    fn test_scope_filter() {
        assert!(ScopeFilter::All.includes_global());
        assert!(ScopeFilter::All.includes_project());
        assert!(ScopeFilter::Global.includes_global());
        assert!(!ScopeFilter::Global.includes_project());
        assert!(!ScopeFilter::Project.includes_global());
        assert!(ScopeFilter::Project.includes_project());
    }


    #[test]
    fn test_default_scopes() {
        assert_eq!(Scope::default(), Scope::Project);
        assert_eq!(ScopeFilter::default(), ScopeFilter::All);
    }
}
