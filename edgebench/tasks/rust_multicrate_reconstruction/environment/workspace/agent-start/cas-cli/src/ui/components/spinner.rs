//! Spinner — animated indeterminate progress indicator
//!
//! Implements the Component trait for interactive use with the Program runner.
//! In plain mode, prints simple text without animation.

use std::io;
use std::time::Instant;

use super::formatter::{Formatter, OutputMode};
use super::traits::{Action, Component, Renderable};
use crate::ui::theme::Icons;

/// Spinner animation style
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum SpinnerStyle {
    /// Braille dots animation (default): ⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏
    #[default]
    Dots,
    /// Line animation: | / - \
    Line,
    /// Circle phases: ◐ ◓ ◑ ◒
    Circle,
}

impl SpinnerStyle {
    fn frames(&self) -> &'static [&'static str] { todo!() }
}

/// Current state of the spinner
#[derive(Debug, Clone, PartialEq, Eq)]
enum SpinnerState {
    /// Actively spinning with animation
    Spinning,
    /// Completed successfully
    Completed,
    /// Failed with error
    Failed,
}

/// Messages the Spinner component responds to
pub enum SpinnerMsg {
    /// Advance the animation frame (sent by tick timer)
    Tick,
    /// Update the displayed message
    SetMessage(String),
    /// Mark as completed with a final message
    Complete(String),
    /// Mark as failed with an error message
    Fail(String),
    /// Stop the spinner
    Stop,
}

/// Animated spinner with message, replacing indicatif ProgressBar spinner.
///
/// In styled mode, animates with braille/line/circle frames and themed colors.
/// In plain mode, prints "Working..." then the final status.
///
/// ```ignore
/// use cas_cli::ui::components::spinner::{Spinner, SpinnerMsg};
/// use cas_cli::ui::components::program::{ProgramConfig, run};
///
/// let mut spinner = Spinner::new("Loading data...");
/// // Drive with Program runner, sending SpinnerMsg::Tick on each tick
/// ```
pub struct Spinner {
    message: String,
    style: SpinnerStyle,
    state: SpinnerState,
    frame_index: usize,
    final_message: String,
    started_at: Instant,
}

impl Spinner {
    /// Create a new spinner with the given message.
    pub fn new(message: impl Into<String>) -> Self { todo!() }

    /// Set the spinner animation style.
    pub fn with_style(mut self, style: SpinnerStyle) -> Self { todo!() }

    /// Get the current message.
    pub fn message(&self) -> &str { todo!() }

    /// Whether the spinner has finished (completed or failed).
    pub fn is_finished(&self) -> bool { todo!() }

    /// Elapsed time since spinner was created.
    pub fn elapsed(&self) -> std::time::Duration { todo!() }

    fn current_frame(&self) -> &'static str { todo!() }
}

impl Component for Spinner {
    type Msg = SpinnerMsg;
    type Output = bool; // true = completed, false = failed/stopped

    fn update(&mut self, msg: SpinnerMsg) -> Action<SpinnerMsg> { todo!() }

    fn view(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }

    fn output(&self) -> bool { todo!() }
}

/// Static spinner for non-interactive contexts (renders a single snapshot).
///
/// Useful for rendering a spinner state in a composed layout without
/// the Program event loop.
impl Renderable for Spinner {
    fn render(&self, fmt: &mut Formatter) -> io::Result<()> { todo!() }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_spinner_new() {
        let spinner = Spinner::new("Loading...");
        assert_eq!(spinner.message(), "Loading...");
        assert!(!spinner.is_finished());
    }

    #[test]
    fn test_spinner_with_style() {
        let spinner = Spinner::new("test").with_style(SpinnerStyle::Line);
        assert_eq!(spinner.style, SpinnerStyle::Line);
    }


    #[test]
    fn test_spinner_tick_wraps_around() {
        let mut spinner = Spinner::new("test");
        let frame_count = spinner.style.frames().len();

        for _ in 0..frame_count {
            spinner.update(SpinnerMsg::Tick);
        }
        assert_eq!(spinner.frame_index, 0);
    }

    #[test]
    fn test_spinner_set_message() {
        let mut spinner = Spinner::new("initial");
        spinner.update(SpinnerMsg::SetMessage("updated".to_string()));
        assert_eq!(spinner.message(), "updated");
    }

    #[test]
    fn test_spinner_complete() {
        let mut spinner = Spinner::new("Loading");
        let action = spinner.update(SpinnerMsg::Complete("All done".to_string()));

        assert!(matches!(action, Action::Quit));
        assert!(spinner.is_finished());
        assert!(spinner.output()); // true = completed
    }



    #[test]
    fn test_spinner_tick_ignored_after_complete() {
        let mut spinner = Spinner::new("Loading");
        spinner.update(SpinnerMsg::Complete("Done".to_string()));
        let frame_before = spinner.frame_index;
        spinner.update(SpinnerMsg::Tick);
        assert_eq!(spinner.frame_index, frame_before);
    }


    #[test]
    fn test_spinner_view_completed_plain() {
        let mut spinner = Spinner::new("Loading");
        spinner.update(SpinnerMsg::Complete("All loaded".to_string()));
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            spinner.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "  Done. All loaded\n");
    }

    #[test]
    fn test_spinner_view_failed_plain() {
        let mut spinner = Spinner::new("Loading");
        spinner.update(SpinnerMsg::Fail("Connection lost".to_string()));
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            spinner.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert_eq!(output, "  Failed. Connection lost\n");
    }

    #[test]
    fn test_spinner_view_spinning_styled() {
        use crate::ui::theme::ActiveTheme;

        let spinner = Spinner::new("Syncing");
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            spinner.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Syncing"));
        assert!(output.contains("\x1b[")); // ANSI escape
    }

    #[test]
    fn test_spinner_view_completed_styled() {
        use crate::ui::theme::ActiveTheme;

        let mut spinner = Spinner::new("Syncing");
        spinner.update(SpinnerMsg::Complete("Synced".to_string()));
        let theme = ActiveTheme::default_dark();
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::styled(&mut buf, theme);
            spinner.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Synced"));
        assert!(output.contains("\x1b["));
    }

    #[test]
    fn test_spinner_renderable() {
        let spinner = Spinner::new("test");
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            spinner.render(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Working... test"));
    }

    #[test]
    fn test_spinner_complete_with_empty_final_uses_original() {
        let mut spinner = Spinner::new("Original message");
        spinner.update(SpinnerMsg::Complete(String::new()));
        let mut buf = Vec::new();
        {
            let mut fmt = Formatter::plain(&mut buf);
            spinner.view(&mut fmt).unwrap();
        }
        let output = String::from_utf8(buf).unwrap();
        assert!(output.contains("Original message"));
    }

    #[test]
    fn test_spinner_styles_have_frames() {
        assert!(!SpinnerStyle::Dots.frames().is_empty());
        assert!(!SpinnerStyle::Line.frames().is_empty());
        assert!(!SpinnerStyle::Circle.frames().is_empty());
    }

    #[test]
    fn test_spinner_elapsed() {
        let spinner = Spinner::new("test");
        let elapsed = spinner.elapsed();
        // Should be very small (just created)
        assert!(elapsed.as_secs() < 1);
    }
}
