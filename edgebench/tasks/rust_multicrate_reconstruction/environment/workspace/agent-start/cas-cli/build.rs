//! Build script for CAS
//!
//! Captures git commit hash and build timestamp for version info.
//! Also loads telemetry keys from .env file for compile-time embedding.

use std::process::Command;

fn main() {
    // Load .env file if present (for telemetry keys)
    load_env_file();

    // Get git commit hash
    let git_hash = Command::new("git")
        .args(["rev-parse", "--short=7", "HEAD"])
        .output()
        .ok()
        .and_then(|o| String::from_utf8(o.stdout).ok())
        .map(|s| s.trim().to_string())
        .unwrap_or_else(|| "unknown".to_string());

    // Check if working directory is dirty
    let is_dirty = Command::new("git")
        .args(["status", "--porcelain"])
        .output()
        .ok()
        .map(|o| !o.stdout.is_empty())
        .unwrap_or(false);

    let git_info = if is_dirty {
        format!("{git_hash}-dirty")
    } else {
        git_hash
    };

    // Get build date
    let build_date = chrono::Utc::now().format("%Y-%m-%d").to_string();

    // Export as environment variables for compilation
    println!("cargo:rustc-env=CAS_GIT_HASH={git_info}");
    println!("cargo:rustc-env=CAS_BUILD_DATE={build_date}");

    // Rebuild if git HEAD changes
    println!("cargo:rerun-if-changed=../.git/HEAD");
    println!("cargo:rerun-if-changed=../.git/index");

    // Rebuild if .env changes
    println!("cargo:rerun-if-changed=../.env");
    println!("cargo:rerun-if-changed=.env");
}

/// Load telemetry keys from .env file and pass to compiler
fn load_env_file() {
    // Try project root .env first, then cas-cli/.env
    let env_paths = ["../.env", ".env"];

    for path in env_paths {
        if std::path::Path::new(path).exists() {
            if let Ok(iter) = dotenvy::from_filename_iter(path) {
                for item in iter.flatten() {
                    let (key, value) = item;
                    // Only pass through telemetry-related keys
                    if key == "CAS_POSTHOG_API_KEY"
                        || key == "CAS_SENTRY_DSN"
                        || key == "POSTHOG_API_KEY"
                        || key == "SENTRY_DSN"
                    {
                        println!("cargo:rustc-env={key}={value}");
                    }
                }
            }
            break; // Use first .env found
        }
    }
}
