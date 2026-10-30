use std::sync::Arc;

use crate::mcp::server::CasCore;
use crate::store::open_agent_store;

/// Run the MCP server with 13 meta-tools (11 CAS + 2 proxy)
pub async fn run_server() -> anyhow::Result<()> { todo!() }

/// Internal implementation for running the MCP server
async fn run_server_impl() -> anyhow::Result<()> { todo!() }

/// Release all tasks claimed by an agent on shutdown and unregister the agent
fn release_agent_tasks(cas_root: &std::path::Path, agent_id: &str) -> anyhow::Result<()> { todo!() }

/// Write the proxy tool catalog to `.cas/proxy_catalog.json` for SessionStart context injection.
#[cfg(feature = "mcp-proxy")]
pub async fn write_proxy_catalog_cache(
    cas_root: &std::path::Path,
    engine: &cmcp_core::ProxyEngine,
) { todo!() }
