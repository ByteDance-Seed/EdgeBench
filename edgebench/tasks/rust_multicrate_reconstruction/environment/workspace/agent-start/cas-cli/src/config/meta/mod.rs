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

mod registry;
mod seed;
#[cfg(test)]
mod tests;
mod types;

pub use registry::{ConfigRegistry, registry};
pub use types::{ConfigMeta, ConfigType, Constraint};
