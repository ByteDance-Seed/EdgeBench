//! Tool definition and execution.
//!
//! Tools allow Claude to perform actions like reading files, running commands,
//! or calling external APIs.

mod handler;
mod schema;

pub use handler::{ConstHandler, EchoHandler, ToolHandler};
pub use schema::JsonSchema;

use crate::error::{Error, Result};
use async_trait::async_trait;
use serde_json::Value;
use std::sync::Arc;

/// A tool that Claude can use.
#[derive(Clone)]
pub struct Tool {
    /// Tool name (must be unique)
    pub name: String,

    /// Human-readable description
    pub description: String,

    /// JSON Schema for input validation
    pub schema: Value,

    /// Handler for executing the tool
    handler: Arc<dyn ToolHandler>,
}

impl Tool {
    /// Create a new tool.
    pub fn new<H: ToolHandler + 'static>(
        name: impl Into<String>,
        description: impl Into<String>,
        schema: Value,
        handler: H,
    ) -> Self {
        Self {
            name: name.into(),
            description: description.into(),
            schema,
            handler: Arc::new(handler),
        }
    }

    /// Create a tool builder.
    pub fn builder(name: impl Into<String>) -> ToolBuilder {
        ToolBuilder::new(name)
    }

    /// Execute the tool with the given input.
    pub async fn execute(&self, input: Value) -> Result<Value> {
        // Validate input against schema
        self.validate_input(&input)?;

        // Execute handler
        self.handler.handle(input).await
    }

    /// Validate input against the schema.
    fn validate_input(&self, input: &Value) -> Result<()> {
        // Use jsonschema for validation
        let compiled = jsonschema::validator_for(&self.schema)
            .map_err(|e| Error::tool_validation(format!("Invalid schema: {e}")))?;

        if let Err(error) = compiled.validate(input) {
            return Err(Error::tool_validation(format!(
                "{}: {}",
                error.instance_path, error
            )));
        }

        Ok(())
    }

    /// Convert to MCP tool format.
    pub fn to_mcp_format(&self) -> Value {
        serde_json::json!({
            "name": self.name,
            "description": self.description,
            "inputSchema": self.schema
        })
    }
}

impl std::fmt::Debug for Tool {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("Tool")
            .field("name", &self.name)
            .field("description", &self.description)
            .field("schema", &self.schema)
            .finish()
    }
}

/// Builder for creating tools.
pub struct ToolBuilder {
    name: String,
    description: Option<String>,
    schema: Option<Value>,
}

impl ToolBuilder {
    /// Create a new tool builder.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            description: None,
            schema: None,
        }
    }

    /// Set the description.
    pub fn description(mut self, desc: impl Into<String>) -> Self {
        self.description = Some(desc.into());
        self
    }

    /// Set the schema from a JSON value.
    pub fn schema(mut self, schema: Value) -> Self {
        self.schema = Some(schema);
        self
    }

    /// Set the schema from a type that implements schemars::JsonSchema.
    pub fn schema_from<T: schemars::JsonSchema>(mut self) -> Self {
        let schema = schemars::schema_for!(T);
        self.schema = Some(serde_json::to_value(schema).unwrap_or_default());
        self
    }

    /// Build the tool with the given handler.
    pub fn handler<H: ToolHandler + 'static>(self, handler: H) -> Tool {
        Tool::new(
            self.name,
            self.description.unwrap_or_default(),
            self.schema
                .unwrap_or_else(|| serde_json::json!({"type": "object"})),
            handler,
        )
    }

    /// Build the tool with a closure handler.
    pub fn handler_fn<F, Fut>(self, f: F) -> Tool
    where
        F: Fn(Value) -> Fut + Send + Sync + 'static,
        Fut: std::future::Future<Output = Result<Value>> + Send + 'static,
    {
        self.handler(FnHandler(f))
    }
}

/// Wrapper for closure handlers.
struct FnHandler<F>(F);

#[async_trait]
impl<F, Fut> ToolHandler for FnHandler<F>
where
    F: Fn(Value) -> Fut + Send + Sync,
    Fut: std::future::Future<Output = Result<Value>> + Send,
{
    async fn handle(&self, input: Value) -> Result<Value> {
        (self.0)(input).await
    }
}
