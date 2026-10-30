//! Component system for CAS CLI output
//!
//! Two-tier architecture:
//! - **Renderable**: Static output (tables, lists, status displays)
//! - **Component**: Interactive Elm Architecture (select menus, wizards)
//!
//! The **Formatter** handles all styled output, auto-detecting TTY/piped/NO_COLOR
//! and using the ActiveTheme for consistent colors.
//!
//! The **Program** runner drives interactive components with a crossterm event loop.

pub mod formatter;
pub mod header;
pub mod key_value;
pub mod layout;
pub mod list;
pub mod panel;
pub mod program;
pub mod progress;
#[cfg(test)]
mod snapshot_tests;
pub mod spinner;
pub mod status_line;
pub mod table;
#[cfg(test)]
pub mod test_helpers;
pub mod traits;
pub mod tree;

pub use formatter::{Formatter, OutputMode, terminal_width, to_crossterm_color};
pub use header::{Header, Level};
pub use key_value::KeyValue;
pub use layout::{Column, Divider, DividerStyle, Row};
pub use list::{BulletStyle, List, ListItem};
pub use panel::Panel;
pub use program::{ProgramConfig, clear_inline, render_inline_view, rerender_inline, run};
pub use progress::{ProgressBar, ProgressBarMsg};
pub use spinner::{Spinner, SpinnerMsg, SpinnerStyle};
pub use status_line::{Status, StatusGroup, StatusLine};
pub use table::{Align, Border, Table, Width};
pub use traits::{Action, Component, Renderable};
pub use tree::Tree;
