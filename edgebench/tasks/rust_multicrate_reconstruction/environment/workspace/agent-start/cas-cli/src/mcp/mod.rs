//! MCP Server for CAS
//!
//! Comprehensive MCP (Model Context Protocol) server exposing all CAS functionality.
//!
//! # Features
//!
//! - **55 Tools**: Memory, tasks, rules, skills, search, and system operations
//! - **9 Prompts**: Reusable prompt templates for common workflows
//! - **Resources**: Read-only access to all CAS data via cas:// URIs
//! - **Embedded Daemon**: Background maintenance during idle periods
//!
//! # Usage
//!
//! Run the MCP server:
//! ```bash
//! cas serve
//! ```
//!
//! Configure in Claude Code settings.json:
//! ```json
//! {
//!   "mcpServers": {
//!     "cas": {
//!       "command": "cas",
//!       "args": ["serve"]
//!     }
//!   }
//! }
//! ```
//!
//! # Embedded Daemon
//!
//! The MCP server includes an embedded daemon that runs maintenance tasks
//! during idle periods:
//!
//! - **Embedding Generation**: Runs every 2 minutes
//! - **Full Maintenance**: Runs every 30 minutes when idle for 1+ minute
//!   - Process pending observations
//!   - Apply memory decay
//!   - Generate embeddings for new entries
//!
//! Use `cas_maintenance_status` to check daemon state and
//! `cas_maintenance_run` to trigger immediate maintenance.

mod daemon;
mod server;
pub mod socket;
pub mod tools;

pub use server::CasCore;
pub use server::run_server;
pub use tools::CasService;
