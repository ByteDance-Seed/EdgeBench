//! Screen buffer and terminal parsing
//!
//! This module provides the core data model for representing terminal state:
//!
//! - [`ScreenBuffer`] - Grid of cells with cursor and attributes
//! - [`Cell`] - Individual terminal cell with character and style
//! - [`VtParser`] - Parses VT escape sequences into buffer updates
//! - [`Snapshot`] - Serializable screen state for testing

mod buffer;
mod cell;
mod parser;
mod snapshot;

pub use buffer::{Attr, CursorPos, FrameMetadata, Pen, ScreenBuffer, TermSize};
pub use cell::{Cell, CellAttrs, Color};
pub use parser::VtParser;
pub use snapshot::{DiffItem, Frame, FrameHistory, Snapshot, SnapshotDiff, SnapshotMetadata};
