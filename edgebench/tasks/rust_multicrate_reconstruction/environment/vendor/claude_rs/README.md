# Agent SDK Reference - Rust

Complete API reference for the Rust Agent SDK (`claude_rs`), including all functions, types, and interfaces.

---

## Installation

Add to your `Cargo.toml`:

```toml
[dependencies]
claude_rs = "0.1"
tokio = { version = "1", features = ["full"] }
futures = "0.3"
```

## Quick Start

```rust
use claude_rs::{query, QueryOptions, Message};
use futures::StreamExt;

#[tokio::main]
async fn main() -> claude_rs::Result<()> {
    let mut stream = query("What is 2 + 2?", QueryOptions::default())?;

    while let Some(msg) = stream.next().await {
        match msg? {
            Message::Assistant(a) => println!("{}", a.text()),
            Message::Result(r) => {
                println!("Done! Cost: ${:.4}", r.total_cost_usd.unwrap_or(0.0));
            }
            _ => {}
        }
    }
    Ok(())
}
```

## Functions

### `query()`

The primary function for interacting with Claude Code. Returns an async stream of messages.

```rust
pub fn query(prompt: &str, options: QueryOptions) -> Result<MessageStream>
```

#### Parameters

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `prompt` | `&str` | The input prompt text |
| `options` | [`QueryOptions`](#queryoptions) | Configuration options |

#### Returns

Returns a [`MessageStream`](#messagestream) (`Pin<Box<dyn Stream<Item = Result<Message>> + Send>>`).

#### Example

```rust
use claude_rs::{query, QueryOptions, Message};
use futures::StreamExt;

let mut stream = query("Hello!", QueryOptions::default())?;
while let Some(msg) = stream.next().await {
    if let Message::Assistant(a) = msg? {
        println!("{}", a.text());
    }
}
```

---

### `prompt()`

Execute a one-shot query and wait for the final result. Convenience function when you only need the final outcome.

```rust
pub async fn prompt(prompt_text: &str, options: QueryOptions) -> Result<ResultMessage>
```

#### Parameters

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `prompt_text` | `&str` | The input prompt text |
| `options` | [`QueryOptions`](#queryoptions) | Configuration options |

#### Returns

Returns a [`ResultMessage`](#resultmessage) containing the final result.

#### Example

```rust
use claude_rs::{prompt, QueryOptions};

let result = prompt("What is 2 + 2?", QueryOptions::default()).await?;
println!("Answer: {}", result.text());
println!("Cost: ${:.4}", result.total_cost_usd.unwrap_or(0.0));
```

---

### `ask()`

Alias for [`prompt()`](#prompt) - execute a one-shot query and wait for result.

```rust
pub async fn ask(prompt_text: &str, options: QueryOptions) -> Result<ResultMessage>
```

---

### `start_query()`

Start a streaming input query for multi-turn conversations.

```rust
pub fn start_query(options: QueryOptions) -> Result<Query>
```

#### Parameters

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `options` | [`QueryOptions`](#queryoptions) | Configuration options |

#### Returns

Returns a [`Query`](#query-1) handle for sending messages and receiving responses.

#### Example

```rust
use claude_rs::{start_query, QueryOptions, Message};

let mut query = start_query(QueryOptions::new().max_turns(3))?;

query.send_message("Hello!").await?;

while let Some(msg) = query.recv().await {
    match msg? {
        Message::Assistant(a) => println!("Claude: {}", a.text()),
        Message::Result(r) => {
            println!("Done!");
            break;
        }
        _ => {}
    }
}
```

---

### `resume_session()`

Resume an existing session by ID.

```rust
pub fn resume_session(session_id: &str, options: QueryOptions) -> Result<Query>
```

#### Parameters

| Parameter | Type | Description |
| :-------- | :--- | :---------- |
| `session_id` | `&str` | The session ID (must be a valid UUID) |
| `options` | [`QueryOptions`](#queryoptions) | Configuration options |

#### Returns

Returns a [`Query`](#query-1) handle to continue the session.

#### Errors

Returns an error if:
- The session ID is not a valid UUID format
- `options.max_turns` is set to 0
- `options.max_budget_usd` is set to a non-positive value

#### Example

```rust
use claude_rs::{resume_session, QueryOptions};

let query = resume_session(
    "550e8400-e29b-41d4-a716-446655440000",
    QueryOptions::default()
)?;
```

---

### `with_query()`

Execute a query with automatic resource cleanup.

```rust
pub async fn with_query<F, Fut, T>(options: QueryOptions, f: F) -> Result<T>
where
    F: FnOnce(Query) -> Fut,
    Fut: Future<Output = Result<T>>,
```

#### Example

```rust
use claude_rs::{with_query, QueryOptions};

let result = with_query(QueryOptions::default(), |mut query| async move {
    query.send_message("Hello!").await?;
    query.finish_input()?;
    // Query is automatically closed here
    Ok(())
}).await?;
```

---

### `session()`

Create a managed session for multi-turn conversations with automatic message accumulation.

```rust
pub async fn session<F, Fut, T>(options: QueryOptions, f: F) -> Result<T>
where
    F: FnOnce(Session) -> Fut,
    Fut: Future<Output = Result<T>>,
```

#### Example

```rust
use claude_rs::{session, QueryOptions};

session(QueryOptions::default(), |mut sess| async move {
    sess.send("What is 2 + 2?").await?;
    let response = sess.await_response(None).await?;
    println!("Got: {:?}", response);
    Ok(())
}).await?;
```

---

## Types

### `QueryOptions`

Configuration options for queries. Uses the builder pattern for ergonomic construction.

```rust
pub struct QueryOptions {
    pub model: Option<String>,
    pub system_prompt: Option<SystemPrompt>,
    pub max_turns: Option<u32>,
    pub max_thinking_tokens: Option<u32>,
    pub max_budget_usd: Option<f64>,
    pub cwd: Option<PathBuf>,
    pub permission_mode: Option<PermissionMode>,
    pub tools: Vec<Tool>,
    pub hooks: Vec<Hook>,
    pub allowed_tools: Vec<String>,
    pub disallowed_tools: Vec<String>,
    // ... and more
}
```

| Property | Type | Default | Description |
| :------- | :--- | :------ | :---------- |
| `model` | `Option<String>` | `None` | Claude model to use (e.g., "claude-sonnet-4-5-20250929") |
| `system_prompt` | `Option<SystemPrompt>` | `None` | System prompt configuration |
| `max_turns` | `Option<u32>` | `None` | Maximum conversation turns (must be >= 1) |
| `max_thinking_tokens` | `Option<u32>` | `None` | Maximum tokens for extended thinking |
| `max_budget_usd` | `Option<f64>` | `None` | Maximum budget in USD (must be > 0) |
| `cwd` | `Option<PathBuf>` | `None` | Working directory for the query |
| `permission_mode` | `Option<PermissionMode>` | `None` | Permission mode for tool execution |
| `dangerously_skip_permissions` | `bool` | `false` | Skip all permission checks (dangerous!) |
| `allow_dangerously_skip_permissions` | `bool` | `false` | Safety flag required for bypass mode |
| `can_use_tool` | `Option<CanUseToolCallback>` | `None` | Custom permission callback |
| `tools` | `Vec<Tool>` | `[]` | Custom tools to register |
| `hooks` | `Vec<Hook>` | `[]` | Hooks for intercepting events |
| `allowed_tools` | `Vec<String>` | `[]` | Tools allowed for this query |
| `disallowed_tools` | `Vec<String>` | `[]` | Tools disallowed for this query |
| `mcp_config` | `Option<PathBuf>` | `None` | Path to MCP config file |
| `continue_session` | `bool` | `false` | Continue the last session |
| `resume` | `Option<String>` | `None` | Resume a specific session by ID |
| `resume_at` | `Option<String>` | `None` | Resume up to a specific message UUID |
| `fork_session` | `bool` | `false` | Fork the session on resume |
| `persist_session` | `Option<bool>` | `None` | Persist session to disk |
| `enable_file_checkpointing` | `bool` | `false` | Enable file checkpointing for rewind |
| `include_partial_messages` | `bool` | `false` | Include partial/streaming messages |
| `output_schema` | `Option<Value>` | `None` | JSON schema for structured output |
| `agents` | `Option<HashMap<String, AgentDefinition>>` | `None` | Custom subagent definitions |
| `plugins` | `Option<Vec<PluginConfig>>` | `None` | Plugin configurations |
| `sandbox` | `Option<SandboxSettings>` | `None` | Sandbox configuration |
| `setting_sources` | `Vec<SettingSource>` | `[]` | Setting sources to load |
| `additional_directories` | `Vec<PathBuf>` | `[]` | Additional directories to allow |
| `betas` | `Vec<String>` | `[]` | Beta features to enable |
| `env` | `Option<HashMap<String, String>>` | `None` | Environment variables |
| `mock` | `bool` | `false` | Enable mock mode (testing) |
| `include_replays` | `bool` | `false` | Include replay messages |

#### Builder Methods

```rust
// Create with defaults
let options = QueryOptions::new();

// Chain builder methods
let options = QueryOptions::new()
    .model("claude-sonnet-4-5-20250929")
    .max_turns(5)
    .max_budget_usd(0.50)
    .cwd("/path/to/project")
    .permission_mode(PermissionMode::AcceptEdits)
    .tool(my_tool)
    .hook(my_hook)
    .allow_tool("Read")
    .disallow_tool("Bash")
    .resume_session("session-id")
    .continue_last()
    .fork()
    .include_partials()
    .output_schema(schema)
    .beta("context-1m-2025-08-07")
    .env_var("MY_VAR", "value")
    .sandbox(SandboxSettings::default())
    .agent("reviewer", agent_def);
```

---

### `Query`

Handle to an active query for streaming input mode.

```rust
pub struct Query {
    // Internal fields
}
```

#### Methods

| Method | Description |
| :----- | :---------- |
| `send_message(&mut self, message: &str) -> Result<()>` | Send a user message |
| `finish_input(&mut self) -> Result<()>` | Signal end of input |
| `interrupt(&mut self) -> Result<()>` | Interrupt the query |
| `close(self) -> Result<()>` | Close the query |
| `recv(&mut self) -> Option<Result<Message>>` | Receive the next message |
| `recv_raw(&mut self) -> Option<Result<Message>>` | Receive raw messages (no processing) |
| `stream(self) -> MessageStream` | Convert to a message stream |
| `set_model(&mut self, model: &str) -> Result<()>` | Change the model (streaming mode only) |
| `clear_model(&mut self) -> Result<()>` | Clear model override |
| `set_permission_mode(&mut self, mode: PermissionMode) -> Result<()>` | Change permission mode |
| `set_max_thinking_tokens(&mut self, tokens: u32) -> Result<()>` | Set max thinking tokens |
| `clear_max_thinking_tokens(&mut self) -> Result<()>` | Clear thinking token limit |
| `supported_commands(&mut self) -> Result<Vec<SlashCommand>>` | Get available slash commands |
| `supported_models(&mut self) -> Result<Vec<ModelInfo>>` | Get available models |
| `mcp_server_status(&mut self) -> Result<Vec<McpServerStatus>>` | Get MCP server status |
| `account_info(&mut self) -> Result<AccountInfo>` | Get account information |
| `rewind_files(&mut self, user_message_id: &str) -> Result<()>` | Rewind files to checkpoint |

#### Message Size Limits

Very large messages (over ~3MB) may fail or timeout due to CLI limitations. For large data, consider chunking into smaller messages or using file-based approaches.

#### Example

```rust
let mut query = start_query(QueryOptions::new().max_turns(3))?;

// Send messages
query.send_message("First message").await?;

// Receive responses
while let Some(msg) = query.recv().await {
    match msg? {
        Message::Assistant(a) => println!("{}", a.text()),
        Message::Result(_) => break,
        _ => {}
    }
}

// Send follow-up
query.send_message("Follow-up question").await?;

// Signal done
query.finish_input()?;
```

---

### `Session`

Managed session for multi-turn conversations with automatic message accumulation.

```rust
pub struct Session {
    // Internal fields
}
```

#### Methods

| Method | Description |
| :----- | :---------- |
| `new(options: QueryOptions) -> Result<Self>` | Create a new session |
| `resume(session_id: &str, options: QueryOptions) -> Result<Self>` | Resume an existing session |
| `send(&mut self, message: &str) -> Result<()>` | Send a message |
| `finish(&mut self) -> Result<()>` | Signal end of input |
| `interrupt(&mut self) -> Result<()>` | Interrupt the session |
| `await_response(&mut self, timeout: Option<Duration>) -> Result<Message>` | Wait for next response |
| `await_result(&mut self, timeout: Option<Duration>) -> Result<ResultMessage>` | Wait for final result |
| `responses(&self) -> &[Message]` | Get accumulated responses |
| `session_id(&self) -> Option<&str>` | Get the session ID |
| `close(self) -> Result<()>` | Close the session |

---

### `PermissionMode`

Permission mode for tool execution.

```rust
pub enum PermissionMode {
    Default,           // Ask for permission on sensitive operations
    AcceptEdits,       // Auto-accept file edits without prompting
    BypassPermissions, // Bypass all permission checks
    Plan,              // Plan mode - propose changes without executing
    DontAsk,           // Don't ask for confirmation
}
```

---

### `SystemPrompt`

System prompt configuration.

```rust
pub enum SystemPrompt {
    Text(String),    // Custom text system prompt
    Preset(String),  // Use a preset (e.g., "claude_code")
    Append(String),  // Append to default system prompt
}
```

#### Constructor Methods

```rust
SystemPrompt::text("You are a helpful assistant")
SystemPrompt::preset("claude_code")
SystemPrompt::append("Additional instructions here")
```

---

### `SettingSource`

Controls which filesystem configuration sources to load.

```rust
pub enum SettingSource {
    User,    // ~/.claude/settings.json
    Project, // .claude/settings.json
    Local,   // .claude/settings.local.json
}
```

---

### `AgentDefinition`

Configuration for a custom subagent.

```rust
pub struct AgentDefinition {
    pub description: String,              // When to use this agent
    pub prompt: String,                   // The agent's system prompt
    pub tools: Option<Vec<String>>,       // Allowed tools (inherits if omitted)
    pub disallowed_tools: Option<Vec<String>>, // Disallowed tools
    pub model: Option<String>,            // Model override ('sonnet', 'opus', 'haiku', 'inherit')
}
```

---

### `PluginConfig`

Plugin configuration.

```rust
pub enum PluginConfig {
    Local { path: String }, // Local plugin from filesystem
}
```

---

## Message Types

### `Message`

Union type of all possible messages returned by queries.

```rust
pub enum Message {
    System(SystemMessage),
    Assistant(AssistantMessage),
    User(UserMessage),
    Result(ResultMessage),
    Partial(PartialMessage),
    ToolProgress(ToolProgressMessage),
    Status(StatusMessage),
    AuthStatus(AuthStatusMessage),
    HookInput(HookInputMessage),
    HookResponse(HookResponseMessage),
    ControlRequest(ControlRequestMessage),
    ControlResponse(ControlResponseMessage),
    CompactBoundary(CompactBoundaryMessage),
}
```

#### Common Methods

| Method | Description |
| :----- | :---------- |
| `session_id(&self) -> Option<&str>` | Get the session ID |
| `uuid(&self) -> Option<&str>` | Get the message UUID |
| `is_replay(&self) -> bool` | Check if this is a replay message |
| `is_assistant(&self) -> bool` | Check if this is an assistant message |
| `is_result(&self) -> bool` | Check if this is a result message |
| `as_assistant(&self) -> Option<&AssistantMessage>` | Get as assistant message |
| `as_result(&self) -> Option<&ResultMessage>` | Get as result message |

---

### `AssistantMessage`

Assistant response message.

```rust
pub struct AssistantMessage {
    pub uuid: Option<String>,
    pub session_id: Option<String>,
    pub message: Option<MessageContent>,
    pub parent_tool_use_id: Option<String>,
    pub error: Option<Value>,
}
```

#### Methods

| Method | Description |
| :----- | :---------- |
| `text(&self) -> String` | Get all text content concatenated |
| `text_blocks(&self) -> Vec<&str>` | Get all text blocks |
| `tool_uses(&self) -> Vec<&ToolUse>` | Get all tool use blocks |
| `has_tool_use(&self) -> bool` | Check if message contains tool use |
| `thinking(&self) -> Option<&str>` | Get thinking content if present |

---

### `ResultMessage`

Final result message with usage statistics and cost information.

```rust
pub struct ResultMessage {
    pub subtype: Option<String>,           // "success", "error_max_turns", etc.
    pub uuid: Option<String>,
    pub session_id: Option<String>,
    pub duration_ms: Option<u64>,
    pub duration_api_ms: Option<u64>,
    pub is_error: Option<bool>,
    pub num_turns: Option<u32>,
    pub result: Option<String>,
    pub total_cost_usd: Option<f64>,
    pub usage: Option<Usage>,
    pub model_usage: Option<HashMap<String, ModelUsage>>,
    pub permission_denials: Option<Vec<PermissionDenial>>,
    pub structured_output: Option<Value>,
    pub errors: Option<Vec<ErrorDetail>>,
}
```

#### Methods

| Method | Description |
| :----- | :---------- |
| `is_success(&self) -> bool` | Check if this is a successful result |
| `is_max_turns(&self) -> bool` | Check if max turns was exceeded |
| `is_budget_exceeded(&self) -> bool` | Check if budget was exceeded |
| `is_execution_error(&self) -> bool` | Check if there was an execution error |
| `text(&self) -> &str` | Get the result text or empty string |
| `input_tokens(&self) -> u64` | Get total input tokens |
| `output_tokens(&self) -> u64` | Get total output tokens |

---

### `Usage`

Token usage statistics.

```rust
pub struct Usage {
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cache_creation_input_tokens: u64,
    pub cache_read_input_tokens: u64,
}
```

---

### `ModelUsage`

Per-model usage breakdown.

```rust
pub struct ModelUsage {
    pub input_tokens: u64,
    pub output_tokens: u64,
    pub cost_usd: Option<f64>,
}
```

---

### `ContentBlock`

Content blocks within messages.

```rust
pub enum ContentBlock {
    Text { text: String },
    ToolUse(ToolUse),
    ToolResult(ToolResult),
    Thinking { thinking: String },
    Image { source: ImageSource },
    RedactedThinking { data: Option<String> },
    ServerToolUse { id: String, name: String, input: Value },
    WebSearchToolUse { id: String, name: String, input: Value },
    WebSearchToolResult { tool_use_id: String, content: Value },
    McpToolResult { tool_use_id: String, content: Value },
    CitationMarker { source_id: String, citation_index: u32 },
    Container { items: Vec<ContentBlock> },
}
```

---

### `ToolUse`

Tool use request.

```rust
pub struct ToolUse {
    pub id: String,
    pub name: String,
    pub input: Value,
}
```

#### Methods

| Method | Description |
| :----- | :---------- |
| `get_input(&self, key: &str) -> Option<&Value>` | Get a specific input field |
| `input_as<T>(&self) -> Result<T, serde_json::Error>` | Deserialize input to type |

---

## Tool Types

### `Tool`

A tool that Claude can use.

```rust
pub struct Tool {
    pub name: String,
    pub description: String,
    pub schema: Value,
    // handler (internal)
}
```

#### Creating Tools

```rust
use claude_rs::{Tool, Result};
use serde_json::{json, Value};

// Using the constructor
let tool = Tool::new(
    "my_tool",
    "Does something useful",
    json!({
        "type": "object",
        "properties": {
            "input": { "type": "string" }
        },
        "required": ["input"]
    }),
    MyHandler,
);

// Using the builder
let tool = Tool::builder("my_tool")
    .description("Does something useful")
    .schema(json!({ "type": "object" }))
    .handler_fn(|input: Value| async move {
        Ok(json!({ "result": "success" }))
    });

// Using schema_from with schemars
#[derive(schemars::JsonSchema)]
struct MyInput {
    input: String,
}

let tool = Tool::builder("my_tool")
    .description("Does something useful")
    .schema_from::<MyInput>()
    .handler_fn(|input| async move {
        Ok(json!({ "result": "done" }))
    });
```

---

### `ToolHandler`

Trait for tool handlers.

```rust
#[async_trait]
pub trait ToolHandler: Send + Sync {
    async fn handle(&self, input: Value) -> Result<Value>;
}
```

---

## Hook Types

### `HookEvent`

Available hook events.

```rust
pub enum HookEvent {
    PreToolUse,        // Before a tool is used
    PostToolUse,       // After a tool is used successfully
    PostToolUseFailure,// After a tool use fails
    Notification,      // Notification from Claude
    UserPromptSubmit,  // User prompt submitted
    SessionStart,      // Session started
    SessionEnd,        // Session ended
    Stop,              // Stop requested
    SubagentStart,     // Subagent started
    SubagentStop,      // Subagent stopped
    PreCompact,        // Before context compaction
    PermissionRequest, // Permission request
}
```

---

### `Hook`

A hook for intercepting events.

```rust
pub struct Hook {
    pub event: HookEvent,
    pub matcher: Option<String>,  // Tool name filter
    pub timeout: Duration,
}
```

#### Creating Hooks

```rust
use claude_rs::{Hook, HookEvent, HookOutput};
use std::time::Duration;

// Simple hook
let hook = Hook::on(HookEvent::PreToolUse, MyHandler);

// With matcher (only for specific tool)
let hook = Hook::on(HookEvent::PreToolUse, MyHandler)
    .matcher("Bash")
    .timeout(Duration::from_secs(60));

// Using builder with closure
let hook = Hook::builder(HookEvent::PreToolUse)
    .matcher("Bash")
    .timeout(Duration::from_secs(30))
    .handler_fn(|input| async move {
        // Check tool input
        if let Some(cmd) = input.tool_input().and_then(|i| i.get("command")) {
            if cmd.as_str().map(|s| s.contains("rm -rf")).unwrap_or(false) {
                return HookOutput::deny("Dangerous command blocked");
            }
        }
        HookOutput::approve()
    });
```

---

### `HookHandler`

Trait for hook handlers.

```rust
#[async_trait]
pub trait HookHandler: Send + Sync {
    async fn handle(&self, input: HookInput) -> HookOutput;
}
```

---

### `HookInput`

Input data for hooks.

```rust
pub struct HookInput {
    pub event: String,
    pub hook_id: String,
    pub session_id: Option<String>,
    pub transcript_path: Option<String>,
    pub cwd: Option<String>,
    pub permission_mode: Option<String>,
    pub data: HookInputData,
}
```

#### Methods

| Method | Description |
| :----- | :---------- |
| `tool_name(&self) -> Option<&str>` | Get the tool name (for tool events) |
| `tool_input(&self) -> Option<&Value>` | Get the tool input (for tool events) |

---

### `HookInputData`

Event-specific hook input data.

```rust
pub enum HookInputData {
    PreToolUse { tool_name: String, tool_input: Value, tool_use_id: String },
    PostToolUse { tool_name: String, tool_input: Value, tool_response: Value, tool_use_id: String },
    PostToolUseFailure { tool_name: String, tool_input: Value, tool_use_id: String, error: Option<String>, is_interrupt: Option<bool> },
    PermissionRequest { tool_name: String, tool_input: Value, permission_suggestions: Option<Vec<PermissionSuggestion>> },
    Notification { message: String, title: Option<String> },
    SessionStart { source: Option<String> },
    SessionEnd { reason: Option<String> },
    SubagentStart { agent_id: String, agent_type: Option<String> },
    SubagentStop { agent_id: String, agent_transcript_path: Option<String>, stop_hook_active: Option<bool> },
    PreCompact { trigger: Option<String>, custom_instructions: Option<String> },
    Empty {},
}
```

---

### `HookOutput`

Output from a hook handler.

```rust
pub struct HookOutput {
    pub continue_execution: bool,
    pub suppress_output: bool,
    pub stop_reason: Option<String>,
    pub permission_decision: Option<PermissionDecision>,
    pub permission_decision_reason: Option<String>,
    pub updated_input: Option<Value>,
    pub system_message: Option<String>,
    pub reason: Option<String>,
}
```

#### Factory Methods

| Method | Description |
| :----- | :---------- |
| `HookOutput::approve()` | Approve/continue execution |
| `HookOutput::deny(reason)` | Deny tool execution |
| `HookOutput::ask()` | Ask the user |
| `HookOutput::stop(reason)` | Stop execution |
| `HookOutput::empty()` | Continue with defaults |

#### Builder Methods

```rust
HookOutput::approve()
    .with_updated_input(new_input)
    .with_system_message("Additional context")
    .suppress()
```

---

### `PermissionDecision`

Permission decision for tool use.

```rust
pub enum PermissionDecision {
    Allow, // Allow the tool use
    Deny,  // Deny the tool use
    Ask,   // Ask the user
}
```

---

## Permission Types

### `CanUseToolCallback`

Custom permission callback type.

```rust
pub type CanUseToolCallback = Arc<
    dyn Fn(CanUseToolRequest) -> Pin<Box<dyn Future<Output = PermissionResult> + Send>>
        + Send
        + Sync,
>;
```

#### Example

```rust
let options = QueryOptions::new()
    .can_use_tool(|req: CanUseToolRequest| async move {
        if req.tool_name == "Bash" {
            if let Some(cmd) = req.input.get("command").and_then(|v| v.as_str()) {
                if cmd.contains("sudo") {
                    return PermissionResult::deny("sudo commands not allowed");
                }
            }
        }
        PermissionResult::allow()
    });
```

---

### `CanUseToolRequest`

Request data for permission callback.

```rust
pub struct CanUseToolRequest {
    pub tool_name: String,
    pub input: Value,
    pub suggestions: Option<Value>,
    pub blocked_path: Option<String>,
    pub decision_reason: Option<String>,
    pub tool_use_id: String,
    pub agent_id: Option<String>,
}
```

---

### `PermissionResult`

Result of a permission check.

```rust
pub enum PermissionResult {
    Allow {
        updated_input: Option<Value>,
        updated_permissions: Option<Vec<PermissionUpdate>>,
    },
    Deny {
        message: String,
        interrupt: bool,
    },
}
```

#### Factory Methods

| Method | Description |
| :----- | :---------- |
| `PermissionResult::allow()` | Allow with no modifications |
| `PermissionResult::allow_with_input(input)` | Allow with updated input |
| `PermissionResult::deny(message)` | Deny with message |
| `PermissionResult::deny_and_interrupt(message)` | Deny and interrupt execution |

---

### `PermissionUpdate`

Operations for updating permissions.

```rust
pub enum PermissionUpdate {
    AddRules { rules: Vec<PermissionRule>, behavior: PermissionBehavior, destination: PermissionDestination },
    ReplaceRules { rules: Vec<PermissionRule>, behavior: PermissionBehavior, destination: PermissionDestination },
    RemoveRules { rules: Vec<PermissionRule>, behavior: PermissionBehavior, destination: PermissionDestination },
    SetMode { mode: PermissionMode, destination: PermissionDestination },
    AddDirectories { directories: Vec<String>, destination: PermissionDestination },
    RemoveDirectories { directories: Vec<String>, destination: PermissionDestination },
}
```

---

### `PermissionBehavior`

```rust
pub enum PermissionBehavior {
    Allow,
    Deny,
    Ask,
}
```

---

### `PermissionDestination`

```rust
pub enum PermissionDestination {
    UserSettings,    // Global user settings
    ProjectSettings, // Per-directory project settings
    LocalSettings,   // Gitignored local settings
    Session,         // Current session only
    CliArg,          // CLI argument scope
}
```

---

## Sandbox Configuration

### `SandboxSettings`

Configuration for sandbox behavior.

```rust
pub struct SandboxSettings {
    pub enabled: Option<bool>,
    pub auto_allow_bash_if_sandboxed: Option<bool>,
    pub network: Option<SandboxNetworkConfig>,
    pub ignore_violations: Option<SandboxIgnoreViolations>,
}
```

| Property | Type | Default | Description |
| :------- | :--- | :------ | :---------- |
| `enabled` | `Option<bool>` | `None` | Enable sandbox mode |
| `auto_allow_bash_if_sandboxed` | `Option<bool>` | `None` | Auto-approve bash when sandboxed |
| `network` | `Option<SandboxNetworkConfig>` | `None` | Network sandbox config |
| `ignore_violations` | `Option<SandboxIgnoreViolations>` | `None` | Violations to ignore |

---

### `SandboxNetworkConfig`

Network-specific sandbox configuration.

```rust
pub struct SandboxNetworkConfig {
    pub allow_local_binding: Option<bool>,
    pub allow_unix_sockets: Option<Vec<String>>,
}
```

---

### `SandboxIgnoreViolations`

Configuration for ignoring sandbox violations.

```rust
pub struct SandboxIgnoreViolations {
    pub paths: Option<Vec<String>>,
}
```

---

## Other Types

### `MessageStream`

Type alias for the message stream returned by query functions.

```rust
pub type MessageStream = Pin<Box<dyn Stream<Item = Result<Message>> + Send>>;
```

---

### `SlashCommand`

Information about an available slash command.

```rust
pub struct SlashCommand {
    pub name: String,
    pub description: String,
    // Additional fields...
}
```

---

### `ModelInfo`

Information about an available model.

```rust
pub struct ModelInfo {
    pub value: String,
    pub display_name: Option<String>,
    // Additional fields...
}
```

---

### `McpServerStatus`

Status of a connected MCP server.

```rust
pub struct McpServerStatus {
    pub name: String,
    pub status: McpConnectionStatus,
    pub server_info: Option<McpServerInfo>,
}
```

---

### `AccountInfo`

Account information for the authenticated user.

```rust
pub struct AccountInfo {
    pub email: Option<String>,
    pub organization: Option<String>,
    // Additional fields...
}
```

---

## Error Types

### `Error`

All errors that can occur when using claude_rs.

```rust
pub enum Error {
    Cli(String),              // CLI process error
    Parse(serde_json::Error), // JSON parsing error
    Io(std::io::Error),       // I/O error
    ExecutableNotFound,       // Claude CLI not found
    ToolValidation(String),   // Tool validation failed
    ToolExecution(String),    // Tool execution failed
    Hook(String),             // Hook execution failed
    Interrupted,              // Query interrupted
    Timeout(String),          // Operation timed out
    MaxTurnsExceeded,         // Max turns exceeded
    BudgetExceeded(f64),      // Budget exceeded
    PermissionDenied(String), // Permission denied
    Mcp(String),              // MCP protocol error
    SessionNotFound(String),  // Session not found
    StreamEnded,              // Stream ended unexpectedly
    InvalidOption(String),    // Invalid option/config
    QueryError(String),       // Query returned error
    Runtime(String),          // Runtime control error
}
```

---

### `Result<T>`

Type alias for results using the [`Error`](#error) type.

```rust
pub type Result<T> = std::result::Result<T, Error>;
```

---

## Known Limitations

- **Message Size**: Very large messages (over ~3MB) may fail or timeout. The CLI has internal limits on message processing. If you need to send large amounts of data, consider chunking into smaller messages or using file-based approaches.

- **Concurrent Queries**: Each `Query` spawns its own CLI process. Running many concurrent queries can be resource-intensive.

- **Session Persistence**: Sessions are persisted by the CLI but session IDs must be valid UUIDs. One-shot queries do not create persistent sessions.

---

## See Also

- [TypeScript SDK Reference](https://docs.anthropic.com/en/agent-sdk/typescript) - TypeScript SDK documentation
- [Python SDK Reference](https://docs.anthropic.com/en/agent-sdk/python) - Python SDK documentation
- [Claude Code CLI Reference](https://code.claude.com/docs/en/cli-reference) - Command-line interface
