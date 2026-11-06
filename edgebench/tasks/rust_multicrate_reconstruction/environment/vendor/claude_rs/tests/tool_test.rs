//! Tool system tests.

use async_trait::async_trait;
use claude_rs::Result;
use claude_rs::tool::{JsonSchema, Tool, ToolHandler};
use serde_json::{Value, json};

/// Test tool handler that echoes input.
struct EchoTool;

#[async_trait]
impl ToolHandler for EchoTool {
    async fn handle(&self, input: Value) -> Result<Value> {
        Ok(input)
    }
}

/// Test tool handler that returns a fixed value.
struct FixedTool {
    value: Value,
}

#[async_trait]
impl ToolHandler for FixedTool {
    async fn handle(&self, _input: Value) -> Result<Value> {
        Ok(self.value.clone())
    }
}

/// Test tool handler that fails.
struct FailingTool;

#[async_trait]
impl ToolHandler for FailingTool {
    async fn handle(&self, _input: Value) -> Result<Value> {
        Err(claude_rs::Error::tool_execution("Tool failed"))
    }
}

#[tokio::test]
async fn test_tool_creation() {
    let tool = Tool::new(
        "test_tool",
        "A test tool",
        json!({"type": "object"}),
        EchoTool,
    );

    assert_eq!(tool.name, "test_tool");
    assert_eq!(tool.description, "A test tool");
}

#[tokio::test]
async fn test_tool_builder() {
    let tool = Tool::builder("my_tool")
        .description("My custom tool")
        .schema(json!({
            "type": "object",
            "properties": {
                "message": {"type": "string"}
            }
        }))
        .handler(EchoTool);

    assert_eq!(tool.name, "my_tool");
    assert_eq!(tool.description, "My custom tool");
}

#[tokio::test]
async fn test_tool_builder_with_closure() {
    let tool = Tool::builder("closure_tool")
        .description("Tool with closure handler")
        .schema(json!({"type": "object"}))
        .handler_fn(|input| async move { Ok(json!({"received": input})) });

    let result = tool.execute(json!({"test": "value"})).await.unwrap();
    assert_eq!(result["received"]["test"], "value");
}

#[tokio::test]
async fn test_tool_execute_success() {
    let tool = Tool::new("echo", "Echo tool", json!({"type": "object"}), EchoTool);

    let input = json!({"message": "hello"});
    let result = tool.execute(input.clone()).await.unwrap();

    assert_eq!(result, input);
}

#[tokio::test]
async fn test_tool_execute_with_fixed_output() {
    let tool = Tool::new(
        "fixed",
        "Fixed output tool",
        json!({"type": "object"}),
        FixedTool {
            value: json!({"status": "ok"}),
        },
    );

    let result = tool.execute(json!({})).await.unwrap();
    assert_eq!(result["status"], "ok");
}

#[tokio::test]
async fn test_tool_execute_failure() {
    let tool = Tool::new(
        "failing",
        "Failing tool",
        json!({"type": "object"}),
        FailingTool,
    );

    let result = tool.execute(json!({})).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_tool_validation_success() {
    let tool = Tool::new(
        "validated",
        "Validated tool",
        json!({
            "type": "object",
            "properties": {
                "name": {"type": "string"},
                "age": {"type": "integer"}
            },
            "required": ["name"]
        }),
        EchoTool,
    );

    // Valid input
    let result = tool.execute(json!({"name": "Alice", "age": 30})).await;
    assert!(result.is_ok());

    // Valid input (optional field missing)
    let result = tool.execute(json!({"name": "Bob"})).await;
    assert!(result.is_ok());
}

#[tokio::test]
async fn test_tool_validation_failure() {
    let tool = Tool::new(
        "validated",
        "Validated tool",
        json!({
            "type": "object",
            "properties": {
                "name": {"type": "string"}
            },
            "required": ["name"]
        }),
        EchoTool,
    );

    // Missing required field
    let result = tool.execute(json!({})).await;
    assert!(result.is_err());

    // Wrong type
    let result = tool.execute(json!({"name": 123})).await;
    assert!(result.is_err());
}

#[tokio::test]
async fn test_tool_to_mcp_format() {
    let tool = Tool::new(
        "test",
        "Test tool",
        json!({"type": "object", "properties": {"x": {"type": "number"}}}),
        EchoTool,
    );

    let mcp = tool.to_mcp_format();
    assert_eq!(mcp["name"], "test");
    assert_eq!(mcp["description"], "Test tool");
    assert!(mcp["inputSchema"].is_object());
}

#[test]
fn test_json_schema_object_builder() {
    let schema = JsonSchema::object()
        .property(
            "name",
            JsonSchema::string().description("User name").build(),
        )
        .property("age", JsonSchema::integer().minimum(0.0).build())
        .optional_property("email", JsonSchema::string().build())
        .build();

    assert_eq!(schema["type"], "object");
    assert!(schema["properties"]["name"].is_object());
    assert!(schema["properties"]["age"].is_object());
    assert!(
        schema["required"]
            .as_array()
            .unwrap()
            .contains(&json!("name"))
    );
    assert!(
        schema["required"]
            .as_array()
            .unwrap()
            .contains(&json!("age"))
    );
    // email should NOT be in required
    assert!(
        !schema["required"]
            .as_array()
            .unwrap()
            .contains(&json!("email"))
    );
}

#[test]
fn test_json_schema_primitives() {
    let string_schema = JsonSchema::string()
        .description("A string field")
        .min_length(1)
        .max_length(100)
        .build();

    assert_eq!(string_schema["type"], "string");
    assert_eq!(string_schema["minLength"], 1);
    assert_eq!(string_schema["maxLength"], 100);

    let int_schema = JsonSchema::integer().minimum(0.0).maximum(100.0).build();

    assert_eq!(int_schema["type"], "integer");
    assert_eq!(int_schema["minimum"], 0.0);
    assert_eq!(int_schema["maximum"], 100.0);
}

#[test]
fn test_json_schema_enum() {
    let enum_schema = JsonSchema::enum_values(&["red", "green", "blue"]);

    assert_eq!(enum_schema["type"], "string");
    assert!(
        enum_schema["enum"]
            .as_array()
            .unwrap()
            .contains(&json!("red"))
    );
}

#[test]
fn test_json_schema_array() {
    let array_schema = JsonSchema::array(JsonSchema::string().build());

    assert_eq!(array_schema["type"], "array");
    assert_eq!(array_schema["items"]["type"], "string");
}
