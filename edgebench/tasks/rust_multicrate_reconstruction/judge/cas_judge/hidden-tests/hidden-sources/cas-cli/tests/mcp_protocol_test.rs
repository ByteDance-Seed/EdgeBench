#[test]
fn test_mcp_list_tools() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    let response = client.list_tools();

    assert!(response.error.is_none(), "List tools should succeed");
    assert!(response.result.is_some());

    let result = response.result.unwrap();
    let tools = result.get("tools").and_then(|t| t.as_array());
    assert!(tools.is_some(), "Should have tools array");

    let tools = tools.unwrap();
    assert!(!tools.is_empty(), "Should have at least one tool");

    // Check that expected tools exist
    let tool_names: Vec<&str> = tools
        .iter()
        .filter_map(|t| t.get("name").and_then(|n| n.as_str()))
        .collect();

    // We should have the 8 meta-tools
    assert!(
        tool_names.contains(&"memory") && tool_names.contains(&"task"),
        "Should have meta-tools (memory, task): {tool_names:?}"
    );
}

#[test]
fn test_mcp_tool_call_remember() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Call the memory tool with remember action (meta-tool API)
    let response = client.call_tool(
        "memory",
        json!({
            "action": "remember",
            "content": "Test memory from MCP protocol test",
            "entry_type": "learning",
            "tags": "test,mcp"
        }),
    );

    assert!(
        response.error.is_none(),
        "Tool call should succeed: {:?}",
        response.error
    );
    assert!(response.result.is_some());

    let result = response.result.unwrap();
    // MCP tool results have a "content" array
    let content = result.get("content").and_then(|c| c.as_array());
    assert!(content.is_some(), "Should have content array");

    let content = content.unwrap();
    assert!(!content.is_empty(), "Content should not be empty");

    // First content item should have text
    let text = content[0].get("text").and_then(|t| t.as_str());
    assert!(text.is_some(), "Should have text in content");
}

#[test]
fn test_mcp_tool_call_invalid_arguments() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Call with missing required argument (meta-tool API)
    let response = client.call_tool(
        "task",
        json!({
            "action": "create"
            // Missing required "title"
        }),
    );

    // Should get an error response
    assert!(
        response.error.is_some() || {
            // Some implementations return success with error in content
            response
                .result
                .as_ref()
                .and_then(|r| r.get("isError"))
                .and_then(|e| e.as_bool())
                .unwrap_or(false)
        },
        "Should indicate error for missing required field"
    );
}

#[test]
fn test_mcp_rule_lifecycle() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Create a rule (meta-tool API)
    let create_response = client.call_tool(
        "rule",
        json!({
            "action": "create",
            "content": "Always use descriptive variable names in tests",
            "tags": "testing,style"
        }),
    );

    assert!(
        create_response.error.is_none(),
        "Rule create should succeed: {:?}",
        create_response.error
    );

    // List all rules (meta-tool API)
    let list_all_response = client.call_tool(
        "rule",
        json!({
            "action": "list_all"
        }),
    );
    assert!(list_all_response.error.is_none());
}

#[test]
fn test_mcp_context() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Add some data (meta-tool API)
    client.call_tool(
        "memory",
        json!({
            "action": "remember",
            "content": "Context test memory entry"
        }),
    );

    client.call_tool(
        "task",
        json!({
            "action": "create",
            "title": "Context test task"
        }),
    );

    // Get context (meta-tool API)
    let response = client.call_tool(
        "search",
        json!({
            "action": "context"
        }),
    );

    assert!(response.error.is_none(), "Context should succeed");
    assert!(response.result.is_some());

    let result = response.result.unwrap();
    let empty_vec = vec![];
    let content = result
        .get("content")
        .and_then(|c| c.as_array())
        .unwrap_or(&empty_vec);

    // Context should have content
    assert!(!content.is_empty(), "Context should have content");
}

#[test]
fn test_mcp_doctor() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Doctor is accessed via system with action: doctor
    let response = client.call_tool(
        "system",
        json!({
            "action": "doctor"
        }),
    );

    assert!(response.error.is_none(), "Doctor should succeed");
    assert!(response.result.is_some());
}

#[test]
fn test_mcp_consolidated_task_tool() {
    let dir = TempDir::new().unwrap();
    init_cas_dir(&dir);

    let mut client = McpTestClient::spawn(dir.path());
    client.initialize();

    // Test task with "create" action
    let response = client.call_tool(
        "task",
        json!({
            "action": "create",
            "title": "Consolidated task test"
        }),
    );

    assert!(
        response.error.is_none(),
        "Task create should succeed: {:?}",
        response.error
    );
}
