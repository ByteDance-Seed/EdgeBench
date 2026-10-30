//! Tool handler trait.

use crate::error::Result;
use async_trait::async_trait;
use serde_json::Value;

/// Trait for tool execution handlers.
///
/// Implement this trait to define custom tool behavior.
///
/// # Example
///
/// ```rust
/// use claude_rs::{ToolHandler, Result};
/// use async_trait::async_trait;
/// use serde_json::{Value, json};
///
/// struct WeatherTool;
///
/// #[async_trait]
/// impl ToolHandler for WeatherTool {
///     async fn handle(&self, input: Value) -> Result<Value> {
///         let city = input["city"].as_str().unwrap_or("unknown");
///         Ok(json!({
///             "temperature": 72,
///             "city": city,
///             "conditions": "sunny"
///         }))
///     }
/// }
/// ```
#[async_trait]
pub trait ToolHandler: Send + Sync {
    /// Execute the tool with the given input.
    ///
    /// # Arguments
    /// * `input` - JSON input matching the tool's schema
    ///
    /// # Returns
    /// The tool's output as a JSON value, or an error.
    async fn handle(&self, input: Value) -> Result<Value>;
}

/// A simple handler that always returns a fixed value.
pub struct ConstHandler(pub Value);

#[async_trait]
impl ToolHandler for ConstHandler {
    async fn handle(&self, _input: Value) -> Result<Value> {
        Ok(self.0.clone())
    }
}

/// A handler that echoes its input.
pub struct EchoHandler;

#[async_trait]
impl ToolHandler for EchoHandler {
    async fn handle(&self, input: Value) -> Result<Value> {
        Ok(input)
    }
}
