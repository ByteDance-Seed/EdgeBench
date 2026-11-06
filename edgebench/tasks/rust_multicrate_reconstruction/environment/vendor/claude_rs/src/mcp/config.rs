//! MCP configuration generation.

use serde_json::{Value, json};

/// Generate MCP configuration for the bridge.
///
/// # Arguments
/// * `port` - The port the bridge is listening on
/// * `server_name` - Name for the MCP server (default: "claude_rs")
///
/// # Returns
/// JSON configuration for the MCP server.
pub fn generate_mcp_config(port: u16) -> Value {
    generate_mcp_config_with_name(port, "claude_rs")
}

/// Generate MCP configuration with a custom server name.
pub fn generate_mcp_config_with_name(port: u16, server_name: &str) -> Value {
    // Find the claude_rs_mcp binary
    let mcp_binary = find_mcp_binary();

    json!({
        "mcpServers": {
            server_name: {
                "command": mcp_binary,
                "args": ["--port", port.to_string()]
            }
        }
    })
}

/// Find the MCP binary path.
fn find_mcp_binary() -> String {
    // Try to find in the same directory as the current executable
    if let Ok(exe_path) = std::env::current_exe()
        && let Some(dir) = exe_path.parent()
    {
        let mcp_path = dir.join("claude_rs_mcp");
        if mcp_path.exists() {
            return mcp_path.to_string_lossy().to_string();
        }
    }

    // Try PATH
    if let Ok(output) = std::process::Command::new("which")
        .arg("claude_rs_mcp")
        .output()
        && output.status.success()
    {
        let path = String::from_utf8_lossy(&output.stdout);
        return path.trim().to_string();
    }

    // Default to just the binary name
    "claude_rs_mcp".to_string()
}

/// Write MCP configuration to a temporary file.
///
/// # Returns
/// Path to the temporary configuration file.
pub fn write_temp_config(port: u16) -> std::io::Result<tempfile::NamedTempFile> {
    let config = generate_mcp_config(port);
    let mut file = tempfile::Builder::new()
        .prefix("claude_rs_mcp_")
        .suffix(".json")
        .tempfile()?;

    use std::io::Write;
    write!(file, "{}", serde_json::to_string_pretty(&config)?)?;
    file.flush()?;

    Ok(file)
}
