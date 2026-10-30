//! PPID-based agent identification
//!
//! Provides stable agent identification across `/compact`, `--resume`, and multi-terminal
//! scenarios by using the parent PID (Claude Code's PID) + machine hash.
//!
//! Agent ID format: `cc-{ppid}-{machine_hash}`
//! Example: `cc-12345-a8f3b2c1`

use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::path::Path;
#[allow(unused_imports)]
use tracing::{debug, info, warn};

/// Compute a machine hash from hostname + username for cross-machine uniqueness
///
/// This ensures agent IDs are unique across machines when cloud-syncing.
pub fn compute_machine_hash() -> String { todo!() }

/// Compute the agent ID for the MCP server context
///
/// Uses getppid() to get Claude Code's PID (since MCP is a subprocess),
/// combined with machine hash for uniqueness.
#[cfg(unix)]
pub fn compute_agent_id() -> String { todo!() }

/// Compute the agent ID for hook context
///
/// Hooks run as: Claude Code → shell → cas hook
/// So we need the grandparent PID (Claude Code), not the parent (shell).
///
/// Architecture:
/// ```text
/// Claude Code (PID C)
/// ├── MCP Server (PPID = C) → agent_id = cc-C-{hash}
/// └── shell (PPID = C)
///     └── cas hook Stop (PPID = shell, grandparent = C) → agent_id = cc-C-{hash}
/// ```
#[cfg(unix)]
pub fn compute_agent_id_for_hook() -> String { todo!() }

#[cfg(not(unix))]
pub fn compute_agent_id_for_hook() -> String { todo!() }

/// Get the parent PID of a given process (for subagent detection)
///
/// On Unix, reads /proc/{pid}/stat to extract PPID.
/// On macOS, uses `ps` command.
#[cfg(target_os = "linux")]
pub fn get_parent_of_pid(pid: u32) -> Option<u32> { todo!() }

#[cfg(target_os = "macos")]
pub fn get_parent_of_pid(pid: u32) -> Option<u32> { todo!() }

#[cfg(windows)]
pub fn get_parent_of_pid(pid: u32) -> Option<u32> { todo!() }

#[cfg(not(any(target_os = "linux", target_os = "macos", windows)))]
pub fn get_parent_of_pid(_pid: u32) -> Option<u32> { todo!() }

/// Windows fallback for compute_agent_id
#[cfg(not(unix))]
pub fn compute_agent_id() -> String { todo!() }

/// Detect parent agent ID for subagent linking
///
/// When Claude Code spawns a subagent via Task tool:
/// - Parent CC (PID 12345) spawns Subagent CC (PID 23456)
/// - Subagent's MCP (PID 23457) has PPID = 23456
/// - We get grandparent PID (12345) and look up its agent ID
///
/// Returns the parent agent ID if:
/// 1. We can determine our grandparent PID
/// 2. That PID has a registered agent in the mapping file
pub fn detect_parent_agent_id(cas_root: &Path) -> Option<String> { todo!() }

/// Register the agent's PID mapping for subagent detection
///
/// Writes the agent ID to a file keyed by Claude Code's PID so that
/// subagents can discover their parent agent.
pub fn register_agent_pid_mapping(cas_root: &Path, agent_id: &str) -> std::io::Result<()> { todo!() }

/// Cleanup the agent's PID mapping on shutdown
pub fn cleanup_agent_pid_mapping(cas_root: &Path) { todo!() }

/// Cleanup PID mapping for a specific Claude Code PID (used by hooks)
pub fn cleanup_pid_mapping_for_cc_pid(cas_root: &Path, cc_pid: u32) { todo!() }

// ============================================================================
// Session ID Lookup (for auto-registration)
// ============================================================================
// PID → session mapping is maintained by the daemon in memory.
// SessionStart hook sends cc_pid to daemon, MCP queries daemon for session.

/// Read session_id for this MCP server (called by MCP on first tool use)
///
/// Queries the daemon via Unix socket for the session mapped to this Claude Code PID.
/// The daemon maintains PID → session mappings in memory (set by SessionStart hook).
#[cfg(feature = "mcp-server")]
pub fn read_session_for_mcp(cas_root: &Path) -> std::io::Result<String> { todo!() }

/// Get the Claude Code PID (PPID in MCP context, our PID in hook context)
#[cfg(unix)]
pub fn get_cc_pid_for_mcp() -> u32 { todo!() }

#[cfg(not(unix))]
pub fn get_cc_pid_for_mcp() -> u32 { todo!() }

/// Get Claude Code's PID from hook context
///
/// Hooks can run in two modes:
/// 1. Direct: Claude Code → cas hook (PPID = Claude Code)
/// 2. Via shell: Claude Code → shell → cas hook (grandparent = Claude Code)
///
/// We detect which mode by checking if our parent's name contains "claude".
#[cfg(unix)]
pub fn get_cc_pid_for_hook() -> u32 { todo!() }

/// Check if a process is Claude Code by examining its command name
#[cfg(target_os = "macos")]
fn is_claude_code_process(pid: u32) -> bool { todo!() }

#[cfg(target_os = "linux")]
fn is_claude_code_process(pid: u32) -> bool { todo!() }

