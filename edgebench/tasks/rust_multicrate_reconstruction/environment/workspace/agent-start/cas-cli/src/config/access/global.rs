use crate::config::*;

pub fn global_cas_dir() -> Option<std::path::PathBuf> { todo!() }

/// Load the global CAS config from ~/.config/cas/
///
/// Returns default config if the directory or config file doesn't exist.
pub fn load_global_config() -> Config { todo!() }

/// Save config to the global CAS directory (~/.config/cas/)
///
/// Creates the directory if it doesn't exist.
pub fn save_global_config(config: &Config) -> Result<(), MemError> { todo!() }

/// Check if telemetry consent has been given (either way)
///
/// Returns None if consent hasn't been asked yet, Some(true) if opted in,
/// Some(false) if opted out.
pub fn get_telemetry_consent() -> Option<bool> { todo!() }

/// Set telemetry consent in the global config
pub fn set_telemetry_consent(consent: bool) -> Result<(), MemError> { todo!() }

/// Prompt the user for telemetry consent
///
/// Returns true if user consents, false otherwise.
/// This function reads from stdin and should only be called in interactive contexts.
pub fn prompt_telemetry_consent() -> bool { todo!() }
