//! CLI command/argument builder.
//!
//! Converts [`QueryOptions`] into command-line arguments for the Claude CLI.

use crate::options::{QueryOptions, SystemPrompt};

/// Builder for Claude CLI command arguments.
#[derive(Debug, Default)]
pub struct CommandBuilder {
    args: Vec<String>,
}

impl CommandBuilder {
    /// Create a new command builder with base arguments.
    ///
    /// Base arguments enable JSON streaming output:
    /// - `--print` - Output to stdout instead of interactive mode
    /// - `--output-format stream-json` - Newline-delimited JSON output
    /// - `--verbose` - Include detailed messages
    pub fn new() -> Self {
        Self {
            args: vec![
                "--print".to_string(),
                "--output-format".to_string(),
                "stream-json".to_string(),
                "--verbose".to_string(),
            ],
        }
    }

    /// Create a command builder for streaming input mode.
    ///
    /// Streaming mode does NOT use `--print` - it uses bidirectional
    /// JSON streaming via stdin/stdout. The `--print` flag is only
    /// for one-shot queries with a prompt argument.
    pub fn streaming_input() -> Self {
        Self {
            args: vec![
                "--output-format".to_string(),
                "stream-json".to_string(),
                "--verbose".to_string(),
                "--input-format".to_string(),
                "stream-json".to_string(),
            ],
        }
    }

    /// Build arguments from query options.
    pub fn from_options(options: &QueryOptions) -> Self {
        let mut builder = if options.streaming_input {
            Self::streaming_input()
        } else {
            Self::new()
        };

        builder.apply_options(options);
        builder
    }

    /// Apply query options to the command builder.
    fn apply_options(&mut self, options: &QueryOptions) {
        // Model
        if let Some(ref model) = options.model {
            self.arg("--model", model);
        }

        // System prompt
        match &options.system_prompt {
            Some(SystemPrompt::Text(text)) => {
                self.arg("--system-prompt", text);
            }
            Some(SystemPrompt::Preset(preset)) => {
                self.arg("--system-prompt-preset", preset);
            }
            Some(SystemPrompt::Append(text)) => {
                self.arg("--system-prompt-append", text);
            }
            None => {}
        }

        // Limits
        if let Some(max_turns) = options.max_turns {
            self.arg("--max-turns", &max_turns.to_string());
        }

        if let Some(max_thinking) = options.max_thinking_tokens {
            self.arg("--max-thinking-tokens", &max_thinking.to_string());
        }

        if let Some(max_budget) = options.max_budget_usd {
            self.arg("--max-budget-usd", &max_budget.to_string());
        }

        // Permission mode
        if let Some(ref mode) = options.permission_mode {
            self.arg("--permission-mode", mode.to_cli_arg());
        }

        if options.dangerously_skip_permissions && options.allow_dangerously_skip_permissions {
            self.flag("--dangerously-skip-permissions");
        }

        // Permission prompt tool
        if let Some(ref tool_name) = options.permission_prompt_tool_name {
            self.arg("--permission-prompt-tool", tool_name);
        }

        // Working directory - handled by process spawning, not CLI args
        // The cwd option is used when spawning the CLI process

        // MCP config
        if let Some(ref config) = options.mcp_config {
            self.arg("--mcp-config", &config.to_string_lossy());
        }

        // Tool filters
        for tool in &options.allowed_tools {
            self.arg("--allowed-tools", tool);
        }

        for tool in &options.disallowed_tools {
            self.arg("--disallowed-tools", tool);
        }

        // Session management
        if options.continue_session {
            self.flag("--continue");
        }

        if let Some(ref session_id) = options.resume {
            self.arg("--resume", session_id);
        }

        if let Some(ref at) = options.resume_at {
            self.arg("--resume-at", at);
        }

        if options.fork_session {
            self.flag("--fork-session");
        }

        // Session persistence
        if let Some(persist) = options.persist_session
            && !persist
        {
            self.flag("--no-persist-session");
        }

        // File checkpointing
        if options.enable_file_checkpointing {
            self.flag("--enable-file-checkpointing");
        }

        // Output format (structured output)
        if let Some(ref schema) = options.output_schema {
            self.arg(
                "--output-format-json-schema",
                &serde_json::to_string(schema).unwrap_or_default(),
            );
        }

        // Agents
        if let Some(ref agents) = options.agents {
            self.arg(
                "--agents",
                &serde_json::to_string(agents).unwrap_or_default(),
            );
        }

        // Plugins
        if let Some(ref plugins) = options.plugins {
            self.arg(
                "--plugins",
                &serde_json::to_string(plugins).unwrap_or_default(),
            );
        }

        // Sandbox
        if let Some(ref sandbox) = options.sandbox {
            self.arg(
                "--sandbox",
                &serde_json::to_string(sandbox).unwrap_or_default(),
            );
        }

        // Fallback model
        if let Some(ref fallback) = options.fallback_model {
            self.arg("--fallback-model", fallback);
        }

        // Include partial messages
        if options.include_partial_messages {
            self.flag("--include-partial-messages");
        }

        // Setting sources
        for source in &options.setting_sources {
            self.arg("--setting-sources", source.to_cli_arg());
        }

        // Additional directories
        for dir in &options.additional_directories {
            self.arg("--add-dir", &dir.to_string_lossy());
        }

        // Strict MCP config
        if options.strict_mcp_config {
            self.flag("--strict-mcp-config");
        }

        // Beta features
        for beta in &options.betas {
            self.arg("--beta", beta);
        }

        // Extra args (pass-through)
        self.args.extend(options.extra_args.clone());
    }

