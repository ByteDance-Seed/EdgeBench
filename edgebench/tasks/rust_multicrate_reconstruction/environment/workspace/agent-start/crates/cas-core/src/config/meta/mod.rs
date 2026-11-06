//! Configuration metadata registry
//!
//! Provides comprehensive metadata for all CAS configuration options including:
//! - Descriptions and documentation
//! - Types and validation constraints
//! - Default values
//! - Section organization
//!
//! This enables rich CLI interfaces like `cas config describe`, validation,
//! shell completion, and interactive editors.

use std::collections::HashMap;

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
}

impl ConfigMeta {
    /// Validate a value against this config's constraints
    pub fn validate(&self, value: &str) -> Result<(), String> { todo!() }

    /// Format value for display
    pub fn format_value(&self, value: &str) -> String { todo!() }

    /// Check if value differs from default
    pub fn is_modified(&self, value: &str) -> bool { todo!() }
}

/// Registry of all configuration options
pub struct ConfigRegistry {
    /// All config metadata indexed by key
    configs: HashMap<&'static str, ConfigMeta>,
    /// Config keys organized by section
    sections: HashMap<&'static str, Vec<&'static str>>,
    /// Section descriptions
    section_descriptions: HashMap<&'static str, &'static str>,
}


mod seed;

impl ConfigRegistry {
    /// Create the complete config registry with all options
    pub fn new() -> Self { todo!() }

    /// Register a config option
    fn register(&mut self, meta: ConfigMeta) { todo!() }

    /// Get metadata for a config key
    pub fn get(&self, key: &str) -> Option<&ConfigMeta> { todo!() }

    /// Get all config keys
    pub fn all_keys(&self) -> Vec<&'static str> { todo!() }

    /// Get keys for a section
    pub fn section_keys(&self, section: &str) -> Vec<&'static str> { todo!() }

    /// Get all section names
    pub fn sections(&self) -> Vec<&'static str> { todo!() }

    /// Get section description
    pub fn section_description(&self, section: &str) -> Option<&'static str> { todo!() }

    /// Get all configs in a section
    pub fn configs_in_section(&self, section: &str) -> Vec<&ConfigMeta> { todo!() }

    /// Search configs by keyword
    pub fn search(&self, query: &str) -> Vec<&ConfigMeta> { todo!() }

    /// Get count of all config options
    pub fn count(&self) -> usize { todo!() }

    /// Get only non-advanced configs
    pub fn basic_configs(&self) -> Vec<&ConfigMeta> { todo!() }

    /// Get only advanced configs
    pub fn advanced_configs(&self) -> Vec<&ConfigMeta> { todo!() }

    /// Validate a value for a key
    pub fn validate(&self, key: &str, value: &str) -> Result<(), String> { todo!() }
}

impl Default for ConfigRegistry {
    fn default() -> Self { todo!() }
}

/// Global config registry singleton
static REGISTRY: std::sync::OnceLock<ConfigRegistry> = std::sync::OnceLock::new();

/// Get the global config registry
pub fn registry() -> &'static ConfigRegistry { todo!() }

#[cfg(test)]
mod tests;
