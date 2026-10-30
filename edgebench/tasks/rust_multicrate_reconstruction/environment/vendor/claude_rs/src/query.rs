//! Query execution and control.

mod runtime_control;

use crate::MessageStream;
use crate::cli::{Cli, CommandBuilder};
use crate::error::{Error, Result};
use crate::hook::{Hook, HookInput, HookOutput};
use crate::message::{
    ControlRequest, ControlRequestMessage, HookCallbackInput, Message, ResultMessage,
};
use crate::options::{CanUseToolCallback, CanUseToolRequest, PermissionResult, QueryOptions};
use crate::protocol::{HookJsonResponse, PermissionJsonResponse};

use futures::StreamExt;
use serde_json::{Value, json};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::{RwLock, mpsc, oneshot};
use tokio_stream::wrappers::ReceiverStream;
use uuid::Uuid;

/// Thread-safe hook callback registry.
#[derive(Clone)]
pub struct HookRegistry {
    callbacks: Arc<RwLock<HashMap<String, Hook>>>,
    next_id: Arc<std::sync::atomic::AtomicU32>,
}

impl HookRegistry {
    pub fn new() -> Self {
        Self {
            callbacks: Arc::new(RwLock::new(HashMap::new())),
            next_id: Arc::new(std::sync::atomic::AtomicU32::new(0)),
        }
    }

    pub fn register_sync(&self, hook: Hook) -> String {
        let id = self
            .next_id
            .fetch_add(1, std::sync::atomic::Ordering::SeqCst);
        let callback_id = format!("hook_{id}");

        // Use blocking write for sync context
        let mut callbacks = futures::executor::block_on(self.callbacks.write());
        callbacks.insert(callback_id.clone(), hook);
        callback_id
    }

    pub async fn get(&self, callback_id: &str) -> Option<Hook> {
        self.callbacks.read().await.get(callback_id).cloned()
    }

    /// Get all registered callbacks (blocking).
    pub fn callbacks_blocking(&self) -> Vec<(String, Hook)> {
        let callbacks = futures::executor::block_on(self.callbacks.read());
        callbacks
            .iter()
            .map(|(k, v)| (k.clone(), v.clone()))
            .collect()
    }

    pub async fn execute_callback(&self, callback_id: &str, input: &HookCallbackInput) -> Value {
        let hook = match self.get(callback_id).await {
            Some(h) => h,
            None => {
                return json!({
                    "continue": true,
                    "reason": format!("No callback found for ID: {}", callback_id)
                });
            }
        };

        let hook_input = HookInput {
            event: input.hook_event_name.clone(),
            hook_id: callback_id.to_string(),
            session_id: input.session_id.clone(),
            transcript_path: input.transcript_path.clone(),
            cwd: input.cwd.clone(),
            permission_mode: input.permission_mode.clone(),
            data: crate::hook::input::HookInputData::PreToolUse {
                tool_name: input.tool_name.clone().unwrap_or_default(),
                tool_input: input.tool_input.clone().unwrap_or(json!({})),
                tool_use_id: input.tool_use_id.clone().unwrap_or_default(),
            },
        };

        let output = hook.execute(hook_input).await;
        hook_output_to_json(&output, &input.hook_event_name)
    }
}

impl Default for HookRegistry {
    fn default() -> Self {
        Self::new()
    }
}

/// Pending control request awaiting response.
struct PendingRequest {
    tx: oneshot::Sender<Value>,
}

/// Handle to an active query.
pub struct Query {
    cli: Cli,
    options: QueryOptions,
    hook_registry: HookRegistry,
    can_use_tool: Option<CanUseToolCallback>,
    pending_requests: Arc<RwLock<HashMap<String, PendingRequest>>>,
    initialized: bool,
    /// Whether finish_input() has been called
    input_finished: bool,
    /// Number of Result messages received (turns completed)
    turns_completed: u32,
}

impl Query {
    pub(crate) fn new(cli: Cli, options: QueryOptions) -> Self {
        let registry = HookRegistry::new();

        // Pre-register all hooks
        for hook in &options.hooks {
            registry.register_sync(hook.clone());
        }

        let can_use_tool = options.can_use_tool.clone();

        Self {
            cli,
            options,
            hook_registry: registry,
            can_use_tool,
            pending_requests: Arc::new(RwLock::new(HashMap::new())),
            initialized: false,
            input_finished: false,
            turns_completed: 0,
        }
    }

