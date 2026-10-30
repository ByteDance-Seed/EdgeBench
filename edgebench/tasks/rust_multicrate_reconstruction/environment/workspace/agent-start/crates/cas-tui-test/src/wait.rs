//! Wait DSL - Methods for waiting on terminal output conditions
//!
//! Provides configurable wait methods with timeouts for:
//! - Text appearance
//! - Regex pattern matching
//! - Output stability (no changes for a duration)

use crate::pty_runner::{PtyRunner, PtyRunnerError};
use regex::Regex;
use std::time::{Duration, Instant};
use thiserror::Error;

/// Default timeout for wait operations
pub const DEFAULT_TIMEOUT: Duration = Duration::from_secs(5);

/// Default poll interval for wait operations
pub const DEFAULT_POLL_INTERVAL: Duration = Duration::from_millis(50);

/// Default stability duration for wait_stable
pub const DEFAULT_STABLE_DURATION: Duration = Duration::from_millis(200);

/// Errors that can occur during wait operations
#[derive(Debug, Error)]
pub enum WaitError {
    #[error("Timeout waiting for text '{0}' after {1:?}")]
    TextTimeout(String, Duration),

    #[error("Timeout waiting for pattern '{0}' after {1:?}")]
    PatternTimeout(String, Duration),

    #[error("Timeout waiting for stable output after {0:?}")]
    StableTimeout(Duration),

    #[error("Invalid regex pattern: {0}")]
    InvalidPattern(#[from] regex::Error),

    #[error("PTY error: {0}")]
    PtyError(#[from] PtyRunnerError),
}

/// Configuration for wait operations
#[derive(Debug, Clone)]
pub struct WaitConfig {
    /// Maximum time to wait
    pub timeout: Duration,
    /// How often to poll for changes
    pub poll_interval: Duration,
    /// For wait_stable: how long output must be unchanged
    pub stable_duration: Duration,
}

impl Default for WaitConfig {
    fn default() -> Self { todo!() }
}

impl WaitConfig {
    /// Create config with custom timeout
    pub fn with_timeout(timeout: Duration) -> Self { todo!() }

    /// Create config with timeout in milliseconds
    pub fn with_timeout_ms(ms: u64) -> Self { todo!() }

    /// Set poll interval
    pub fn poll_interval(mut self, interval: Duration) -> Self { todo!() }

    /// Set stable duration for wait_stable
    pub fn stable_duration(mut self, duration: Duration) -> Self { todo!() }
}

/// Wait for text to appear in output
pub fn wait_for_text(
    runner: &mut PtyRunner,
    text: &str,
    config: &WaitConfig,
) -> Result<String, WaitError> { todo!() }

/// Wait for a regex pattern to match in output
pub fn wait_for_regex(
    runner: &mut PtyRunner,
    pattern: &str,
    config: &WaitConfig,
) -> Result<String, WaitError> { todo!() }

/// Wait for output to stabilize (no changes for stable_duration)
pub fn wait_stable(runner: &mut PtyRunner, config: &WaitConfig) -> Result<String, WaitError> { todo!() }

/// Extension trait for PtyRunner to add wait methods
pub trait WaitExt {
    /// Wait for text with default config
    fn wait_for_text(&mut self, text: &str) -> Result<String, WaitError>;

    /// Wait for text with custom timeout
    fn wait_for_text_timeout(&mut self, text: &str, timeout: Duration)
    -> Result<String, WaitError>;

    /// Wait for regex pattern with default config
    fn wait_for_regex(&mut self, pattern: &str) -> Result<String, WaitError>;

    /// Wait for regex pattern with custom timeout
    fn wait_for_regex_timeout(
        &mut self,
        pattern: &str,
        timeout: Duration,
    ) -> Result<String, WaitError>;

    /// Wait for output to stabilize with default config
    fn wait_stable(&mut self) -> Result<String, WaitError>;

    /// Wait for output to stabilize with custom config
    fn wait_stable_config(&mut self, config: &WaitConfig) -> Result<String, WaitError>;
}

impl WaitExt for PtyRunner {
    fn wait_for_text(&mut self, text: &str) -> Result<String, WaitError> { todo!() }

    fn wait_for_text_timeout(
        &mut self,
        text: &str,
        timeout: Duration,
    ) -> Result<String, WaitError> { todo!() }

    fn wait_for_regex(&mut self, pattern: &str) -> Result<String, WaitError> { todo!() }

    fn wait_for_regex_timeout(
        &mut self,
        pattern: &str,
        timeout: Duration,
    ) -> Result<String, WaitError> { todo!() }

    fn wait_stable(&mut self) -> Result<String, WaitError> { todo!() }

    fn wait_stable_config(&mut self, config: &WaitConfig) -> Result<String, WaitError> { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::wait::*;

    #[test]
    fn test_wait_config_default() {
        let config = WaitConfig::default();
        assert_eq!(config.timeout, DEFAULT_TIMEOUT);
        assert_eq!(config.poll_interval, DEFAULT_POLL_INTERVAL);
        assert_eq!(config.stable_duration, DEFAULT_STABLE_DURATION);
    }

    #[test]
    fn test_wait_config_builder() {
        let config = WaitConfig::with_timeout_ms(1000)
            .poll_interval(Duration::from_millis(10))
            .stable_duration(Duration::from_millis(100));

        assert_eq!(config.timeout, Duration::from_millis(1000));
        assert_eq!(config.poll_interval, Duration::from_millis(10));
        assert_eq!(config.stable_duration, Duration::from_millis(100));
    }

    #[test]
    fn test_wait_for_text_success() {
        let mut runner = PtyRunner::new();
        runner
            .spawn("echo", &["hello world"])
            .expect("spawn failed");

        let config = WaitConfig::with_timeout_ms(1000);
        let result = wait_for_text(&mut runner, "hello", &config);
        assert!(result.is_ok());
        assert!(result.unwrap().contains("hello"));
    }

    #[test]
    fn test_wait_for_text_timeout() {
        let mut runner = PtyRunner::new();
        runner.spawn("echo", &["hello"]).expect("spawn failed");

        let config = WaitConfig::with_timeout_ms(100);
        let result = wait_for_text(&mut runner, "nonexistent", &config);
        assert!(matches!(result, Err(WaitError::TextTimeout(_, _))));
    }

    #[test]
    fn test_wait_for_regex_success() {
        let mut runner = PtyRunner::new();
        runner.spawn("echo", &["value: 42"]).expect("spawn failed");

        let config = WaitConfig::with_timeout_ms(1000);
        let result = wait_for_regex(&mut runner, r"value:\s+\d+", &config);
        assert!(result.is_ok());
    }


    #[test]
    fn test_wait_stable() {
        let mut runner = PtyRunner::new();
        runner
            .spawn("echo", &["stable output"])
            .expect("spawn failed");

        let config = WaitConfig::with_timeout_ms(1000).stable_duration(Duration::from_millis(100));
        let result = wait_stable(&mut runner, &config);
        assert!(result.is_ok());
    }

    #[test]
    fn test_wait_ext_trait() {
        let mut runner = PtyRunner::new();
        runner
            .spawn("echo", &["test output"])
            .expect("spawn failed");

        let result = runner.wait_for_text_timeout("test", Duration::from_millis(1000));
        assert!(result.is_ok());
    }
}
