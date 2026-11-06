use crate::error::{Error, Result};
use crate::message::{AccountInfo, McpServerStatus, ModelInfo, SlashCommand};
use crate::query::Query;
use serde_json::{Value, json};

impl Query {
    /// Set the model for subsequent responses.
    pub async fn set_model(&mut self, model: &str) -> Result<()> {
        let response = self
            .send_control_request(json!({
                "subtype": "set_model",
                "model": model
            }))
            .await?;
        ensure_no_runtime_error(&response)
    }

    /// Clear the model override (use default).
    pub async fn clear_model(&mut self) -> Result<()> {
        let response = self
            .send_control_request(json!({
                "subtype": "set_model",
                "model": null
            }))
            .await?;
        ensure_no_runtime_error(&response)
    }

    /// Set the permission mode for the session.
    pub async fn set_permission_mode(&mut self, mode: crate::PermissionMode) -> Result<()> {
        let response = self
            .send_control_request(json!({
                "subtype": "set_permission_mode",
                "mode": mode.to_cli_arg()
            }))
            .await?;
        ensure_no_runtime_error(&response)
    }

    /// Set maximum thinking tokens.
    pub async fn set_max_thinking_tokens(&mut self, tokens: u32) -> Result<()> {
        let response = self
            .send_control_request(json!({
                "subtype": "set_max_thinking_tokens",
                "max_thinking_tokens": tokens
            }))
            .await?;
        ensure_no_runtime_error(&response)
    }

    /// Clear max thinking tokens limit.
    pub async fn clear_max_thinking_tokens(&mut self) -> Result<()> {
        let response = self
            .send_control_request(json!({
                "subtype": "set_max_thinking_tokens",
                "max_thinking_tokens": null
            }))
            .await?;
        ensure_no_runtime_error(&response)
    }

    /// Get list of available slash commands.
    pub async fn supported_commands(&mut self) -> Result<Vec<SlashCommand>> {
        let response = self
            .send_control_request(json!({
                "subtype": "initialize"
            }))
            .await?;

        if let Some(commands) = response.get("commands") {
            Ok(serde_json::from_value(commands.clone()).unwrap_or_default())
        } else {
            Ok(Vec::new())
        }
    }

    /// Get list of available models.
    pub async fn supported_models(&mut self) -> Result<Vec<ModelInfo>> {
        let response = self
            .send_control_request(json!({
                "subtype": "initialize"
            }))
            .await?;

        if let Some(models) = response.get("models") {
            Ok(serde_json::from_value(models.clone()).unwrap_or_default())
        } else {
            Ok(Vec::new())
        }
    }

    /// Get MCP server connection status.
    pub async fn mcp_server_status(&mut self) -> Result<Vec<McpServerStatus>> {
        let response = self
            .send_control_request(json!({
                "subtype": "mcp_status"
            }))
            .await?;

        if let Some(servers) = response.get("servers") {
            Ok(serde_json::from_value(servers.clone()).unwrap_or_default())
        } else {
            Ok(Vec::new())
        }
    }

    /// Get account information.
    pub async fn account_info(&mut self) -> Result<AccountInfo> {
        let response = self
            .send_control_request(json!({
                "subtype": "initialize"
            }))
            .await?;

        if let Some(account) = response.get("account") {
            Ok(serde_json::from_value(account.clone()).unwrap_or_default())
        } else {
            Ok(AccountInfo::default())
        }
    }

    /// Rewind tracked files to their state at a specific user message.
    ///
    /// Requires `enable_file_checkpointing` to be set in options.
    pub async fn rewind_files(&mut self, user_message_id: &str) -> Result<()> {
        let response = self
            .send_control_request(json!({
                "subtype": "rewind_files",
                "user_message_id": user_message_id
            }))
            .await?;
        ensure_no_runtime_error(&response)
    }
}

fn ensure_no_runtime_error(response: &Value) -> Result<()> {
    if let Some(err) = response.get("error") {
        let message = err.as_str().unwrap_or("Unknown error").to_string();
        return Err(Error::Runtime(message));
    }
    Ok(())
}