    /// Build hooks configuration for CLI initialization.
    fn build_hooks_config(&self) -> Option<Value> {
        if self.options.hooks.is_empty() {
            return None;
        }

        let mut config: HashMap<String, Vec<Value>> = HashMap::new();

        for (callback_id, hook) in self.hook_registry.callbacks_blocking() {
            let event_name = hook.event.to_sdk_string();
            let matcher_config = json!({
                "matcher": hook.matcher.as_deref().unwrap_or("*"),
                "hookCallbackIds": [callback_id],
                "timeout": 60
            });

            config
                .entry(event_name.to_string())
                .or_default()
                .push(matcher_config);
        }

        if config.is_empty() {
            None
        } else {
            Some(json!(config))
        }
    }

    /// Send initialization with hooks config and wait for response.
    ///
    /// In streaming mode, the initialize request must be sent and acknowledged
    /// before any user messages. This is required by the Claude CLI's control protocol.
    ///
    /// In one-shot mode (non-streaming), initialization is skipped as there's
    /// no bidirectional communication channel.
    async fn send_initialize(&mut self) -> Result<()> {
        if self.initialized {
            return Ok(());
        }

        // Skip initialization in one-shot mode - no stdin to write to
        if !self.options.streaming_input {
            self.initialized = true;
            return Ok(());
        }

        let hooks = self.build_hooks_config();

        // Always send initialize in streaming mode, even without hooks
        let request_id = format!("req_{}", Uuid::new_v4());
        let init_request = json!({
            "type": "control_request",
            "request_id": request_id,
            "request": {
                "subtype": "initialize",
                "hooks": hooks
            }
        });

        self.cli.write(&format!("{init_request}\n"))?;

        // Wait for the initialize response before continuing
        // Read messages until we get the control_response for our request
        loop {
            match self.cli.recv().await {
                Some(Ok(Message::ControlResponse(ref response))) => {
                    // Check if this is our initialize response
                    if response.request_id() == Some(request_id.as_str()) {
                        self.initialized = true;
                        return Ok(());
                    }
                }
                Some(Ok(_)) => {
                    // Skip other messages during initialization
                    continue;
                }
                Some(Err(e)) => return Err(e),
                None => {
                    return Err(Error::cli("CLI closed before initialize response"));
                }
            }
        }
    }

    /// Send a user message.
    ///
    /// # Message Size Limits
    ///
    /// Very large messages (over ~3MB) may fail or timeout due to CLI limitations.
    /// If you need to send large amounts of data, consider chunking into smaller
    /// messages or using file-based approaches (e.g., having Claude read a file).
    ///
    /// # Errors
    ///
    /// Returns an error if:
    /// - `finish_input()` has already been called
    /// - The CLI process has terminated
    /// - The message is empty or whitespace-only
    pub async fn send_message(&mut self, message: &str) -> Result<()> {
        // Check if input has been finished
        if self.input_finished {
            return Err(Error::cli(
                "Cannot send message after finish_input() was called",
            ));
        }

        // Validate message is not empty
        if message.trim().is_empty() {
            return Err(Error::cli("Cannot send empty or whitespace-only message"));
        }

        self.send_initialize().await?;

        let msg = json!({
            "type": "user",
            "message": {
                "role": "user",
                "content": [{"type": "text", "text": message}]
            }
        });
        self.cli.write(&format!("{msg}\n"))
    }

    /// Signal end of input.
    ///
    /// After calling this, no more messages can be sent.
    /// The recv() loop will terminate after receiving all pending results.
    pub fn finish_input(&mut self) -> Result<()> {
        if self.input_finished {
            // Already finished, idempotent
            return Ok(());
        }
        self.input_finished = true;
        self.cli.send_eof()
    }

    /// Interrupt the query.
    pub fn interrupt(&mut self) -> Result<()> {
        self.cli.interrupt()
    }

