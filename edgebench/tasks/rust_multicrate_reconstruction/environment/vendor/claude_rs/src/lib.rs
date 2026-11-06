//! # claude_rs
//!
//! Pure Rust SDK for Claude Code CLI.
//!
//! This library provides a native Rust interface to communicate with the Claude CLI,
//! supporting streaming messages, tools, hooks, and session management.
//!
//! ## Quick Start
//!
//! ```rust,no_run
//! use claude_rs::{query, QueryOptions};
//! use futures::StreamExt;
//!
//! #[tokio::main]
//! async fn main() -> claude_rs::Result<()> {
//!     let mut stream = query("What is 2 + 2?", QueryOptions::default())?;
//!
//!     while let Some(msg) = stream.next().await {
//!         match msg? {
//!             claude_rs::Message::Assistant(a) => println!("{}", a.text()),
//!             claude_rs::Message::Result(r) => {
//!                 println!("Done! Cost: ${:.4}", r.total_cost_usd.unwrap_or(0.0));
//!             }
//!             _ => {}
//!         }
//!     }
//!     Ok(())
//! }
//! ```
//!
//! ## Features
//!
//! - **Streaming**: Lazy async streams for real-time message consumption
//! - **Tools**: Define custom tools with JSON Schema validation
//! - **Hooks**: Intercept tool usage with pre/post hooks
//! - **Sessions**: Multi-turn conversations with session management
//! - **MCP**: Model Context Protocol support via the official rmcp SDK
//!
//! ## Known Limitations
//!
//! - **Message Size**: Very large messages (over ~3MB) may fail or timeout. The CLI
//!   has internal limits on message processing. If you need to send large amounts of
//!   data, consider chunking it into smaller messages or using file-based approaches.
//!
//! - **Concurrent Queries**: Each `Query` spawns its own CLI process. Running many
//!   concurrent queries can be resource-intensive.
//!
//! - **Session Persistence**: Sessions are persisted by the CLI but session IDs must
//!   be valid UUIDs. One-shot queries do not create persistent sessions.

pub mod cli;
pub mod error;
pub mod hook;
pub mod mcp;
pub mod message;
pub mod options;
mod protocol;
pub mod query;
pub mod session;
pub mod testing;
pub mod tool;

// Re-exports for convenience
pub use error::{Error, Result};
pub use hook::{Hook, HookEvent, HookHandler};
pub use message::{
    AccountInfo, McpConnectionStatus, McpServerInfo, McpServerStatus, Message, ModelInfo,
    SlashCommand,
};
pub use options::{
    AgentDefinition, CanUseToolRequest, PermissionBehavior, PermissionDestination, PermissionMode,
    PermissionResult, PermissionRule, PermissionUpdate, PluginConfig, QueryOptions,
    SandboxIgnoreViolations, SandboxNetworkConfig, SandboxSettings, SettingSource, SystemPrompt,
};
pub use query::Query;
pub use session::Session;
pub use tool::{Tool, ToolHandler};

use futures::Stream;
use std::pin::Pin;

/// Type alias for the message stream returned by query functions
pub type MessageStream = Pin<Box<dyn Stream<Item = Result<Message>> + Send>>;

/// Execute a one-shot query and return a stream of messages.
///
/// This is the primary entry point for interacting with Claude.
/// The returned stream yields messages as they arrive from the CLI.
///
/// # Example
///
/// ```rust,no_run
/// use claude_rs::{query, QueryOptions, Message};
/// use futures::StreamExt;
///
/// # async fn example() -> claude_rs::Result<()> {
/// let mut stream = query("Hello!", QueryOptions::default())?;
/// while let Some(msg) = stream.next().await {
///     if let Message::Assistant(a) = msg? {
///         println!("{}", a.text());
///     }
/// }
/// # Ok(())
/// # }
/// ```
pub fn query(prompt: &str, options: QueryOptions) -> Result<MessageStream> {
    query::start_query_with_prompt(prompt, options)
}

