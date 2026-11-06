//! SSH-based remote attach to factories on other machines.
//!
//! Resolves device name → SSH host via cloud API, builds an SSH command,
//! and replaces the current process with `ssh -t <host> -- cas attach <factory-id>`.

use std::io;

use anyhow::{Result, bail};

use crate::cloud::CloudConfig;
use crate::ui::components::{Formatter, Renderable, StatusLine};
use crate::ui::theme::ActiveTheme;

/// Parse a remote target string into (device_name, factory_id).
///
/// Formats:
///   - `device:factory-id` → (Some("device"), "factory-id")
///   - `factory-id`        → (None, "factory-id")
fn parse_remote_target(target: &str) -> (Option<&str>, &str) { todo!() }

/// Look up a device's SSH host from the cloud API.
///
/// Fetches GET /api/devices and finds the device by name or ID,
/// then extracts the ssh_config.host field.
fn resolve_ssh_host(cloud_config: &CloudConfig, device_name: &str) -> Result<String> { todo!() }

/// Execute remote attach via SSH.
///
/// 1. Parse target into device name and factory ID
/// 2. Look up device SSH host from cloud API
/// 3. Build SSH command: `ssh -t <host> -- cas attach <factory-id> [--worker <name>]`
/// 4. Replace current process with SSH via exec
pub fn execute_remote_attach(target: &str, worker: Option<&str>) -> Result<()> { todo!() }

/// Replace the current process with SSH using exec.
///
/// On Unix, uses execvp to replace the process entirely.
/// On non-Unix, spawns SSH as a child process.
fn exec_ssh(args: &[String]) -> Result<()> { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_parse_remote_target_with_device() {
        let (device, factory_id) = parse_remote_target("desktop:f-abc123");
        assert_eq!(device, Some("desktop"));
        assert_eq!(factory_id, "f-abc123");
    }


    #[test]
    fn test_parse_remote_target_empty_device() {
        let (device, factory_id) = parse_remote_target(":f-abc123");
        assert_eq!(device, None);
        assert_eq!(factory_id, "f-abc123");
    }

    #[test]
    fn test_parse_remote_target_complex_factory_id() {
        let (device, factory_id) = parse_remote_target("laptop:my-session-name");
        assert_eq!(device, Some("laptop"));
        assert_eq!(factory_id, "my-session-name");
    }
}
