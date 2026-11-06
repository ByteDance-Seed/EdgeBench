//! MCP CLI commands for managing upstream MCP server configurations.
//!
//! Mirrors cmcp's CLI interface so users can copy-paste `claude mcp add` or
//! `codex mcp add` commands by prepending `cas mcp`.
//!
//! Config is stored in `.cas/proxy.toml` (project-scoped). Servers are exposed
//! via `mcp_search` and `mcp_execute` tools in `cas serve`.

use std::path::Path;

use anyhow::Result;
use clap::Subcommand;

#[cfg(feature = "mcp-proxy")]
use std::collections::HashMap;
#[cfg(feature = "mcp-proxy")]
use std::io::{self, Write};
#[cfg(feature = "mcp-proxy")]
use std::path::PathBuf;
#[cfg(feature = "mcp-proxy")]
use anyhow::Context;
#[cfg(feature = "mcp-proxy")]
use cmcp_core::config::{Config, ServerConfig};
#[cfg(feature = "mcp-proxy")]
use crate::ui::components::{Formatter, Renderable, StatusLine};
#[cfg(feature = "mcp-proxy")]
use crate::ui::theme::ActiveTheme;
#[cfg(not(feature = "mcp-proxy"))]
use anyhow::bail;

#[derive(Subcommand)]
pub enum McpCommands {
    /// Add an MCP server (drop-in replacement for `claude mcp add`).
    ///
    /// Copy any `claude mcp add` command and replace `claude mcp` with `cas mcp`:
    ///
    ///   cas mcp add chrome-devtools --scope user npx chrome-devtools-mcp@latest
    ///   cas mcp add -e API_KEY=xxx my-server -- npx my-mcp-server --some-flag
    ///   cas mcp add --transport http sentry https://mcp.sentry.dev/mcp
    ///   cas mcp add -H "Authorization: Bearer ..." corridor https://app.corridor.dev/api/mcp
    ///   cas mcp add canva https://mcp.canva.com/mcp
    Add {
        /// Raw arguments — parsed identically to `claude mcp add`.
        /// Supports: -s/--scope, -t/--transport, -e/--env, -H/--header, --auth
        #[arg(trailing_var_arg = true, allow_hyphen_values = true, required = true)]
        raw: Vec<String>,
    },

    /// Remove an MCP server.
    Remove {
        /// Server name to remove
        name: String,

        /// Scope: "local" (default), "user", or "project".
        #[arg(short, long, default_value = "local")]
        scope: String,
    },

    /// List configured MCP servers.
    #[command(alias = "ls")]
    List {
        /// Only show server names (don't connect to fetch tools)
        #[arg(short, long)]
        short: bool,
    },

    /// Import MCP servers from Claude or Codex config.
    ///
    /// Examples:
    ///   cas mcp import                    # import from all sources
    ///   cas mcp import --from claude      # only from Claude
    ///   cas mcp import --from codex       # only from Codex
    ///   cas mcp import --dry-run          # preview without writing
    ///   cas mcp import --force            # overwrite existing servers
    Import {
        /// Source to import from: "claude", "codex", or omit for all.
        #[arg(short, long)]
        from: Option<String>,

        /// Preview what would be imported without writing.
        #[arg(short, long)]
        dry_run: bool,

        /// Overwrite existing servers with the same name.
        #[arg(long)]
        force: bool,
    },
}

#[cfg(feature = "mcp-proxy")]
pub fn execute(cmd: &McpCommands, cli: &super::Cli, cas_root: &Path) -> Result<()> { todo!() }

#[cfg(not(feature = "mcp-proxy"))]
pub fn execute(_cmd: &McpCommands, _cli: &super::Cli, _cas_root: &Path) -> Result<()> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn resolve_scope_path(scope: &str, cas_root: &Path) -> Result<PathBuf> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn project_config_path(cas_root: &Path) -> PathBuf { todo!() }

