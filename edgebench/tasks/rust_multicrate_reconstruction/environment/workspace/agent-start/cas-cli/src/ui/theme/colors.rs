//! Base color definitions for CAS themes

use ratatui::style::Color;

/// Base color palette - inspired by Linear/Raycast muted aesthetics
#[derive(Debug, Clone)]
pub struct ColorPalette {
    // Grayscale
    pub gray_50: Color,
    pub gray_100: Color,
    pub gray_200: Color,
    pub gray_300: Color,
    pub gray_400: Color,
    pub gray_500: Color,
    pub gray_600: Color,
    pub gray_700: Color,
    pub gray_800: Color,
    pub gray_900: Color,

    // Primary accent (teal - ops console)
    pub primary_100: Color,
    pub primary_200: Color,
    pub primary_300: Color,
    pub primary_400: Color,
    pub primary_500: Color,

    // Status colors
    pub success: Color,
    pub success_dim: Color,
    pub warning: Color,
    pub warning_dim: Color,
    pub error: Color,
    pub error_dim: Color,
    pub info: Color,
    pub info_dim: Color,

    // Specialty colors
    pub purple: Color,
    pub purple_dim: Color,
    pub cyan: Color,
    pub cyan_dim: Color,
    pub orange: Color,
    pub orange_dim: Color,
}

impl ColorPalette {
    /// Linear-inspired dark theme
    pub fn dark() -> Self { todo!() }

    /// Light theme variant
    pub fn light() -> Self { todo!() }

    /// High contrast accessibility variant
    pub fn high_contrast() -> Self { todo!() }
}
