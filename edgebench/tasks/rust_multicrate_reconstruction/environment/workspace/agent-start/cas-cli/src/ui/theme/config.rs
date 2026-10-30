//! Theme configuration and active theme management

use serde::{Deserialize, Serialize};

use crate::ui::theme::colors::ColorPalette;
use crate::ui::theme::palette::Palette;
use crate::ui::theme::styles::Styles;

/// Theme mode selection
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum ThemeMode {
    #[default]
    Dark,
    Light,
    HighContrast,
}

impl std::fmt::Display for ThemeMode {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

impl std::str::FromStr for ThemeMode {
    type Err = String;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Theme configuration stored in .cas/config.toml
#[derive(Debug, Clone, Default, Serialize, Deserialize)]
pub struct ThemeConfig {
    /// Theme mode: dark, light, or high_contrast
    #[serde(default)]
    pub mode: ThemeMode,
}

/// Active theme instance with computed styles
#[derive(Debug, Clone)]
pub struct ActiveTheme {
    pub mode: ThemeMode,
    pub is_dark: bool,
    pub palette: Palette,
    pub styles: Styles,
}

impl ActiveTheme {
    /// Create theme from configuration
    pub fn from_config(config: &ThemeConfig) -> Self { todo!() }

    /// Create theme from mode
    pub fn from_mode(mode: ThemeMode) -> Self { todo!() }

    /// Create default dark theme
    pub fn default_dark() -> Self { todo!() }

    /// Create default light theme
    pub fn default_light() -> Self { todo!() }

    /// Create high contrast theme
    pub fn high_contrast() -> Self { todo!() }

    /// Auto-detect the terminal background and create the appropriate theme.
    ///
    /// Uses OSC 11 terminal query, COLORFGBG env var, or defaults to dark.
    pub fn detect() -> Self { todo!() }

    /// Resolve the theme from optional config, falling back to auto-detection.
    ///
    /// When config is `Some`, the explicit mode is used (no detection).
    /// When config is `None`, auto-detection runs (OSC 11 → COLORFGBG → dark).
    pub fn resolve(config: Option<&ThemeConfig>) -> Self { todo!() }
}

impl Default for ActiveTheme {
    fn default() -> Self { todo!() }
}