    /// Close the query.
    pub fn close(mut self) -> Result<()> {
        self.cli.kill()
    }

    /// Receive raw messages without processing.
    pub async fn recv_raw(&mut self) -> Option<Result<Message>> {
        self.cli.recv().await
    }

    /// Receive messages with automatic control request handling.
    ///
    /// Returns `None` when:
    /// - The CLI process has closed
    /// - Input has been finished and all turns are complete
    /// - max_turns has been reached
    pub async fn recv(&mut self) -> Option<Result<Message>> {
        // If we've finished input and completed all turns, return None
        if self.input_finished && self.is_complete() {
            return None;
        }

        loop {
            match self.cli.recv().await {
                Some(Ok(msg)) => {
                    // Handle control requests (CLI asking SDK to do something)
                    if let Message::ControlRequest(ref request) = msg {
                        if let Err(e) = self.handle_control_request(request).await {
                            return Some(Err(e));
                        }
                        continue;
                    }

                    // Handle control responses (CLI responding to SDK requests)
                    // These are internal protocol messages, not user-visible
                    if let Message::ControlResponse(ref response) = msg {
                        // Complete any pending request waiting for this response
                        if let Some(request_id) = response.request_id() {
                            let mut pending = self.pending_requests.write().await;
                            if let Some(pending_req) = pending.remove(request_id) {
                                // Send response data through the channel
                                let response_data = response
                                    .response
                                    .response
                                    .clone()
                                    .unwrap_or(serde_json::Value::Null);
                                let _ = pending_req.tx.send(response_data);
                            }
                        }
                        continue;
                    }

                    if matches!(msg, Message::HookInput(_)) {
                        continue;
                    }

                    if !self.options.include_replays && msg.is_replay() {
                        continue;
                    }

                    // Track Result messages to know when turns are complete
                    if matches!(msg, Message::Result(_)) {
                        self.turns_completed += 1;

                        // If we've reached max_turns in streaming mode, auto-close stdin
                        if self.should_auto_close() {
                            let _ = self.cli.send_eof();
                            self.input_finished = true;
                        }
                    }

                    return Some(Ok(msg));
                }
                Some(Err(e)) => return Some(Err(e)),
                None => return None,
            }
        }
    }

    /// Check if the query is complete (no more turns expected).
    fn is_complete(&self) -> bool {
        if let Some(max) = self.options.max_turns {
            self.turns_completed >= max
        } else {
            // Without max_turns, only complete when input is finished
            // and we've received at least one result
            self.input_finished && self.turns_completed > 0
        }
    }

    /// Check if we should auto-close stdin after receiving a result.
    fn should_auto_close(&self) -> bool {
        if !self.options.streaming_input {
            return false;
        }

        // Auto-close if we've reached max_turns
        if let Some(max) = self.options.max_turns
            && self.turns_completed >= max
        {
            return true;
        }

        false
    }

    async fn handle_control_request(&mut self, request: &ControlRequestMessage) -> Result<()> {
        let response = match &request.request {
            ControlRequest::HookCallback {
                callback_id, input, ..
            } => {
                self.hook_registry
                    .execute_callback(callback_id, input)
                    .await
            }
            ControlRequest::CanUseTool {
                tool_name,
                input,
                permission_suggestions,
                blocked_path,
                decision_reason,
                tool_use_id,
                agent_id,
            } => {
                if let Some(ref callback) = self.can_use_tool {
                    let suggestions_value = permission_suggestions
                        .as_ref()
                        .and_then(|s| serde_json::to_value(s).ok());
                    let req = CanUseToolRequest {
                        tool_name: tool_name.clone(),
                        input: input.clone(),
                        suggestions: suggestions_value,
                        blocked_path: blocked_path.clone(),
                        decision_reason: decision_reason.clone(),
                        tool_use_id: tool_use_id.clone(),
                        agent_id: agent_id.clone(),
                    };
                    let result = callback(req).await;
                    permission_result_to_json(&result, input)
                } else {
                    // Default: allow with original input
                    json!({ "behavior": "allow", "updatedInput": input })
                }
            }
            _ => {
                json!({ "error": "Unsupported control request" })
            }
        };

        self.send_control_response(&request.request_id, response)
    }