#[cfg(not(any(target_os = "macos", target_os = "linux")))]
fn is_claude_code_process(_pid: u32) -> bool { todo!() }

#[cfg(not(unix))]
pub fn get_cc_pid_for_hook() -> u32 { todo!() }

#[cfg(test)]
mod tests {
    use crate::agent_id::*;

    #[test]
    fn test_machine_hash_consistent() {
        let hash1 = compute_machine_hash();
        let hash2 = compute_machine_hash();
        assert_eq!(hash1, hash2);
        assert_eq!(hash1.len(), 8); // 8 hex chars
    }

    #[test]
    fn test_agent_id_format() {
        let agent_id = compute_agent_id();
        assert!(agent_id.starts_with("cc-"));
        // Should be cc-{pid}-{8-char-hash}
        let parts: Vec<&str> = agent_id.split('-').collect();
        assert_eq!(parts.len(), 3);
        assert_eq!(parts[0], "cc");
        assert!(parts[1].parse::<u32>().is_ok()); // PID
        assert_eq!(parts[2].len(), 8); // Hash
    }

    #[test]
    fn test_hook_agent_id_format() {
        let agent_id = compute_agent_id_for_hook();
        assert!(agent_id.starts_with("cc-"));
        let parts: Vec<&str> = agent_id.split('-').collect();
        assert_eq!(parts.len(), 3);
        assert_eq!(parts[0], "cc");
        // In hook context, uses either:
        // - PPID if parent is Claude Code (direct execution)
        // - grandparent if parent is a shell (shell wrapper)
        // In test context, parent is cargo test (not Claude), so uses grandparent
        let pid_str = parts[1];
        let pid: u32 = pid_str.parse().unwrap();
        #[cfg(unix)]
        {
            let ppid = std::os::unix::process::parent_id();
            // In test, parent is cargo/test runner, not Claude Code
            // So we use grandparent
            let expected = if is_claude_code_process(ppid) {
                ppid
            } else {
                get_parent_of_pid(ppid).unwrap_or(ppid)
            };
            assert_eq!(pid, expected);
        }
        #[cfg(not(unix))]
        {
            // On non-Unix, falls back to own PID
            assert_eq!(pid, std::process::id());
        }
    }

    #[cfg(unix)]
    #[test]
    fn test_get_parent_of_pid() {
        // Our own parent should be retrievable
        let our_pid = std::process::id();
        let our_ppid = std::os::unix::process::parent_id();

        // Test that we can get our own parent
        if let Some(ppid) = get_parent_of_pid(our_pid) {
            assert_eq!(ppid, our_ppid);
        }
        // Note: This might fail in some test environments, so we don't panic
    }


    #[test]
    fn test_subagent_parent_detection() {
        use tempfile::TempDir;

        let temp = TempDir::new().unwrap();
        let cas_root = temp.path();

        // Simulate parent agent registration by writing a PID mapping file
        // In real usage, the parent MCP writes this file keyed by its PPID (Claude Code's PID)
        let parent_agent_id = "cc-99999-deadbeef";
        let mapping_dir = cas_root.join("agents_by_cc_pid");
        std::fs::create_dir_all(&mapping_dir).unwrap();

        // Write a mapping for our grandparent PID (simulating parent agent)
        // In real subagent scenario:
        // - Parent CC (PID P) spawns Subagent CC (PID S)
        // - Subagent CC spawns MCP (PID M, PPID = S)
        // - MCP's grandparent = P, so it looks up agents_by_cc_pid/P
        #[cfg(unix)]
        {
            let our_ppid = std::os::unix::process::parent_id();
            // Simulate that our grandparent registered as an agent
            if let Some(grandparent) = get_parent_of_pid(our_ppid) {
                std::fs::write(mapping_dir.join(grandparent.to_string()), parent_agent_id).unwrap();

                // Now detect_parent_agent_id should find it
                let detected = detect_parent_agent_id(cas_root);
                assert_eq!(detected, Some(parent_agent_id.to_string()));

                // Cleanup
                std::fs::remove_file(mapping_dir.join(grandparent.to_string())).unwrap();
            }
        }

        // Test that detection returns None when no parent exists
        let no_parent = detect_parent_agent_id(cas_root);
        assert_eq!(no_parent, None);
    }

    #[test]
    fn test_cleanup_pid_mapping_for_specific_pid() {
        use tempfile::TempDir;

        let temp = TempDir::new().unwrap();
        let cas_root = temp.path();

        let mapping_dir = cas_root.join("agents_by_cc_pid");
        std::fs::create_dir_all(&mapping_dir).unwrap();

        // Create a mapping file for a specific PID
        let test_pid: u32 = 12345;
        let mapping_file = mapping_dir.join(test_pid.to_string());
        std::fs::write(&mapping_file, "cc-12345-test1234").unwrap();
        assert!(mapping_file.exists());

        // Cleanup using the specific function
        cleanup_pid_mapping_for_cc_pid(cas_root, test_pid);
        assert!(!mapping_file.exists());
    }

    // Note: Session mapping tests removed - session lookup now uses daemon socket
    // and cannot be unit tested without a running daemon. Tested via integration tests.
}
