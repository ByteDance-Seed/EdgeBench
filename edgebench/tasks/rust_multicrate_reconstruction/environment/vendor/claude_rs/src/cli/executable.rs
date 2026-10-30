//! Claude CLI executable detection.
//!
//! Searches for the `claude` executable in common locations.

use crate::error::{Error, Result};
use std::path::{Path, PathBuf};
use std::process::Command;

/// Known locations to search for the Claude CLI executable.
const KNOWN_PATHS: &[&str] = &[
    // Homebrew (macOS ARM)
    "/opt/homebrew/bin/claude",
    // Homebrew (macOS Intel)
    "/usr/local/bin/claude",
    // Linux
    "/usr/bin/claude",
    // npm global (will be expanded with home dir)
    ".claude/local/claude",
];

/// Find the Claude CLI executable.
///
/// Searches in the following order:
/// 1. `CLAUDE_EXECUTABLE` environment variable
/// 2. System PATH
/// 3. Known installation locations
///
/// # Returns
/// The path to the executable, or an error if not found.
pub fn find_executable() -> Result<PathBuf> {
    // Check environment variable first
    if let Ok(path) = std::env::var("CLAUDE_EXECUTABLE") {
        let path = PathBuf::from(path);
        if path.exists() && is_executable(&path) {
            return Ok(path);
        }
    }

    // Check PATH using `which`
    if let Ok(output) = Command::new("which").arg("claude").output()
        && output.status.success()
    {
        let path_str = String::from_utf8_lossy(&output.stdout);
        let path = PathBuf::from(path_str.trim());
        if path.exists() {
            return Ok(path);
        }
    }

    // Check known paths
    for known_path in KNOWN_PATHS {
        let path = if known_path.starts_with('.') {
            // Expand home directory
            if let Some(home) = dirs::home_dir() {
                home.join(known_path)
            } else {
                continue;
            }
        } else {
            PathBuf::from(known_path)
        };

        if path.exists() && is_executable(&path) {
            return Ok(path);
        }
    }

    // Try npm global installation
    if let Some(path) = find_npm_global() {
        return Ok(path);
    }

    Err(Error::ExecutableNotFound)
}

/// Check if a path is executable.
#[cfg(unix)]
fn is_executable(path: &Path) -> bool {
    use std::os::unix::fs::PermissionsExt;
    if let Ok(metadata) = path.metadata() {
        let permissions = metadata.permissions();
        permissions.mode() & 0o111 != 0
    } else {
        false
    }
}

#[cfg(not(unix))]
fn is_executable(path: &Path) -> bool {
    path.exists()
}

/// Try to find claude installed via npm global.
fn find_npm_global() -> Option<PathBuf> {
    // Try `npm root -g` to get global node_modules path
    let output = Command::new("npm").args(["root", "-g"]).output().ok()?;

    if !output.status.success() {
        return None;
    }

    let root = String::from_utf8_lossy(&output.stdout);
    let root = root.trim();

    // Claude might be in .bin relative to node_modules
    let bin_path = PathBuf::from(root).parent()?.join("bin").join("claude");

    if bin_path.exists() && is_executable(&bin_path) {
        return Some(bin_path);
    }

    // Or in the package directly
    let pkg_path = PathBuf::from(root)
        .join("@anthropic-ai")
        .join("claude-code")
        .join("cli.js");

    if pkg_path.exists() {
        // Return node path for js file
        return Some(pkg_path);
    }

    None
}

#[cfg(test)]
mod tests {
    use crate::cli::executable::*;

    #[test]
    fn test_find_executable_returns_path_or_error() {
        // This test just ensures the function doesn't panic
        let result = find_executable();
        // Result depends on whether claude is installed
        assert!(result.is_ok() || matches!(result, Err(Error::ExecutableNotFound)));
    }

    #[test]
    fn test_is_executable_nonexistent() {
        let path = PathBuf::from("/nonexistent/path/to/claude");
        assert!(!is_executable(&path));
    }
}
