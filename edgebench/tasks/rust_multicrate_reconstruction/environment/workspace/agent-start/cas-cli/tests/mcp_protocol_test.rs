//! MCP Protocol Integration Tests
//!
//! Tests the actual MCP server protocol by spawning the server and
//! communicating via JSON-RPC over stdio.
//!
//! These tests verify that:
//! 1. The server responds correctly to MCP protocol messages
//! 2. Tool calls work end-to-end through the protocol
//! 3. Error handling follows MCP spec

use serde::{Deserialize, Serialize};
use serde_json::{Value, json};
use std::io::{BufRead, BufReader, Write};
use std::process::{Command, Stdio};
use tempfile::TempDir;

// ============================================================================
// MCP Protocol Types
// ============================================================================

#[derive(Debug, Serialize)]
struct JsonRpcRequest {
    jsonrpc: &'static str,
    id: u64,
    method: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    params: Option<Value>,
}

impl JsonRpcRequest {
    fn new(id: u64, method: &str, params: Option<Value>) -> Self { todo!() }
}

#[derive(Debug, Deserialize)]
struct JsonRpcResponse {
    jsonrpc: String,
    id: Option<u64>,
    #[serde(default)]
    result: Option<Value>,
    #[serde(default)]
    error: Option<JsonRpcError>,
}

#[derive(Debug, Deserialize)]
struct JsonRpcError {
    code: i64,
    message: String,
    #[serde(default)]
    data: Option<Value>,
}

// ============================================================================
// Test Helpers
// ============================================================================

/// Helper to communicate with MCP server
struct McpTestClient {
    child: std::process::Child,
    stdin: std::process::ChildStdin,
    stdout: BufReader<std::process::ChildStdout>,
    next_id: u64,
}

impl McpTestClient {
    /// Spawn MCP server (7 meta-tools)
    fn spawn(cas_dir: &std::path::Path) -> Self { todo!() }

    fn send_request(&mut self, method: &str, params: Option<Value>) -> JsonRpcResponse { todo!() }

    fn call_tool(&mut self, name: &str, arguments: Value) -> JsonRpcResponse { todo!() }

    fn initialize(&mut self) -> JsonRpcResponse { todo!() }

    /// Send a notification (no response expected)
    fn send_notification(&mut self, method: &str, params: Option<Value>) { todo!() }

    fn list_tools(&mut self) -> JsonRpcResponse { todo!() }
}

impl Drop for McpTestClient {
    fn drop(&mut self) { todo!() }
}

/// Initialize CAS in temp directory
fn init_cas_dir(dir: &TempDir) { todo!() }

// ============================================================================
// Protocol Tests
// ============================================================================

#[test]
fn test_mcp_initialize() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    let response = client.initialize();

    assert!(response.error.is_none(), "Initialize should succeed");
    assert!(response.result.is_some(), "Should have result");

    let result = response.result.unwrap();
    assert!(result.get("protocolVersion").is_some());
    assert!(result.get("serverInfo").is_some());
    assert!(result.get("capabilities").is_some());

    let server_info = result.get("serverInfo").unwrap();
    assert_eq!(server_info.get("name").unwrap().as_str().unwrap(), "cas");
}



#[test]
fn test_mcp_tool_call_task_create() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Create a task (meta-tool API)
    let response = client.call_tool(
        "task",
        json!({
            "action": "create",
            "title": "MCP Protocol Test Task",
            "priority": 2,
            "task_type": "task"
        }),
    );

    assert!(
        response.error.is_none(),
        "Task create should succeed: {:?}",
        response.error
    );

    // Verify task was created by listing tasks
    let list_response = client.call_tool(
        "task",
        json!({
            "action": "list"
        }),
    );

    assert!(list_response.error.is_none());
    let result = list_response.result.unwrap();

    // Content should mention the task we created
    let empty_vec = vec![];
    let content = result
        .get("content")
        .and_then(|c| c.as_array())
        .unwrap_or(&empty_vec);

    let content_text: String = content
        .iter()
        .filter_map(|c| c.get("text").and_then(|t| t.as_str()))
        .collect();

    assert!(
        content_text.contains("MCP Protocol Test Task") || content_text.contains("cas-"),
        "Task list should include our task"
    );
}

