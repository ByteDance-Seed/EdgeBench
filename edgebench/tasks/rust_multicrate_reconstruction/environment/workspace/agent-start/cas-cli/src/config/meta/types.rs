/// Type of configuration value
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ConfigType {
    /// Boolean (true/false)
    Bool,
    /// Integer number
    Int,
    /// String value
    String,
    /// Comma-separated list of strings
    StringList,
}

impl ConfigType {
    /// Get a human-readable type name
    pub fn name(&self) -> &'static str { todo!() }

    /// Get example values for this type
    pub fn examples(&self) -> Vec<&'static str> { todo!() }
}

/// Validation constraints for a config value
#[derive(Debug, Clone)]
pub enum Constraint {
    /// No constraints
    None,
    /// Minimum integer value
    Min(i64),
    /// Maximum integer value
    Max(i64),
    /// Range (inclusive)
    Range(i64, i64),
    /// Must be one of these values
    OneOf(Vec<String>),
    /// Must not be empty
    NotEmpty,
    /// Must be a valid path
    ValidPath,
}

/// Metadata for a single configuration option
#[derive(Debug, Clone)]
pub struct ConfigMeta {
    /// The full key path (e.g., "hooks.token_budget")
    pub key: &'static str,
    /// Section this belongs to
    pub section: &'static str,
    /// Human-readable display name
    pub name: &'static str,
    /// Detailed description
    pub description: &'static str,
    /// Value type
    pub value_type: ConfigType,
    /// Default value as string
    pub default: &'static str,
    /// Validation constraint
    pub constraint: Constraint,
    /// Whether this is an advanced option (hidden by default in simple lists)
    pub advanced: bool,
    /// Feature flag required (if any)
    pub requires_feature: Option<&'static str>,
    /// Keywords for semantic search (synonyms, related terms)
    pub keywords: &'static [&'static str],
    /// Common use cases when you'd change this setting
    pub use_cases: &'static [&'static str],
}

impl ConfigMeta {
    /// Validate a value against this config's constraints
    pub fn validate(&self, value: &str) -> Result<(), String> { todo!() }

    /// Format value for display
    pub fn format_value(&self, value: &str) -> String { todo!() }

    /// Check if value differs from default
    pub fn is_modified(&self, value: &str) -> bool { todo!() }
}
