//! Agent color assignment aligned with Claude Code's native Agent Teams palette.
//!
//! Colors match the `--agent-color` values that Claude Code supports:
//! green, blue, yellow, cyan, magenta, red, white.
//!
//! Factory agents register their Teams color at spawn time via
//! `register_agent_color()`. Non-factory agents auto-assign from the
//! same palette in order, ensuring visual consistency between the CAS
//! TUI and Claude Code's internal agent rendering.

use ratatui::style::Color;
use std::collections::HashMap;
use std::sync::Mutex;

/// RGB values for each Claude Code Agent Teams color.
/// These are vibrant, distinct colors optimized for dark terminal backgrounds.
const TEAM_PALETTE: &[(&str, u8, u8, u8)] = &[
    ("green", 74, 222, 128),    // #4ADE80
    ("blue", 96, 165, 250),     // #60A5FA
    ("yellow", 250, 204, 21),   // #FACC15
    ("cyan", 34, 211, 238),     // #22D3EE
    ("magenta", 232, 121, 249), // #E879F9
    ("red", 248, 113, 113),     // #F87171
    ("white", 226, 232, 240),   // #E2E8F0
];

/// Order for auto-assigning colors when no explicit registration exists.
/// Supervisor gets green (index 0), workers cycle through the rest.
const AUTO_ASSIGN_ORDER: &[&str] = &["green", "blue", "yellow", "cyan", "magenta", "red", "white"];

struct ColorRegistry {
    /// Explicit registrations: agent_name -> team color name
    registered: HashMap<String, String>,
    /// Auto-assigned colors for unregistered agents: agent_name -> team color name
    auto_assigned: HashMap<String, String>,
    /// Next index into AUTO_ASSIGN_ORDER for auto-assignment
    next_index: usize,
}

impl ColorRegistry {
    fn new() -> Self { todo!() }

    fn register(&mut self, agent_name: &str, color_name: &str) { todo!() }

    fn get_color(&mut self, agent_name: &str) -> Color { todo!() }
}

static REGISTRY: Mutex<Option<ColorRegistry>> = Mutex::new(None);

/// Register an agent's color by Teams color name (e.g., "green", "blue").
///
/// Call this when spawning factory agents so the TUI renders the same
/// color that Claude Code uses internally for that agent.
pub fn register_agent_color(agent_name: &str, color_name: &str) { todo!() }

/// Get a color for an agent, consistent with Claude Code's Agent Teams palette.
///
/// Returns the registered Teams color if one was set via `register_agent_color()`,
/// otherwise auto-assigns the next color from the palette. The same agent always
/// returns the same color within a session.
pub fn get_agent_color(agent_id: &str) -> Color { todo!() }

/// Convert a Teams color name to its RGB value.
///
/// Returns a default gray for unrecognized color names.
pub fn team_color_rgb(color_name: &str) -> Color { todo!() }

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_registered_color_matches() {
        let mut registry = ColorRegistry::new();
        registry.register("swift-fox", "blue");
        let color = registry.get_color("swift-fox");
        assert_eq!(color, Color::Rgb(96, 165, 250));
    }

    #[test]
    fn test_auto_assign_cycles_palette() {
        let mut registry = ColorRegistry::new();
        let c1 = registry.get_color("agent-1");
        let c2 = registry.get_color("agent-2");
        let c3 = registry.get_color("agent-3");

        // First three auto-assigned colors: green, blue, yellow
        assert_eq!(c1, team_color_rgb("green"));
        assert_eq!(c2, team_color_rgb("blue"));
        assert_eq!(c3, team_color_rgb("yellow"));
    }

    #[test]
    fn test_same_agent_returns_same_color() {
        let mut registry = ColorRegistry::new();
        let c1 = registry.get_color("test-agent");
        let c2 = registry.get_color("test-agent");
        assert_eq!(c1, c2);
    }

    #[test]
    fn test_registered_overrides_auto() {
        let mut registry = ColorRegistry::new();
        // Auto-assign first
        let _ = registry.get_color("my-agent");
        // Then register explicitly
        registry.register("my-agent", "red");
        let color = registry.get_color("my-agent");
        assert_eq!(color, team_color_rgb("red"));
    }


    #[test]
    fn test_team_color_rgb_unknown_fallback() {
        let fallback = team_color_rgb("nonexistent");
        assert!(matches!(fallback, Color::Rgb(160, 174, 192)));
    }

}
