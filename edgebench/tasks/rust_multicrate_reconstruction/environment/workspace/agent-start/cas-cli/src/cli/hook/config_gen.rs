use std::path::Path;

use toml::map::Map;

/// Get the CAS hooks configuration JSON
///
/// Note: Claude Code 2.1.0+ supports `once: true` for hooks that should only run once
/// per session, even if resumed. CAS hooks intentionally do NOT use `once: true` because:
/// - SessionStart should inject context on every session start/resume
/// - PostToolUse and Stop should run on every matching event
///
/// Users can manually add `"once": true` to specific hooks if desired.
pub(crate) fn get_cas_hooks_config(config: &crate::config::HookConfig) -> serde_json::Value { todo!() }

/// Get suggested Bash permission patterns for CAS commands
///
/// Claude Code 2.1.0+ supports wildcard patterns like `Bash(cas :*)` to allow
/// all CAS CLI commands without individual prompts.
pub fn get_cas_bash_permissions() -> Vec<String> { todo!() }

/// Configure CAS as an MCP server via .mcp.json
///
/// Creates or updates .mcp.json in the project root to register CAS.
/// This follows the Claude Code convention for project-level MCP configuration.
/// Returns Ok(true) if file was modified, Ok(false) if no changes needed.
pub fn configure_mcp_server(project_root: &Path) -> anyhow::Result<bool> { todo!() }

/// Configure CAS as an MCP server for Codex via .codex/config.toml
///
/// Creates or updates .codex/config.toml in the project root to register CAS.
/// Returns Ok(true) if file was modified, Ok(false) if no changes needed.
pub fn configure_codex_mcp_server(project_root: &Path) -> anyhow::Result<bool> { todo!() }
