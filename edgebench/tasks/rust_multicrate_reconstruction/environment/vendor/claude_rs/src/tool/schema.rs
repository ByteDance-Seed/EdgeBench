//! JSON Schema helpers for tool definitions.

use serde_json::{Value, json};

/// Builder for JSON Schema objects.
///
/// This is a namespace struct providing static methods for building JSON schemas.
/// Use `JsonSchema::object()`, `JsonSchema::string()`, etc. to create schema builders.
#[derive(Debug, Clone, Default)]
pub struct JsonSchema;

impl JsonSchema {
    /// Create an object schema.
    pub fn object() -> ObjectSchemaBuilder {
        ObjectSchemaBuilder::new()
    }

    /// Create a string schema.
    pub fn string() -> PrimitiveSchemaBuilder {
        PrimitiveSchemaBuilder::new("string")
    }

    /// Create an integer schema.
    pub fn integer() -> PrimitiveSchemaBuilder {
        PrimitiveSchemaBuilder::new("integer")
    }

    /// Create a number schema.
    pub fn number() -> PrimitiveSchemaBuilder {
        PrimitiveSchemaBuilder::new("number")
    }

    /// Create a boolean schema.
    pub fn boolean() -> PrimitiveSchemaBuilder {
        PrimitiveSchemaBuilder::new("boolean")
    }

    /// Create an array schema.
    pub fn array(items: Value) -> Value {
        json!({
            "type": "array",
            "items": items
        })
    }

    /// Create an enum schema.
    pub fn enum_values(values: &[&str]) -> Value {
        json!({
            "type": "string",
            "enum": values
        })
    }
}

/// Builder for object schemas.
#[derive(Debug, Clone, Default)]
pub struct ObjectSchemaBuilder {
    properties: serde_json::Map<String, Value>,
    required: Vec<String>,
    description: Option<String>,
}

impl ObjectSchemaBuilder {
    /// Create a new object schema builder.
    pub fn new() -> Self {
        Self::default()
    }

    /// Add a required property.
    pub fn property(mut self, name: &str, schema: Value) -> Self {
        self.properties.insert(name.to_string(), schema);
        self.required.push(name.to_string());
        self
    }

    /// Add an optional property.
    pub fn optional_property(mut self, name: &str, schema: Value) -> Self {
        self.properties.insert(name.to_string(), schema);
        self
    }

    /// Set the description.
    pub fn description(mut self, desc: &str) -> Self {
        self.description = Some(desc.to_string());
        self
    }

    /// Build the schema.
    pub fn build(self) -> Value {
        let mut schema = json!({
            "type": "object",
            "properties": self.properties,
        });

        if !self.required.is_empty() {
            schema["required"] = json!(self.required);
        }

        if let Some(desc) = self.description {
            schema["description"] = json!(desc);
        }

        schema
    }
}

/// Builder for primitive type schemas.
#[derive(Debug, Clone)]
pub struct PrimitiveSchemaBuilder {
    type_name: String,
    description: Option<String>,
    default: Option<Value>,
    enum_values: Option<Vec<String>>,
    minimum: Option<f64>,
    maximum: Option<f64>,
    min_length: Option<u64>,
    max_length: Option<u64>,
    pattern: Option<String>,
}

impl PrimitiveSchemaBuilder {
    /// Create a new primitive schema builder.
    pub fn new(type_name: &str) -> Self {
        Self {
            type_name: type_name.to_string(),
            description: None,
            default: None,
            enum_values: None,
            minimum: None,
            maximum: None,
            min_length: None,
            max_length: None,
            pattern: None,
        }
    }

    /// Set the description.
    pub fn description(mut self, desc: &str) -> Self {
        self.description = Some(desc.to_string());
        self
    }

    /// Set the default value.
    pub fn default(mut self, value: Value) -> Self {
        self.default = Some(value);
        self
    }

    /// Set enum values (for strings).
    pub fn enum_values(mut self, values: &[&str]) -> Self {
        self.enum_values = Some(values.iter().map(|s| s.to_string()).collect());
        self
    }

    /// Set minimum value (for numbers).
    pub fn minimum(mut self, min: f64) -> Self {
        self.minimum = Some(min);
        self
    }

    /// Set maximum value (for numbers).
    pub fn maximum(mut self, max: f64) -> Self {
        self.maximum = Some(max);
        self
    }

    /// Set minimum length (for strings).
    pub fn min_length(mut self, len: u64) -> Self {
        self.min_length = Some(len);
        self
    }

    /// Set maximum length (for strings).
    pub fn max_length(mut self, len: u64) -> Self {
        self.max_length = Some(len);
        self
    }

    /// Set pattern (for strings).
    pub fn pattern(mut self, pattern: &str) -> Self {
        self.pattern = Some(pattern.to_string());
        self
    }

    /// Build the schema.
    pub fn build(self) -> Value {
        let mut schema = json!({
            "type": self.type_name
        });

        if let Some(desc) = self.description {
            schema["description"] = json!(desc);
        }
        if let Some(default) = self.default {
            schema["default"] = default;
        }
        if let Some(values) = self.enum_values {
            schema["enum"] = json!(values);
        }
        if let Some(min) = self.minimum {
            schema["minimum"] = json!(min);
        }
        if let Some(max) = self.maximum {
            schema["maximum"] = json!(max);
        }
        if let Some(len) = self.min_length {
            schema["minLength"] = json!(len);
        }
        if let Some(len) = self.max_length {
            schema["maxLength"] = json!(len);
        }
        if let Some(pattern) = self.pattern {
            schema["pattern"] = json!(pattern);
        }

        schema
    }
}
