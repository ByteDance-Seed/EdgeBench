//! Theme system for CAS Terminal UI
//!
//! Provides centralized theming with dark/light/high-contrast modes,
//! semantic color tokens, and pre-composed styles.

mod agent_colors;
mod colors;
mod config;
pub mod detect;
mod icons;
mod palette;
mod styles;

pub use agent_colors::{get_agent_color, register_agent_color, team_color_rgb};
pub use colors::ColorPalette;
pub use config::{ActiveTheme, ThemeConfig, ThemeMode};
pub use detect::detect_background_theme;
pub use icons::Icons;
pub use palette::Palette;
pub use styles::Styles;
