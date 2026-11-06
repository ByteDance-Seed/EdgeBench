//! MCP Bridge tests.

use async_trait::async_trait;
use claude_rs::Result;
use claude_rs::mcp::McpBridge;
use claude_rs::tool::{Tool, ToolHandler};
use serde_json::{Value, json};
use tokio::io::{AsyncBufReadExt, AsyncWriteExt, BufReader};
use tokio::net::TcpStream;

/// Echo tool for testing.
struct EchoTool;

#[async_trait]
impl ToolHandler for EchoTool {
    async fn handle(&self, input: Value) -> Result<Value> {
        Ok(input)
    }
}

/// Tool that always fails.
struct FailingTool;

#[async_trait]
impl ToolHandler for FailingTool {
    async fn handle(&self, _input: Value) -> Result<Value> {
        Err(claude_rs::Error::tool_execution("Tool failed"))
    }
}

#[tokio::test]
async fn test_bridge_start() {
    let tools = vec![Tool::new(
        "echo",
        "Echo tool",
        json!({"type": "object"}),
        EchoTool,
    )];

    let bridge = McpBridge::start(tools).await.unwrap();
    let port = bridge.port();

    // Port should be non-zero
    assert_ne!(port, 0);
}

#[tokio::test]
async fn test_bridge_list_tools() {
    let tools = vec![
        Tool::new(
            "echo",
            "Echo tool",
            json!({"type": "object", "properties": {"message": {"type": "string"}}}),
            EchoTool,
        ),
        Tool::new(
            "failing",
            "Failing tool",
            json!({"type": "object"}),
            FailingTool,
        ),
    ];

    let bridge = McpBridge::start(tools).await.unwrap();
    let port = bridge.port();

    // Spawn bridge in background
    tokio::spawn(async move {
        let _ = bridge.run().await;
    });

    // Give the bridge time to start
    tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;

    // Connect to the bridge
    let stream = TcpStream::connect(format!("127.0.0.1:{port}"))
        .await
        .unwrap();
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);

    // Send list_tools request
    let request = json!({"type": "list_tools"});
    writer
        .write_all(format!("{request}\n").as_bytes())
        .await
        .unwrap();
    writer.flush().await.unwrap();

    // Read response
    let mut response_line = String::new();
    reader.read_line(&mut response_line).await.unwrap();

    let response: Value = serde_json::from_str(&response_line).unwrap();
    assert_eq!(response["type"], "tools");

    let tools = response["tools"].as_array().unwrap();
    assert_eq!(tools.len(), 2);

    // Check that both tools are listed
    let tool_names: Vec<&str> = tools.iter().map(|t| t["name"].as_str().unwrap()).collect();
    assert!(tool_names.contains(&"echo"));
    assert!(tool_names.contains(&"failing"));
}

#[tokio::test]
async fn test_bridge_execute_success() {
    let tools = vec![Tool::new(
        "echo",
        "Echo tool",
        json!({"type": "object"}),
        EchoTool,
    )];

    let bridge = McpBridge::start(tools).await.unwrap();
    let port = bridge.port();

    // Spawn bridge in background
    tokio::spawn(async move {
        let _ = bridge.run().await;
    });

    tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;

    let stream = TcpStream::connect(format!("127.0.0.1:{port}"))
        .await
        .unwrap();
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);

    // Send execute request
    let request = json!({
        "type": "execute",
        "name": "echo",
        "args": {"message": "hello"},
        "id": "req-123"
    });
    writer
        .write_all(format!("{request}\n").as_bytes())
        .await
        .unwrap();
    writer.flush().await.unwrap();

    // Read response
    let mut response_line = String::new();
    reader.read_line(&mut response_line).await.unwrap();

    let response: Value = serde_json::from_str(&response_line).unwrap();
    assert_eq!(response["type"], "result");
    assert_eq!(response["id"], "req-123");
    assert_eq!(response["ok"], true);
    assert_eq!(response["result"]["message"], "hello");
}

#[tokio::test]
async fn test_bridge_execute_tool_not_found() {
    let tools = vec![Tool::new(
        "echo",
        "Echo tool",
        json!({"type": "object"}),
        EchoTool,
    )];

    let bridge = McpBridge::start(tools).await.unwrap();
    let port = bridge.port();

    tokio::spawn(async move {
        let _ = bridge.run().await;
    });

    tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;

    let stream = TcpStream::connect(format!("127.0.0.1:{port}"))
        .await
        .unwrap();
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);

    // Send execute request for non-existent tool
    let request = json!({
        "type": "execute",
        "name": "nonexistent",
        "args": {},
        "id": "req-456"
    });
    writer
        .write_all(format!("{request}\n").as_bytes())
        .await
        .unwrap();
    writer.flush().await.unwrap();

    let mut response_line = String::new();
    reader.read_line(&mut response_line).await.unwrap();

    let response: Value = serde_json::from_str(&response_line).unwrap();
    assert_eq!(response["type"], "result");
    assert_eq!(response["id"], "req-456");
    assert_eq!(response["ok"], false);
    assert!(response["error"].as_str().unwrap().contains("not found"));
}

#[tokio::test]
async fn test_bridge_execute_failure() {
    let tools = vec![Tool::new(
        "failing",
        "Failing tool",
        json!({"type": "object"}),
        FailingTool,
    )];

    let bridge = McpBridge::start(tools).await.unwrap();
    let port = bridge.port();

    tokio::spawn(async move {
        let _ = bridge.run().await;
    });

    tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;

    let stream = TcpStream::connect(format!("127.0.0.1:{port}"))
        .await
        .unwrap();
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);

    // Send execute request for failing tool
    let request = json!({
        "type": "execute",
        "name": "failing",
        "args": {},
        "id": "req-789"
    });
    writer
        .write_all(format!("{request}\n").as_bytes())
        .await
        .unwrap();
    writer.flush().await.unwrap();

    let mut response_line = String::new();
    reader.read_line(&mut response_line).await.unwrap();

    let response: Value = serde_json::from_str(&response_line).unwrap();
    assert_eq!(response["type"], "result");
    assert_eq!(response["id"], "req-789");
    assert_eq!(response["ok"], false);
    assert!(response["error"].as_str().unwrap().contains("Tool failed"));
}

#[tokio::test]
async fn test_bridge_add_remove_tool() {
    let bridge = McpBridge::start(vec![]).await.unwrap();
    let port = bridge.port();

    // Add a tool
    let echo_tool = Tool::new("echo", "Echo tool", json!({"type": "object"}), EchoTool);
    bridge.add_tool(echo_tool).await;

    // Spawn bridge in background
    tokio::spawn(async move {
        let _ = bridge.run().await;
    });

    tokio::time::sleep(tokio::time::Duration::from_millis(50)).await;

    let stream = TcpStream::connect(format!("127.0.0.1:{port}"))
        .await
        .unwrap();
    let (reader, mut writer) = stream.into_split();
    let mut reader = BufReader::new(reader);

    // List tools - should have echo
    let request = json!({"type": "list_tools"});
    writer
        .write_all(format!("{request}\n").as_bytes())
        .await
        .unwrap();
    writer.flush().await.unwrap();

    let mut response_line = String::new();
    reader.read_line(&mut response_line).await.unwrap();

    let response: Value = serde_json::from_str(&response_line).unwrap();
    let tools = response["tools"].as_array().unwrap();
    assert_eq!(tools.len(), 1);
    assert_eq!(tools[0]["name"], "echo");
}
