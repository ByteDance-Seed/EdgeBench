//! CAS Terminal Multiplexer
//!
//! A terminal multiplexer built on ghostty_vt + ratatui for CAS factory mode.
//! Provides direct PTY control for reliable prompt injection into Claude instances.
//!
//! # Architecture
//!
//! ```text
//! ┌─────────────────────────────────────────────────────────┐
//! │                      Multiplexer                         │
//! │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌───────────────┐ │
//! │  │  Pane   │ │  Pane   │ │  Pane   │ │     Pane      │ │
//! │  │ worker1 │ │ worker2 │ │  super  │ │   director    │ │
//! │  │  (PTY)  │ │  (PTY)  │ │  (PTY)  │ │   (native)    │ │
//! │  └─────────┘ └─────────┘ └─────────┘ └───────────────┘ │
//! └─────────────────────────────────────────────────────────┘
//! ```
//!
//! Each pane with a PTY has:
//! - A ghostty_vt Terminal for parsing and state management
//! - A direct write handle for prompt injection
//! - An associated agent name for targeting
//!
//! # Components
//!
//! - **ghostty_vt**: Handles terminal emulation (escape sequences, cursor, colors)
//! - **portable-pty**: Manages PTY processes
//! - **ratatui**: Renders the TUI output

mod error;
mod harness;
mod mux;
mod pane;
mod pty;
mod render;

pub use error::{Error, Result};
pub use harness::{HarnessCapabilities, SupervisorCli};
pub use mux::{Mux, MuxConfig, MuxEvent};
pub use pane::TerminalSnapshot;
pub use pane::{Pane, PaneBackend, PaneId, PaneKind};
pub use pty::{Pty, PtyConfig, PtyEvent, TeamsSpawnConfig};
pub use render::{LayoutDirection, Renderer};