#[cfg(feature = "mcp-proxy")]
fn load_config_for_scope(scope: &str, cas_root: &Path) -> Result<(Config, PathBuf)> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn load_config(cas_root: &Path) -> Result<Config> { todo!() }

// ── Add ──────────────────────────────────────────────────────────────

/// Manually parse raw args from `cas mcp add`, matching `claude mcp add` syntax.
///
/// Supports all Claude flags: -s/--scope, -t/--transport, -e/--env, -H/--header
/// Plus CAS extras: -a/--auth
/// Ignores Claude-only flags: --callback-port, --client-id, --client-secret
///
/// After flags, first positional = server name, rest = url/command + args.
/// Everything after `--` is passed literally to the subprocess.
#[cfg(feature = "mcp-proxy")]
fn execute_add(raw: &[String], cli: &super::Cli, cas_root: &Path) -> Result<()> { todo!() }

/// Parse "Key: Value" or "Key=Value" header strings.
#[cfg(feature = "mcp-proxy")]
fn parse_headers(raw: &[String]) -> HashMap<String, String> { todo!() }

/// Parse "KEY=VALUE" env strings.
#[cfg(feature = "mcp-proxy")]
fn parse_envs(raw: &[String]) -> HashMap<String, String> { todo!() }

// ── Remove ───────────────────────────────────────────────────────────

#[cfg(feature = "mcp-proxy")]
fn execute_remove(name: &str, scope: &str, cli: &super::Cli, cas_root: &Path) -> Result<()> { todo!() }

// ── List ─────────────────────────────────────────────────────────────

#[cfg(feature = "mcp-proxy")]
fn execute_list(short: bool, cli: &super::Cli, cas_root: &Path) -> Result<()> { todo!() }

// ── Import ───────────────────────────────────────────────────────────

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[cfg(feature = "mcp-proxy")]
enum ImportSource {
    Claude,
    Codex,
}

#[cfg(feature = "mcp-proxy")]
impl std::fmt::Display for ImportSource {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

#[cfg(feature = "mcp-proxy")]
struct ImportedServer {
    name: String,
    config: ServerConfig,
    source: ImportSource,
}

#[cfg(feature = "mcp-proxy")]
fn execute_import(
    from: Option<&str>,
    dry_run: bool,
    force: bool,
    cli: &super::Cli,
    cas_root: &Path,
) -> Result<()> { todo!() }

// ── Import discovery ─────────────────────────────────────────────────

#[cfg(feature = "mcp-proxy")]
fn discover_servers(source_filter: Option<ImportSource>) -> Result<Vec<ImportedServer>> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn home_dir() -> Result<PathBuf> { todo!() }

// ── Claude discovery ─────────────────────────────────────────────────

#[cfg(feature = "mcp-proxy")]
fn discover_claude() -> Result<Vec<ImportedServer>> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn parse_claude_json(path: &Path) -> Result<Vec<ImportedServer>> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn parse_claude_server(name: &str, value: &serde_json::Value) -> Result<Option<ImportedServer>> { todo!() }

// ── Codex discovery ──────────────────────────────────────────────────

#[cfg(feature = "mcp-proxy")]
fn discover_codex() -> Result<Vec<ImportedServer>> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn parse_codex_toml(path: &Path) -> Result<Vec<ImportedServer>> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn parse_codex_server(name: &str, value: &toml::Value) -> Result<Option<ImportedServer>> { todo!() }

// ── Helpers ──────────────────────────────────────────────────────────

#[cfg(feature = "mcp-proxy")]
fn parse_json_string_map(value: Option<&serde_json::Value>) -> HashMap<String, String> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn parse_toml_string_map(value: Option<&toml::Value>) -> HashMap<String, String> { todo!() }

#[cfg(feature = "mcp-proxy")]
fn extract_auth_header(
    mut headers: HashMap<String, String>,
) -> (Option<String>, HashMap<String, String>) { todo!() }
