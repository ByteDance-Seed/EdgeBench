//! Configuration management for CAS
//!
//! This module provides core configuration types that are CLI-agnostic.
//! UI-specific configuration (like themes) is handled by the CLI layer.

pub mod meta;

pub use meta::{registry, ConfigMeta, ConfigRegistry, Constraint};
pub use types::*;
pub use types_core::*;

mod get;
mod io;
mod set;
#[cfg(test)]
mod tests;
mod types;
mod types_core;
