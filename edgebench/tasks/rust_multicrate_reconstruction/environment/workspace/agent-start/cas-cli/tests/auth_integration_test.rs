//! Integration tests for CLI and Desktop authentication
//!
//! Tests that verify:
//! 1. Token format compatibility between CLI and Desktop
//! 2. Shared auth.json storage works correctly
//! 3. Token expiry validation works consistently
//!
//! These tests use a temporary directory to avoid affecting real auth state.

use chrono::{DateTime, Duration, Utc};
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;
use tempfile::TempDir;

#[cfg(unix)]
use std::os::unix::fs::PermissionsExt;

// =============================================================================
// Types (matching CLI cas-cli/src/auth/mod.rs)
// =============================================================================

/// CLI AuthUser struct (from cas-cli/src/auth/mod.rs)
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
struct CliAuthUser {
    id: String,
    github_id: i64,
    github_username: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    email: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    avatar_url: Option<String>,
}

/// CLI AuthToken struct (from cas-cli/src/auth/mod.rs)
#[derive(Debug, Clone, Serialize, Deserialize)]
struct CliAuthToken {
    access_token: String,
    refresh_token: String,
    expires_at: DateTime<Utc>,
    user: CliAuthUser,
}

// =============================================================================
// Types (matching Desktop cas-desktop/src-tauri/src/auth.rs)
// =============================================================================

/// Desktop AuthUser struct (from cas-desktop/src-tauri/src/auth.rs)
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
struct DesktopAuthUser {
    id: String,
    github_id: i64,
    github_username: String,
    email: Option<String>,
    avatar_url: Option<String>,
}

/// Desktop AuthToken struct (from cas-desktop/src-tauri/src/auth.rs)
/// Note: Desktop uses String for expires_at (ISO 8601 format)
#[derive(Debug, Clone, Serialize, Deserialize)]
struct DesktopAuthToken {
    access_token: String,
    refresh_token: String,
    expires_at: String,
    user: DesktopAuthUser,
}

// =============================================================================
// Test Helpers
// =============================================================================

fn create_temp_auth_dir() -> (TempDir, PathBuf) { todo!() }

fn create_cli_test_token() -> CliAuthToken { todo!() }

fn create_desktop_test_token() -> DesktopAuthToken { todo!() }

// =============================================================================
// Token Format Compatibility Tests
// =============================================================================

#[test]
fn test_cli_token_can_be_read_by_desktop() {
    // CLI writes a token, Desktop should be able to read it
    let (_temp, auth_path) = create_temp_auth_dir();

    // CLI writes token
    let cli_token = create_cli_test_token();
    let json = serde_json::to_string_pretty(&cli_token).unwrap();
    fs::write(&auth_path, &json).unwrap();

    // Desktop reads token
    let loaded_json = fs::read_to_string(&auth_path).unwrap();
    let desktop_token: DesktopAuthToken = serde_json::from_str(&loaded_json).unwrap();

    // Verify fields match
    assert_eq!(desktop_token.access_token, cli_token.access_token);
    assert_eq!(desktop_token.refresh_token, cli_token.refresh_token);
    assert_eq!(desktop_token.user.id, cli_token.user.id);
    assert_eq!(desktop_token.user.github_id, cli_token.user.github_id);
    assert_eq!(
        desktop_token.user.github_username,
        cli_token.user.github_username
    );
    assert_eq!(desktop_token.user.email, cli_token.user.email);
    assert_eq!(desktop_token.user.avatar_url, cli_token.user.avatar_url);

    // Verify expires_at is parseable
    let parsed_expires: DateTime<Utc> = desktop_token.expires_at.parse().unwrap();
    assert!(parsed_expires > Utc::now());
}



// =============================================================================
// Token Expiry Tests
// =============================================================================


#[test]
fn test_cli_nearly_expired_token() {
    // Token that expires in 3 minutes (within 5-minute buffer)
    let near_expiry_token = CliAuthToken {
        access_token: "near_expiry_token".to_string(),
        refresh_token: "refresh".to_string(),
        expires_at: Utc::now() + Duration::minutes(3),
        user: CliAuthUser {
            id: "user-123".to_string(),
            github_id: 123,
            github_username: "nearexpiry".to_string(),
            email: None,
            avatar_url: None,
        },
    };

    // CLI uses 5-minute buffer, so 3 minutes should be considered "needs refresh"
    let needs_refresh = near_expiry_token.expires_at <= Utc::now() + Duration::minutes(5);
    assert!(
        needs_refresh,
        "Token expiring in 3 minutes should need refresh"
    );
}


// =============================================================================
// File Permission Tests (Unix only)
// =============================================================================

#[test]
#[cfg(unix)]
fn test_auth_file_permissions() {
    let (_temp, auth_path) = create_temp_auth_dir();

    // Write token
    let token = create_cli_test_token();
    let json = serde_json::to_string_pretty(&token).unwrap();
    fs::write(&auth_path, &json).unwrap();

    // Set permissions to 0600 (as CLI and Desktop should do)
    let perms = fs::Permissions::from_mode(0o600);
    fs::set_permissions(&auth_path, perms).unwrap();

    // Verify permissions
    let metadata = fs::metadata(&auth_path).unwrap();
    let mode = metadata.permissions().mode() & 0o777;
    assert_eq!(mode, 0o600, "Auth file should have 0600 permissions");
}


// =============================================================================
// Optional Fields Tests
// =============================================================================

#[test]
fn test_token_without_optional_fields() {
    // Token without email and avatar_url
    let minimal_token = CliAuthToken {
        access_token: "minimal_token".to_string(),
        refresh_token: "refresh".to_string(),
        expires_at: Utc::now() + Duration::hours(1),
        user: CliAuthUser {
            id: "user-123".to_string(),
            github_id: 123,
            github_username: "minimal".to_string(),
            email: None,
            avatar_url: None,
        },
    };

    // Serialize (should skip None fields)
    let json = serde_json::to_string(&minimal_token).unwrap();
    assert!(
        !json.contains("\"email\""),
        "None email should be skipped in serialization"
    );
    assert!(
        !json.contains("\"avatar_url\""),
        "None avatar_url should be skipped in serialization"
    );

    // Desktop should still be able to read it
    let desktop_token: DesktopAuthToken = serde_json::from_str(&json).unwrap();
    assert!(desktop_token.user.email.is_none());
    assert!(desktop_token.user.avatar_url.is_none());
}


// =============================================================================
// Error Handling Tests
// =============================================================================


#[test]
fn test_load_invalid_json() {
    let (_temp, auth_path) = create_temp_auth_dir();

    // Write invalid JSON
    fs::write(&auth_path, "not valid json {{{").unwrap();

    // Attempting to parse should fail
    let content = fs::read_to_string(&auth_path).unwrap();
    let result: Result<CliAuthToken, _> = serde_json::from_str(&content);
    assert!(result.is_err(), "Parsing invalid JSON should error");
}

#[test]
fn test_load_incomplete_token() {
    let (_temp, auth_path) = create_temp_auth_dir();

    // Write JSON missing required fields
    let incomplete_json = r#"{"access_token": "test"}"#;
    fs::write(&auth_path, incomplete_json).unwrap();

    // Attempting to parse should fail
    let content = fs::read_to_string(&auth_path).unwrap();
    let result: Result<CliAuthToken, _> = serde_json::from_str(&content);
    assert!(result.is_err(), "Parsing incomplete token should error");
}

// =============================================================================
// Date Format Compatibility Tests
// =============================================================================

