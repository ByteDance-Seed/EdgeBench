//! Utility functions for widget rendering

use chrono::{DateTime, Utc};
use ratatui::style::Color;

use crate::ui::theme::Palette;
use cas_types::Priority;

/// Truncate a string to max length with ellipsis
pub fn truncate(s: &str, max_len: usize) -> String { todo!() }

/// Truncate a string to fit within a width, accounting for prefix characters
pub fn truncate_to_width(s: &str, width: u16, prefix_chars: usize) -> String { todo!() }

fn prefix_at_char_boundary(s: &str, max_bytes: usize) -> &str { todo!() }

/// Format a datetime as relative time (e.g., "5m", "2h", "3d")
pub fn format_relative(dt: DateTime<Utc>) -> String { todo!() }

/// Get color for a task priority
pub fn priority_color(priority: Priority, palette: &Palette) -> Color { todo!() }

/// Get color for an event type
pub fn event_type_color(event_type: &cas_types::EventType, palette: &Palette) -> Color { todo!() }

#[cfg(test)]
mod tests {
    use super::{truncate, truncate_to_width};

    #[test]
    fn truncate_handles_unicode_boundary() {
        let value = format!("{}✅ trailing", "a".repeat(99));
        assert_eq!(truncate(&value, 103), format!("{}...", "a".repeat(99)));
    }

    #[test]
    fn truncate_to_width_handles_unicode_boundary() {
        let value = format!("{}✅ trailing", "a".repeat(99));
        // width=106, prefix_chars=0 => available=103 => cut point would be byte 100 without boundary check
        assert_eq!(
            truncate_to_width(&value, 106, 0),
            format!("{}...", "a".repeat(99))
        );
    }
}
