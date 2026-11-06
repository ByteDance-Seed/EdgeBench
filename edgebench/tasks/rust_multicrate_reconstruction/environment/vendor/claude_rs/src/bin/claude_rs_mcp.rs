//! MCP stdio server binary.
//!
//! This binary is spawned by the Claude CLI to handle MCP protocol
//! communication. It reads JSON-RPC 2.0 from stdin and writes to stdout,
//! connecting to the claude_rs bridge via TCP for actual tool execution.

use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::io::{BufRead, Write};
use std::net::TcpStream;

/// JSON-RPC 2.0 request.
#[derive(Debug, Deserialize)]
struct JsonRpcRequest {
    jsonrpc: String,
    method: String,
    #[serde(default)]
    params: Option<Value>,
    id: Option<Value>,
}

/// JSON-RPC 2.0 response.
#[derive(Debug, Serialize)]
struct JsonRpcResponse {
    jsonrpc: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    result: Option<Value>,
    #[serde(skip_serializing_if = "Option::is_none")]
    error: Option<JsonRpcError>,
    id: Value,
}

/// JSON-RPC 2.0 error.
#[derive(Debug, Serialize)]
struct JsonRpcError {
    code: i32,
    message: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    data: Option<Value>,
}

/// Bridge request.
#[derive(Debug, Serialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum BridgeRequest {
    ListTools,
    Execute {
        name: String,
        args: Value,
        id: String,
    },
}

/// Bridge response.
#[derive(Debug, Deserialize)]
#[serde(tag = "type", rename_all = "snake_case")]
enum BridgeResponse {
    Tools {
        tools: Vec<ToolSpec>,
    },
    Result {
        id: String,
        ok: bool,
        result: Option<Value>,
        error: Option<String>,
    },
}

/// Tool specification.
#[derive(Debug, Deserialize, Serialize)]
struct ToolSpec {
    name: String,
    description: String,
    #[serde(rename = "inputSchema")]
    input_schema: Value,
}

fn main() {
    let args: Vec<String> = std::env::args().collect();
    let port = parse_port(&args).unwrap_or(0);

    if port == 0 {
        eprintln!("Usage: claude_rs_mcp --port <port>");
        std::process::exit(1);
    }

    // Connect to bridge
    let bridge = match TcpStream::connect(format!("127.0.0.1:{port}")) {
        Ok(stream) => stream,
        Err(e) => {
            eprintln!("Failed to connect to bridge: {e}");
            std::process::exit(1);
        }
    };

    let mut bridge_reader = std::io::BufReader::new(bridge.try_clone().unwrap());
    let mut bridge_writer = bridge;

    let stdin = std::io::stdin();
    let stdout = std::io::stdout();
    let mut stdout = stdout.lock();

    for line in stdin.lock().lines() {
        let line = match line {
            Ok(l) => l,
            Err(_) => break,
        };

        if line.trim().is_empty() {
            continue;
        }

        let request: JsonRpcRequest = match serde_json::from_str(&line) {
            Ok(r) => r,
            Err(e) => {
                eprintln!("Invalid JSON-RPC: {e}");
                continue;
            }
        };

        // Validate JSON-RPC version
        if request.jsonrpc != "2.0" {
            eprintln!("Invalid JSON-RPC version: {}", request.jsonrpc);
            continue;
        }

        let response = handle_request(&request, &mut bridge_reader, &mut bridge_writer);

        if let Some(response) = response {
            let json = serde_json::to_string(&response).unwrap();
            writeln!(stdout, "{json}").unwrap();
            stdout.flush().unwrap();
        }
    }
}

fn parse_port(args: &[String]) -> Option<u16> {
    for i in 0..args.len() {
        if args[i] == "--port" && i + 1 < args.len() {
            return args[i + 1].parse().ok();
        }
    }
    None
}

fn handle_request(
    request: &JsonRpcRequest,
    bridge_reader: &mut std::io::BufReader<TcpStream>,
    bridge_writer: &mut TcpStream,
) -> Option<JsonRpcResponse> {
    let id = request.id.clone()?;

    let result = match request.method.as_str() {
        "initialize" => handle_initialize(),
        "tools/list" => handle_tools_list(bridge_reader, bridge_writer),
        "tools/call" => handle_tools_call(request, bridge_reader, bridge_writer),
        _ => Err(JsonRpcError {
            code: -32601,
            message: format!("Method not found: {}", request.method),
            data: None,
        }),
    };

    Some(match result {
        Ok(result) => JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            result: Some(result),
            error: None,
            id,
        },
        Err(error) => JsonRpcResponse {
            jsonrpc: "2.0".to_string(),
            result: None,
            error: Some(error),
            id,
        },
    })
}