    /// Add a flag (no value).
    pub fn flag(&mut self, flag: &str) -> &mut Self {
        self.args.push(flag.to_string());
        self
    }

    /// Add an argument with a value.
    pub fn arg(&mut self, name: &str, value: &str) -> &mut Self {
        self.args.push(name.to_string());
        self.args.push(value.to_string());
        self
    }

    /// Add the prompt as a positional argument.
    pub fn prompt(&mut self, prompt: &str) -> &mut Self {
        self.args.push("-p".to_string());
        self.args.push(prompt.to_string());
        self
    }

    /// Build the final argument list.
    pub fn build(self) -> Vec<String> {
        self.args
    }

    /// Get the arguments as a slice.
    pub fn args(&self) -> &[String] {
        &self.args
    }
}

#[cfg(test)]
mod tests {
    use crate::cli::command::*;
    use crate::options::PermissionMode;

    #[test]
    fn test_base_args() {
        let builder = CommandBuilder::new();
        let args = builder.build();
        assert!(args.contains(&"--print".to_string()));
        assert!(args.contains(&"--output-format".to_string()));
        assert!(args.contains(&"stream-json".to_string()));
        assert!(args.contains(&"--verbose".to_string()));
    }

    #[test]
    fn test_streaming_input_args() {
        let builder = CommandBuilder::streaming_input();
        let args = builder.build();
        assert!(args.contains(&"--input-format".to_string()));
        assert!(args.contains(&"stream-json".to_string()));
    }

    #[test]
    fn test_with_model() {
        let options = QueryOptions {
            model: Some("claude-sonnet-4-5-20250929".to_string()),
            ..Default::default()
        };
        let builder = CommandBuilder::from_options(&options);
        let args = builder.build();
        assert!(args.contains(&"--model".to_string()));
        assert!(args.contains(&"claude-sonnet-4-5-20250929".to_string()));
    }

    #[test]
    fn test_with_permission_mode() {
        let options = QueryOptions {
            permission_mode: Some(PermissionMode::AcceptEdits),
            ..Default::default()
        };
        let builder = CommandBuilder::from_options(&options);
        let args = builder.build();
        assert!(args.contains(&"--permission-mode".to_string()));
        assert!(args.contains(&"acceptEdits".to_string()));
    }

    // Note: cwd is handled by process spawning, not CLI arguments
    // See Cli::spawn_with_cwd() in cli/mod.rs

    #[test]
    fn test_prompt() {
        let mut builder = CommandBuilder::new();
        builder.prompt("Hello, Claude!");
        let args = builder.build();
        assert!(args.contains(&"-p".to_string()));
        assert!(args.contains(&"Hello, Claude!".to_string()));
    }

    #[test]
    fn test_allowed_tools() {
        let options = QueryOptions {
            allowed_tools: vec!["Bash".to_string(), "Read".to_string()],
            ..Default::default()
        };
        let builder = CommandBuilder::from_options(&options);
        let args = builder.build();

        // Find all --allowed-tools and their values using windows
        let mut found_tools = Vec::new();
        for window in args.windows(2) {
            if window[0] == "--allowed-tools" {
                found_tools.push(window[1].as_str());
            }
        }

        assert!(
            !found_tools.is_empty(),
            "Expected --allowed-tools arguments"
        );
        for tool in found_tools {
            assert!(tool == "Bash" || tool == "Read", "Unexpected tool: {tool}");
        }
    }

    #[test]
    fn test_session_resume() {
        let options = QueryOptions {
            resume: Some("session-123".to_string()),
            fork_session: true,
            ..Default::default()
        };
        let builder = CommandBuilder::from_options(&options);
        let args = builder.build();
        assert!(args.contains(&"--resume".to_string()));
        assert!(args.contains(&"session-123".to_string()));
        assert!(args.contains(&"--fork-session".to_string()));
    }
}
