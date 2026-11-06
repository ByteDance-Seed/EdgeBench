//! MCP Server for CAS
//!
//! Provides MCP (Model Context Protocol) server exposing CAS functionality.
//!
//! # Architecture
//!
//! This crate provides the MCP protocol layer for CAS:
//!
//! - **Request Types**: Schema definitions for the 7 consolidated tools
//! - **Daemon Types**: Activity tracking and daemon status
//! - **Error Types**: MCP-specific error handling
//!
//! The actual tool implementations remain in `cas-cli` since they depend
//! on many CLI-specific modules. This crate provides the shared types
//! and interfaces.
//!
//! # Modules
//!
//! - `types`: Request/response types for MCP tools
//! - `daemon`: Embedded daemon types for background maintenance
//! - `error`: MCP-specific error types

pub mod daemon;
pub mod error;
pub mod types;

// Re-exports
pub use daemon::{ActivityTracker, EmbeddedDaemonConfig, EmbeddedDaemonStatus, MaintenanceResult};
pub use error::McpError;
pub use types::{
    AgentRequest, CoordinationRequest, ExecuteRequest, FactoryRequest, MemoryRequest,
    PatternRequest, RuleRequest, SearchContextRequest, SkillRequest, SpecRequest, SystemRequest,
    TaskRequest, TeamRequest, VerificationRequest,
};
