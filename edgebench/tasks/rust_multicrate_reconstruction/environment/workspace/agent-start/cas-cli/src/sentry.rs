//! Sentry crash reporting integration
//!
//! Provides automatic panic/crash reporting to Sentry for debugging.
//! Respects user telemetry preferences and strips PII from reports.

use sentry::ClientInitGuard;

/// Get Sentry DSN from environment or use default
fn get_sentry_dsn() -> Option<&'static str> { todo!() }

/// Initialize Sentry crash reporting if telemetry is enabled.
///
/// Returns a guard that must be kept alive for the duration of the program.
/// When the guard is dropped, Sentry flushes any pending events.
///
/// # Arguments
/// * `telemetry_enabled` - Whether the user has opted into telemetry
///
/// # Returns
/// * `Some(guard)` if Sentry was initialized
/// * `None` if telemetry is disabled or initialization failed
pub fn init(telemetry_enabled: bool) -> Option<ClientInitGuard> { todo!() }

/// Add breadcrumb for command execution (for crash context)
pub fn add_command_breadcrumb(command: &str) { todo!() }

/// Check if Sentry crash reporting is enabled.
///
/// Sentry is opt-in: only enabled when CAS_SENTRY=1 env var is set
/// or explicitly enabled in config.
pub fn is_sentry_enabled() -> bool { todo!() }

#[cfg(test)]
mod tests {
    use crate::sentry::*;

    #[test]
    fn test_telemetry_disabled_returns_none() {
        let guard = init(false);
        assert!(guard.is_none());
    }
}