    fn send_control_response(&mut self, request_id: &str, response: Value) -> Result<()> {
        let msg = json!({
            "type": "control_response",
            "response": {
                "subtype": "success",
                "request_id": request_id,
                "response": response
            }
        });
        self.cli.write(&format!("{msg}\n"))
    }

    /// Send a control request and wait for response.
    async fn send_control_request(&mut self, request: Value) -> Result<Value> {
        let request_id = format!("req_{}", Uuid::new_v4());
        let (tx, rx) = oneshot::channel();

        // Register pending request
        {
            let mut pending = self.pending_requests.write().await;
            pending.insert(request_id.clone(), PendingRequest { tx });
        }

        // Send the request
        let msg = json!({
            "type": "control_request",
            "request_id": request_id,
            "request": request
        });
        self.cli.write(&format!("{msg}\n"))?;

        // Wait for response (with timeout)
        match tokio::time::timeout(std::time::Duration::from_secs(30), rx).await {
            Ok(Ok(response)) => Ok(response),
            Ok(Err(_)) => Err(Error::Timeout("Control request channel closed".to_string())),
            Err(_) => {
                // Clean up pending request
                let mut pending = self.pending_requests.write().await;
                pending.remove(&request_id);
                Err(Error::Timeout("Control request timed out".to_string()))
            }
        }
    }

    /// Convert to a message stream.
    ///
    /// This spawns a background task to handle CLI I/O and hook processing,
    /// returning a stream of messages.
    pub fn stream(mut self) -> MessageStream {
        let (tx, rx) = mpsc::channel::<Result<Message>>(100);
        let include_replays = self.options.include_replays;
        let hook_registry = self.hook_registry.clone();

        // Spawn background task to handle CLI communication
        tokio::spawn(async move {
            // Send initialization if needed
            if let Err(e) = self.send_initialize().await {
                let _ = tx.send(Err(e)).await;
                return;
            }

            loop {
                match self.cli.recv().await {
                    Some(Ok(msg)) => {
                        // Handle control requests
                        if let Message::ControlRequest(ref request) = msg {
                            let response = match &request.request {
                                ControlRequest::HookCallback {
                                    callback_id, input, ..
                                } => hook_registry.execute_callback(callback_id, input).await,
                                ControlRequest::CanUseTool { input, .. } => {
                                    json!({ "behavior": "allow", "updatedInput": input })
                                }
                                _ => json!({ "error": "Unsupported" }),
                            };

                            if let Err(e) =
                                self.send_control_response(&request.request_id, response)
                            {
                                let _ = tx.send(Err(e)).await;
                                break;
                            }
                            continue;
                        }

                        // Skip internal messages
                        if matches!(msg, Message::HookInput(_)) {
                            continue;
                        }

                        if !include_replays && msg.is_replay() {
                            continue;
                        }

                        // Send message to stream
                        if tx.send(Ok(msg)).await.is_err() {
                            break;
                        }
                    }
                    Some(Err(e)) => {
                        let _ = tx.send(Err(e)).await;
                        break;
                    }
                    None => break,
                }
            }
        });

        Box::pin(ReceiverStream::new(rx))
    }
}

/// Convert PermissionResult to JSON response using typed struct.
fn permission_result_to_json(result: &PermissionResult, original_input: &Value) -> Value {
    let response = match result {
        PermissionResult::Allow {
            updated_input,
            updated_permissions,
        } => {
            let perms_json = updated_permissions
                .as_ref()
                .and_then(|p| serde_json::to_value(p).ok());
            PermissionJsonResponse::allow(
                updated_input
                    .clone()
                    .unwrap_or_else(|| original_input.clone()),
                perms_json,
            )
        }
        PermissionResult::Deny { message, interrupt } => {
            PermissionJsonResponse::deny(message.clone(), *interrupt)
        }
    };
    serde_json::to_value(response).unwrap_or_else(|_| json!({"behavior": "allow"}))
}

/// Convert HookOutput to JSON response using typed struct.
fn hook_output_to_json(output: &HookOutput, event_name: &str) -> Value {
    let response = HookJsonResponse::from_hook_output(output, event_name);
    serde_json::to_value(response).unwrap_or_else(|_| json!({"continue": true}))
}

