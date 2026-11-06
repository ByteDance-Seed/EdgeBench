//! Local device identity persistence
//!
//! Stores device registration info in `~/.config/cas/device.json`.
//! This is global (not per-project) since a device is a machine, not a repo.

use serde::{Deserialize, Serialize};
use std::fs;
use std::path::PathBuf;

use crate::error::CasError;

/// Local device identity stored on disk
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct DeviceConfig {
    /// Device ID from the cloud (UUID)
    pub device_id: String,

    /// Human-readable device name
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,

    /// When this device was first registered
    pub registered_at: String,
}

impl DeviceConfig {
    /// Load device config from `~/.config/cas/device.json`
    pub fn load() -> Result<Option<Self>, CasError> { todo!() }

    /// Save device config to `~/.config/cas/device.json`
    pub fn save(&self) -> Result<(), CasError> { todo!() }

    /// Delete device config (on deregister)
    pub fn delete() -> Result<(), CasError> { todo!() }

    /// Get the path to device.json
    pub fn config_path() -> Result<PathBuf, CasError> { todo!() }

    /// Generate a machine hash from system info
    pub fn machine_hash() -> String { todo!() }

    /// Get current hostname
    pub fn hostname() -> Option<String> { todo!() }

    /// Get current OS
    pub fn os() -> String { todo!() }

    /// Get current architecture
    pub fn arch() -> String { todo!() }

    /// Get current CAS version
    pub fn cas_version() -> String { todo!() }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tempfile::TempDir;

    #[test]
    fn test_machine_hash_is_stable() {
        let hash1 = DeviceConfig::machine_hash();
        let hash2 = DeviceConfig::machine_hash();
        assert_eq!(hash1, hash2);
        assert_eq!(hash1.len(), 16); // 16 hex chars
    }

    #[test]
    fn test_save_and_load() {
        let temp = TempDir::new().unwrap();
        let path = temp.path().join("device.json");

        let config = DeviceConfig {
            device_id: "test-device-123".to_string(),
            name: Some("My Laptop".to_string()),
            registered_at: "2026-02-19T00:00:00Z".to_string(),
        };

        let content = serde_json::to_string_pretty(&config).unwrap();
        std::fs::write(&path, content).unwrap();

        let loaded_content = std::fs::read_to_string(&path).unwrap();
        let loaded: DeviceConfig = serde_json::from_str(&loaded_content).unwrap();
        assert_eq!(loaded.device_id, "test-device-123");
        assert_eq!(loaded.name, Some("My Laptop".to_string()));
    }

    #[test]
    fn test_system_info() {
        assert!(!DeviceConfig::os().is_empty());
        assert!(!DeviceConfig::arch().is_empty());
        assert!(!DeviceConfig::cas_version().is_empty());
    }
}
