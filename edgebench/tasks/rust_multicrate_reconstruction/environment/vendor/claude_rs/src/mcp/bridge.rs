//! MCP Bridge - TCP server for tool execution.

use crate::error::{Error, Result};
use crate::tool::Tool;

use serde::{Deserialize, Serialize};
use serde_json::Value;
use std::collections::HashMap;
use std::sync::Arc;
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::{TcpListener, TcpStream};
use tokio::sync::RwLock;

/// MCP Bridge server for tool execution.
///
/// The bridge listens on a TCP port and handles tool list and execution
/// requests from the MCP stdio server.
pub struct McpBridge {
    tools: Arc<RwLock<HashMap<String, Tool>>>,
    listener: TcpListener,
    port: u16,
}

/// Request from the MCP stdio server.
#[derive(Debug, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum BridgeRequest {
    /// List available tools
    ListTools,
    /// Execute a tool
    Execute {
        name: String,
        args: Value,
        id: String,
    },
}

/// Response to the MCP stdio server.
#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum BridgeResponse {
    /// Tool list response
    Tools { tools: Vec<ToolSpec> },
    /// Execution result
    Result {
        id: String,
        ok: bool,
        #[serde(skip_serializing_if = "Option::is_none")]
        result: Option<Value>,
        #[serde(skip_serializing_if = "Option::is_none")]
        error: Option<String>,
    },
}

/// Tool specification for listing.
#[derive(Debug, Serialize)]
struct ToolSpec {
    name: String,
    description: String,
    #[serde(rename = "inputSchema")]
    input_schema: Value,
}

impl McpBridge {
    /// Start a new MCP bridge.
    ///
    /// # Returns
    /// The bridge instance and the port it's listening on.
    pub async fn start(tools: Vec<Tool>) -> Result<Self> {
        let listener = TcpListener::bind("127.0.0.1:0")
            .await
            .map_err(|e| Error::mcp(format!("Failed to bind: {e}")))?;

        let port = listener
            .local_addr()
            .map_err(|e| Error::mcp(format!("Failed to get address: {e}")))?
            .port();

        let tool_map: HashMap<String, Tool> =
            tools.into_iter().map(|t| (t.name.clone(), t)).collect();

        Ok(Self {
            tools: Arc::new(RwLock::new(tool_map)),
            listener,
            port,
        })
    }

    /// Get the port the bridge is listening on.
    pub fn port(&self) -> u16 {
        self.port
    }

    /// Run the bridge accept loop.
    ///
    /// This will accept connections and handle requests until dropped.
    pub async fn run(self) -> Result<()> {
        loop {
            let (stream, _) = self
                .listener
                .accept()
                .await
                .map_err(|e| Error::mcp(format!("Accept failed: {e}")))?;

            let tools = Arc::clone(&self.tools);
            tokio::spawn(async move {
                if let Err(e) = handle_connection(stream, tools).await {
                    tracing::error!("Connection error: {}", e);
                }
            });
        }
    }

    /// Add a tool to the bridge.
    pub async fn add_tool(&self, tool: Tool) {
        let mut tools = self.tools.write().await;
        tools.insert(tool.name.clone(), tool);
    }

    /// Remove a tool from the bridge.
    pub async fn remove_tool(&self, name: &str) {
        let mut tools = self.tools.write().await;
        tools.remove(name);
    }
}

/// Handle a single client connection.
async fn handle_connection(
    stream: TcpStream,
    tools: Arc<RwLock<HashMap<String, Tool>>>,
) -> Result<()> {
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);
    let mut line = String::new();

    loop {
        line.clear();
        let n = reader
            .read_line(&mut line)
            .await
            .map_err(|e| Error::mcp(format!("Read error: {e}")))?;

        if n == 0 {
            break; // Connection closed
        }

        let request: BridgeRequest = match serde_json::from_str(&line) {
            Ok(r) => r,
            Err(e) => {
                tracing::warn!("Invalid request: {}", e);
                continue;
            }
        };

        let response = match request {
            BridgeRequest::ListTools => {
                let tools = tools.read().await;
                let specs: Vec<ToolSpec> = tools
                    .values()
                    .map(|t| ToolSpec {
                        name: t.name.clone(),
                        description: t.description.clone(),
                        input_schema: t.schema.clone(),
                    })
                    .collect();
                BridgeResponse::Tools { tools: specs }
            }
            BridgeRequest::Execute { name, args, id } => {
                let tools = tools.read().await;
                match tools.get(&name) {
                    Some(tool) => {
                        // Release lock before executing
                        let tool = tool.clone();
                        drop(tools);

                        match tool.execute(args).await {
                            Ok(result) => BridgeResponse::Result {
                                id,
                                ok: true,
                                result: Some(result),
                                error: None,
                            },
                            Err(e) => BridgeResponse::Result {
                                id,
                                ok: false,
                                result: None,
                                error: Some(e.to_string()),
                            },
                        }
                    }
                    None => BridgeResponse::Result {
                        id,
                        ok: false,
                        result: None,
                        error: Some(format!("Tool not found: {name}")),
                    },
                }
            }
        };

        let response_json = serde_json::to_string(&response)
            .map_err(|e| Error::mcp(format!("Serialize error: {e}")))?;

        writer
            .write_all(response_json.as_bytes())
            .await
            .map_err(|e| Error::mcp(format!("Write error: {e}")))?;
        writer
            .write_all(b"\n")
            .await
            .map_err(|e| Error::mcp(format!("Write error: {e}")))?;
        writer
            .flush()
            .await
            .map_err(|e| Error::mcp(format!("Flush error: {e}")))?;
    }

    Ok(())
}