fn handle_initialize() -> Result<Value, JsonRpcError> {
    Ok(json!({
        "protocolVersion": "2025-03-26",
        "capabilities": {
            "tools": {}
        },
        "serverInfo": {
            "name": "claude_rs",
            "version": env!("CARGO_PKG_VERSION")
        }
    }))
}

fn handle_tools_list(
    bridge_reader: &mut std::io::BufReader<TcpStream>,
    bridge_writer: &mut TcpStream,
) -> Result<Value, JsonRpcError> {
    // Request tools from bridge
    let request = BridgeRequest::ListTools;
    let request_json = serde_json::to_string(&request).unwrap();
    writeln!(bridge_writer, "{request_json}").map_err(|e| JsonRpcError {
        code: -32000,
        message: format!("Bridge write error: {e}"),
        data: None,
    })?;
    bridge_writer.flush().map_err(|e| JsonRpcError {
        code: -32000,
        message: format!("Bridge flush error: {e}"),
        data: None,
    })?;

    // Read response
    let mut line = String::new();
    bridge_reader
        .read_line(&mut line)
        .map_err(|e| JsonRpcError {
            code: -32000,
            message: format!("Bridge read error: {e}"),
            data: None,
        })?;

    let response: BridgeResponse = serde_json::from_str(&line).map_err(|e| JsonRpcError {
        code: -32000,
        message: format!("Bridge parse error: {e}"),
        data: None,
    })?;

    match response {
        BridgeResponse::Tools { tools } => Ok(json!({ "tools": tools })),
        _ => Err(JsonRpcError {
            code: -32000,
            message: "Unexpected response".to_string(),
            data: None,
        }),
    }
}

fn handle_tools_call(
    request: &JsonRpcRequest,
    bridge_reader: &mut std::io::BufReader<TcpStream>,
    bridge_writer: &mut TcpStream,
) -> Result<Value, JsonRpcError> {
    let params = request.params.as_ref().ok_or(JsonRpcError {
        code: -32602,
        message: "Missing params".to_string(),
        data: None,
    })?;

    let name = params["name"].as_str().ok_or(JsonRpcError {
        code: -32602,
        message: "Missing tool name".to_string(),
        data: None,
    })?;

    let args = params.get("arguments").cloned().unwrap_or(json!({}));
    let call_id = uuid::Uuid::new_v4().to_string();

    // Request execution from bridge
    let bridge_request = BridgeRequest::Execute {
        name: name.to_string(),
        args,
        id: call_id.clone(),
    };
    let request_json = serde_json::to_string(&bridge_request).unwrap();
    writeln!(bridge_writer, "{request_json}").map_err(|e| JsonRpcError {
        code: -32000,
        message: format!("Bridge write error: {e}"),
        data: None,
    })?;
    bridge_writer.flush().map_err(|e| JsonRpcError {
        code: -32000,
        message: format!("Bridge flush error: {e}"),
        data: None,
    })?;

    // Read response
    let mut line = String::new();
    bridge_reader
        .read_line(&mut line)
        .map_err(|e| JsonRpcError {
            code: -32000,
            message: format!("Bridge read error: {e}"),
            data: None,
        })?;

    let response: BridgeResponse = serde_json::from_str(&line).map_err(|e| JsonRpcError {
        code: -32000,
        message: format!("Bridge parse error: {e}"),
        data: None,
    })?;

    match response {
        BridgeResponse::Result {
            id: response_id,
            ok,
            result,
            error,
        } => {
            // Verify response matches our request
            if response_id != call_id {
                return Err(JsonRpcError {
                    code: -32000,
                    message: format!("Response ID mismatch: expected {call_id}, got {response_id}"),
                    data: None,
                });
            }
            if ok {
                let text = match result {
                    Some(Value::String(s)) => s,
                    Some(v) => serde_json::to_string(&v).unwrap_or_default(),
                    None => String::new(),
                };
                Ok(json!({
                    "content": [{"type": "text", "text": text}]
                }))
            } else {
                Err(JsonRpcError {
                    code: -32000,
                    message: error.unwrap_or_else(|| "Tool execution failed".to_string()),
                    data: None,
                })
            }
        }
        _ => Err(JsonRpcError {
            code: -32000,
            message: "Unexpected response".to_string(),
            data: None,
        }),
    }
}