/// Execute a one-shot query and wait for the final result.
///
/// This is a convenience function that collects all messages and returns
/// the final `Result` message. Use this when you only care about the
/// final outcome, not intermediate streaming messages.
///
/// # Example
///
/// ```rust,no_run
/// use claude_rs::{prompt, QueryOptions};
///
/// # async fn example() -> claude_rs::Result<()> {
/// let result = prompt("What is 2 + 2?", QueryOptions::default()).await?;
/// println!("Answer: {}", result.result.unwrap_or_default());
/// # Ok(())
/// # }
/// ```
pub async fn prompt(prompt_text: &str, options: QueryOptions) -> Result<message::ResultMessage> {
    query::prompt(prompt_text, options).await
}

/// Alias for [`prompt`] - execute a one-shot query and wait for result.
pub async fn ask(prompt_text: &str, options: QueryOptions) -> Result<message::ResultMessage> {
    prompt(prompt_text, options).await
}

/// Start a streaming input query.
///
/// This returns a [`Query`] handle that allows sending multiple messages
/// to an ongoing conversation. Use this for multi-turn conversations
/// where you need to send follow-up messages.
///
/// # Example
///
/// ```rust,no_run
/// use claude_rs::{start_query, QueryOptions};
///
/// # async fn example() -> claude_rs::Result<()> {
/// let mut query = start_query(QueryOptions::default())?;
/// query.send_message("Hello!").await?;
/// // ... process responses ...
/// query.send_message("Follow up question").await?;
/// query.finish_input()?;
/// # Ok(())
/// # }
/// ```
pub fn start_query(options: QueryOptions) -> Result<Query> {
    query::start_query(options)
}

/// Resume an existing session by ID.
///
/// Use this to continue a conversation from a previous session.
/// The session ID can be obtained from any message's `session_id` field.
///
/// # Example
///
/// ```rust,no_run
/// use claude_rs::{resume_session, QueryOptions};
///
/// # async fn example() -> claude_rs::Result<()> {
/// let query = resume_session("session-id-here", QueryOptions::default())?;
/// # Ok(())
/// # }
/// ```
pub fn resume_session(session_id: &str, options: QueryOptions) -> Result<Query> {
    query::resume_session(session_id, options)
}

/// Execute a query with automatic resource cleanup.
///
/// The provided closure receives a [`Query`] handle and the query
/// is automatically closed when the closure returns.
///
/// # Example
///
/// ```rust,no_run
/// use claude_rs::{with_query, QueryOptions};
///
/// # async fn example() -> claude_rs::Result<()> {
/// let result = with_query(QueryOptions::default(), |mut query| async move {
///     query.send_message("Hello!").await?;
///     query.finish_input()?;
///     // Query is automatically closed here
///     Ok(())
/// }).await?;
/// # Ok(())
/// # }
/// ```
pub async fn with_query<F, Fut, T>(options: QueryOptions, f: F) -> Result<T>
where
    F: FnOnce(Query) -> Fut,
    Fut: std::future::Future<Output = Result<T>>,
{
    let query = start_query(options)?;
    // Query is dropped here, triggering cleanup
    f(query).await
}

/// Create a managed session for multi-turn conversations.
///
/// Sessions provide a higher-level API for multi-turn conversations
/// with automatic message accumulation and await helpers.
///
/// # Example
///
/// ```rust,no_run
/// use claude_rs::{session, QueryOptions};
///
/// # async fn example() -> claude_rs::Result<()> {
/// session(QueryOptions::default(), |mut sess| async move {
///     sess.send("What is 2 + 2?").await?;
///     let response = sess.await_response(None).await?;
///     println!("Got: {:?}", response);
///     Ok(())
/// }).await?;
/// # Ok(())
/// # }
/// ```
pub async fn session<F, Fut, T>(options: QueryOptions, f: F) -> Result<T>
where
    F: FnOnce(Session) -> Fut,
    Fut: std::future::Future<Output = Result<T>>,
{
    let sess = Session::new(options)?;
    f(sess).await
}