#[test]
fn test_mcp_tool_call_search() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Add some content first (meta-tool API)
    client.call_tool(
        "memory",
        json!({
            "action": "remember",
            "content": "Rust programming language with ownership and borrowing",
            "tags": "rust,programming"
        }),
    );

    // Search for it (meta-tool API)
    let response = client.call_tool(
        "search",
        json!({
            "action": "search",
            "query": "rust ownership"
        }),
    );

    assert!(response.error.is_none(), "Search should succeed");
    assert!(response.result.is_some());
}


#[test]
fn test_mcp_unknown_tool() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    let response = client.call_tool("nonexistent_tool", json!({}));

    // Should return an error
    assert!(
        response.error.is_some(),
        "Unknown tool should return error: {response:?}"
    );
}




// ============================================================================
// Consolidated Tools Tests
// ============================================================================

#[test]
fn test_mcp_consolidated_memory_tool() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Test memory with "remember" action
    let response = client.call_tool(
        "memory",
        json!({
            "action": "remember",
            "content": "Consolidated memory test entry",
            "entry_type": "learning"
        }),
    );

    assert!(
        response.error.is_none(),
        "Memory remember should succeed: {:?}",
        response.error
    );
}


// ============================================================================
// Error Handling Tests
// ============================================================================

#[test]
fn test_mcp_invalid_json_rpc() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    // Must initialize first per MCP protocol
    client.initialize();

    // Send request with invalid method
    let response = client.send_request("invalid/method", None);

    // Should get method not found error
    assert!(response.error.is_some(), "Invalid method should error");
    if let Some(error) = response.error {
        assert_eq!(error.code, -32601, "Should be method not found error");
        assert!(
            !error.message.is_empty(),
            "Error message should be populated"
        );
        let _ = error.data.as_ref();
    }
}

#[test]
fn test_mcp_resources_list_changed_capability() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    let response = client.initialize();

    assert!(response.error.is_none(), "Initialize should succeed");
    let result = response.result.unwrap();

    // Check that resources.listChanged capability is advertised
    let capabilities = result
        .get("capabilities")
        .expect("should have capabilities");
    let resources = capabilities.get("resources");

    assert!(
        resources.is_some(),
        "Should have resources capability: {capabilities:?}"
    );

    let resources = resources.unwrap();
    let list_changed = resources.get("listChanged").and_then(|v| v.as_bool());

    assert_eq!(
        list_changed,
        Some(true),
        "resources.listChanged should be true: {resources:?}"
    );
}

#[test]
fn test_mcp_mutation_with_notifications() {
    // This test verifies that mutations work correctly even with notification code path
    // (notifications are fire-and-forget, so we can't directly verify they were sent,
    // but we verify the mutation succeeds and doesn't crash)
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // List resources first (this captures the peer for notifications)
    let list_response = client.send_request("resources/list", None);
    assert!(
        list_response.error.is_none(),
        "List resources should succeed"
    );

    // Create a memory (triggers notification)
    let response = client.call_tool(
        "memory",
        json!({
            "action": "remember",
            "content": "Test entry for notification test"
        }),
    );

    assert!(
        response.error.is_none(),
        "Memory create should succeed: {:?}",
        response.error
    );

    // Create a task (triggers notification)
    let response = client.call_tool(
        "task",
        json!({
            "action": "create",
            "title": "Test task for notification test"
        }),
    );

    assert!(
        response.error.is_none(),
        "Task create should succeed: {:?}",
        response.error
    );

    // Verify the resources were created by listing them
    let list_response = client.send_request("resources/list", None);
    assert!(list_response.error.is_none());

    let result = list_response.result.unwrap();
    let resources = result
        .get("resources")
        .and_then(|r| r.as_array())
        .expect("Should have resources array");

    // Should have at least one resource after mutations
    // (exact count may vary due to test parallelism)
    assert!(
        !resources.is_empty(),
        "Should have resources after mutations: {resources:?}"
    );
}
