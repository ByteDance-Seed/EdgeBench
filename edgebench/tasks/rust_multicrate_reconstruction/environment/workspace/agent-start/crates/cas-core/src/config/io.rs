use crate::config::Config;
use crate::error::CoreError;
use std::path::Path;

impl Config {
    pub fn load(cas_dir: &Path) -> Result<Self, CoreError> { todo!() }

    /// Save configuration to .cas directory
    pub fn save(&self, cas_dir: &Path) -> Result<(), CoreError> { todo!() }

    /// Get path to config file
    pub fn config_path(cas_dir: &Path) -> std::path::PathBuf { todo!() }

    /// Check if sync is disabled via environment variable
    pub fn is_sync_disabled() -> bool { todo!() }
}
