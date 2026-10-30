//! Cloud configuration management
//!
//! Stores cloud authentication and sync state in `.cas/cloud.json`.
//!
//! # Integration Status
//! Methods ready for cloud sync feature when enabled.

// #![allow(dead_code)] // Check unused

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

use crate::error::CasError;
use crate::store::find_cas_root;

/// Get the canonical project ID from the current git repository.
///
/// This normalizes git remote URLs to a canonical format:
/// - `git@github.com:owner/repo.git` → `github.com/owner/repo`
/// - `https://github.com/owner/repo.git` → `github.com/owner/repo`
/// - `ssh://git@gitlab.com/team/project.git` → `gitlab.com/team/project`
///
/// Returns None if not in a git repository or no remote is configured.
pub fn get_project_canonical_id() -> Option<String> { todo!() }

/// Normalize a git remote URL to a canonical format.
///
/// Examples:
/// - `git@github.com:company/repo.git` → `github.com/company/repo`
/// - `https://github.com/company/repo.git` → `github.com/company/repo`
/// - `ssh://git@gitlab.com/team/project.git` → `gitlab.com/team/project`
pub fn normalize_git_remote(url: &str) -> String { todo!() }

/// Cloud configuration stored in .cas/cloud.json
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CloudConfig {
    /// Cloud API endpoint
    #[serde(default = "default_endpoint")]
    pub endpoint: String,

    /// API token for authentication
    pub token: Option<String>,

    /// User email
    pub email: Option<String>,

    /// User plan
    pub plan: Option<String>,

    /// Organization ID (for enterprise users)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub org_id: Option<String>,

    /// Organization slug (for display)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub org_slug: Option<String>,

    /// Team ID (for enterprise users)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub team_id: Option<String>,

    /// Team slug (for display)
    #[serde(skip_serializing_if = "Option::is_none")]
    pub team_slug: Option<String>,

    /// Per-team sync timestamps (team_id -> last sync time)
    #[serde(default, skip_serializing_if = "HashMap::is_empty")]
    pub team_sync_timestamps: HashMap<String, DateTime<Utc>>,

    /// Last sync timestamp for entries
    pub last_entry_sync: Option<String>,

    /// Last sync timestamp for tasks
    pub last_task_sync: Option<String>,

    /// Last sync timestamp for rules
    pub last_rule_sync: Option<String>,

    /// Last sync timestamp for skills
    pub last_skill_sync: Option<String>,
}

fn default_endpoint() -> String { todo!() }

impl Default for CloudConfig {
    fn default() -> Self { todo!() }
}

impl CloudConfig {
    /// Load cloud config from .cas/cloud.json
    pub fn load() -> Result<Self, CasError> { todo!() }

    /// Load cloud config from a specific path
    pub fn load_from(path: &Path) -> Result<Self, CasError> { todo!() }

    /// Load cloud config from a specific cas directory
    pub fn load_from_cas_dir(cas_dir: &Path) -> Result<Self, CasError> { todo!() }

    /// Save cloud config to .cas/cloud.json
    pub fn save(&self) -> Result<(), CasError> { todo!() }

    /// Save cloud config to a specific path
    pub fn save_to(&self, path: &Path) -> Result<(), CasError> { todo!() }

    /// Save cloud config to a specific cas directory
    pub fn save_to_cas_dir(&self, cas_dir: &Path) -> Result<(), CasError> { todo!() }

    /// Get the path to cloud.json
    pub fn config_path() -> Result<PathBuf, CasError> { todo!() }

    /// Check if user is logged in (has a valid token)
    pub fn is_logged_in(&self) -> bool { todo!() }

    /// Clear authentication (logout)
    pub fn logout(&mut self) { todo!() }

    /// Check if user belongs to an organization
    pub fn has_org(&self) -> bool { todo!() }

    /// Check if user belongs to a team
    pub fn has_team(&self) -> bool { todo!() }

    /// Set the current team context
    pub fn set_team(&mut self, team_id: &str, team_slug: &str) { todo!() }

    /// Clear the current team context
    pub fn clear_team(&mut self) { todo!() }

    /// Get the last sync timestamp for a specific team
    pub fn get_team_sync_timestamp(&self, team_id: &str) -> Option<DateTime<Utc>> { todo!() }

    /// Set the last sync timestamp for a specific team
    pub fn set_team_sync_timestamp(&mut self, team_id: &str, ts: DateTime<Utc>) { todo!() }

    /// Clear the sync timestamp for a specific team
    pub fn clear_team_sync_timestamp(&mut self, team_id: &str) { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::cloud::config::*;
    use tempfile::TempDir;

    #[test]
    fn test_default_config() {
        let config = CloudConfig::default();
        assert_eq!(config.endpoint, "https://cas.dev");
        assert!(config.token.is_none());
        assert!(!config.is_logged_in());
    }

    #[test]
    fn test_save_and_load() {
        let temp = TempDir::new().unwrap();
        let path = temp.path().join("cloud.json");

        let config = CloudConfig {
            token: Some("test_token".to_string()),
            email: Some("test@example.com".to_string()),
            ..Default::default()
        };

        config.save_to(&path).unwrap();

        let loaded = CloudConfig::load_from(&path).unwrap();
        assert_eq!(loaded.token, Some("test_token".to_string()));
        assert_eq!(loaded.email, Some("test@example.com".to_string()));
        assert!(loaded.is_logged_in());
    }

    #[test]
    fn test_logout() {
        let mut config = CloudConfig {
            token: Some("test_token".to_string()),
            email: Some("test@example.com".to_string()),
            ..Default::default()
        };

        assert!(config.is_logged_in());

        config.logout();

        assert!(!config.is_logged_in());
        assert!(config.token.is_none());
        assert!(config.email.is_none());
    }


    #[test]
    fn test_team_sync_timestamps() {
        let mut config = CloudConfig::default();

        // Initially no timestamps
        assert!(config.get_team_sync_timestamp("team-a").is_none());

        // Set timestamp for team-a
        let ts1 = Utc::now();
        config.set_team_sync_timestamp("team-a", ts1);
        assert_eq!(config.get_team_sync_timestamp("team-a"), Some(ts1));

        // Set timestamp for team-b
        let ts2 = Utc::now();
        config.set_team_sync_timestamp("team-b", ts2);
        assert_eq!(config.get_team_sync_timestamp("team-b"), Some(ts2));

        // team-a still has its timestamp
        assert_eq!(config.get_team_sync_timestamp("team-a"), Some(ts1));

        // Clear team-a timestamp
        config.clear_team_sync_timestamp("team-a");
        assert!(config.get_team_sync_timestamp("team-a").is_none());
        assert_eq!(config.get_team_sync_timestamp("team-b"), Some(ts2));
    }

}
