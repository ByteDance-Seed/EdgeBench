//! MCP (Model Context Protocol) support.
//!
//! This module provides integration with MCP for custom tool support.
//! Tools are exposed via an MCP server that the Claude CLI can connect to.

mod bridge;
mod config;

pub use bridge::McpBridge;
pub use config::{generate_mcp_config, generate_mcp_config_with_name, write_temp_config};