// Public API functions

/// Start a streaming input query.
///
/// # Errors
///
/// Returns an error if:
/// - `options.resume` is set with an invalid session ID format
/// - `options.max_turns` is set to 0 (must be at least 1)
/// - `options.max_budget_usd` is set to a non-positive value
pub fn start_query(mut options: QueryOptions) -> Result<Query> {
    // Validate options
    validate_options(&options)?;

    options.streaming_input = true;
    let builder = CommandBuilder::from_options(&options);
    let cli = Cli::spawn_piped_with_cwd(
        builder.build(),
        options.cwd.as_deref(),
        options.env.as_ref(),
    )?;
    Ok(Query::new(cli, options))
}

/// Validate query options before spawning CLI.
///
/// Validates:
/// - Session ID format (if resuming)
/// - max_turns > 0 (if set)
/// - max_budget_usd > 0 (if set)
fn validate_options(options: &QueryOptions) -> Result<()> {
    // Validate session ID if resuming
    if let Some(ref session_id) = options.resume {
        validate_session_id(session_id)?;
    }

    // Validate max_turns
    if let Some(max_turns) = options.max_turns
        && max_turns == 0
    {
        return Err(Error::cli(
            "max_turns must be at least 1 (use None for unlimited turns)",
        ));
    }

    // Validate budget
    if let Some(budget) = options.max_budget_usd
        && budget <= 0.0
    {
        return Err(Error::cli(
            "max_budget_usd must be positive (e.g., 0.01 for 1 cent)",
        ));
    }

    Ok(())
}

/// Validate a session ID format.
///
/// Session IDs should be valid UUIDs (e.g., "550e8400-e29b-41d4-a716-446655440000").
fn validate_session_id(session_id: &str) -> Result<()> {
    if session_id.is_empty() {
        return Err(Error::cli("Session ID cannot be empty"));
    }

    // Try to parse as UUID
    if Uuid::parse_str(session_id).is_err() {
        return Err(Error::cli(format!(
            "Invalid session ID format: '{session_id}'. Expected a valid UUID (e.g., '550e8400-e29b-41d4-a716-446655440000')"
        )));
    }

    Ok(())
}

/// Resume a session by ID.
///
/// # Errors
///
/// Returns an error if:
/// - The session ID is not a valid UUID format
/// - `options.max_turns` is set to 0
/// - `options.max_budget_usd` is set to a non-positive value
pub fn resume_session(session_id: &str, mut options: QueryOptions) -> Result<Query> {
    // Set resume first so validate_options can check it
    options.resume = Some(session_id.to_string());
    validate_options(&options)?;

    options.streaming_input = true;
    let builder = CommandBuilder::from_options(&options);
    let cli = Cli::spawn_piped_with_cwd(
        builder.build(),
        options.cwd.as_deref(),
        options.env.as_ref(),
    )?;
    Ok(Query::new(cli, options))
}

/// Start a query with a prompt and return a message stream.
///
/// # Errors
///
/// Returns an error if:
/// - `options.resume` is set with an invalid session ID format
/// - `options.max_turns` is set to 0
/// - `options.max_budget_usd` is set to a non-positive value
pub fn start_query_with_prompt(prompt: &str, options: QueryOptions) -> Result<MessageStream> {
    validate_options(&options)?;

    let mut builder = CommandBuilder::from_options(&options);
    builder.prompt(prompt);
    let cli = Cli::spawn_with_cwd(
        builder.build(),
        options.cwd.as_deref(),
        options.env.as_ref(),
    )?;
    Ok(Query::new(cli, options).stream())
}

/// Execute a query and wait for the final result.
pub async fn prompt(prompt_text: &str, options: QueryOptions) -> Result<ResultMessage> {
    let stream = start_query_with_prompt(prompt_text, options)?;
    futures::pin_mut!(stream);

    let mut result: Option<ResultMessage> = None;

    while let Some(msg_result) = stream.next().await {
        if let Message::Result(r) = msg_result? {
            result = Some(r);
        }
    }

    result.ok_or(Error::StreamEnded)
}
