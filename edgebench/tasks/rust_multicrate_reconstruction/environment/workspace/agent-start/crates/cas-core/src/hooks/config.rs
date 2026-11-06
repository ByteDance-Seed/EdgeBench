//! Configuration traits for hooks
//!
//! Defines traits that abstract over configuration access, allowing
//! the hooks module to work with different configuration backends.

use serde::{Deserialize, Serialize};

/// Configuration for plan mode context building
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct PlanModeConfig {
    /// Whether to use plan-aware context in plan mode
    #[serde(default = "default_true")]
    pub enabled: bool,

    /// Token budget for plan mode (typically higher than execution)
    #[serde(default = "default_plan_token_budget")]
    pub token_budget: usize,

    /// Maximum tasks to show in plan context
    #[serde(default = "default_plan_task_limit")]
    pub task_limit: usize,

    /// Include dependency trees in plan context
    #[serde(default = "default_true")]
    pub show_dependencies: bool,

    /// Include closed tasks in dependency context
    #[serde(default)]
    pub include_closed: bool,
}

impl Default for PlanModeConfig {
    fn default() -> Self { todo!() }
}

fn default_true() -> bool { todo!() }
fn default_plan_token_budget() -> usize { todo!() }
fn default_plan_task_limit() -> usize { todo!() }
fn default_token_budget() -> usize { todo!() }
fn default_ai_model() -> String { todo!() }

/// Configuration trait for hooks
///
/// Abstracts over configuration access so the hooks module can work
/// with different configuration backends (CLI config, MCP config, etc.)
pub trait HooksConfig {
    /// Token budget for context injection
    fn token_budget(&self) -> usize;

    /// Whether to start with minimal context (context engineering pattern)
    fn minimal_start(&self) -> bool;

    /// Whether MCP mode is enabled
    fn mcp_enabled(&self) -> bool;

    /// Whether to use AI-powered context selection
    fn ai_context(&self) -> bool;

    /// Model to use for AI context selection
    fn ai_model(&self) -> String;

    /// Whether to fall back to non-AI context if AI fails
    fn ai_fallback(&self) -> bool;

    /// Whether context injection is enabled
    fn inject_context(&self) -> bool;

    /// Get plan mode configuration
    fn plan_mode(&self) -> PlanModeConfig;

    /// Get supervisor role guidance content
    fn supervisor_guidance(&self) -> String { todo!() }

    /// Get worker role guidance content
    fn worker_guidance(&self) -> String { todo!() }
}

/// Default supervisor guidance content (fallback when cas-cli builtins are unavailable)
fn default_supervisor_guidance() -> String { todo!() }

/// Default worker guidance content (fallback when cas-cli builtins are unavailable)
fn default_worker_guidance() -> String { todo!() }

/// Default hooks configuration
///
/// Used when no configuration is available. Provides sensible defaults.
#[derive(Debug, Clone, Default)]
pub struct DefaultHooksConfig {
    pub token_budget: usize,
    pub minimal_start: bool,
    pub mcp_enabled: bool,
    pub ai_context: bool,
    pub ai_model: String,
    pub ai_fallback: bool,
    pub inject_context: bool,
    pub plan_mode: PlanModeConfig,
}

impl DefaultHooksConfig {
    pub fn new() -> Self { todo!() }

    /// Create config with MCP mode enabled
    pub fn with_mcp(mut self) -> Self { todo!() }

    /// Create config with specified token budget
    pub fn with_token_budget(mut self, budget: usize) -> Self { todo!() }
}

impl HooksConfig for DefaultHooksConfig {
    fn token_budget(&self) -> usize { todo!() }

    fn minimal_start(&self) -> bool { todo!() }

    fn mcp_enabled(&self) -> bool { todo!() }

    fn ai_context(&self) -> bool { todo!() }

    fn ai_model(&self) -> String { todo!() }

    fn ai_fallback(&self) -> bool { todo!() }

    fn inject_context(&self) -> bool { todo!() }

    fn plan_mode(&self) -> PlanModeConfig { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::hooks::config::*;



    #[test]
    fn test_with_token_budget() {
        let config = DefaultHooksConfig::new().with_token_budget(8000);
        assert_eq!(config.token_budget(), 8000);
    }

}
