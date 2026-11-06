//! Message types for Factory client-server protocol.
//!
//! Defines all messages exchanged between Factory servers and clients
//! over WebSocket connections using MessagePack encoding.

mod core;
mod model;
#[cfg(test)]
mod tests;

pub use core::{ClientMessage, ServerMessage};
pub use model::{
    ActivityEvent, AgentSummary, CacheRow, ClientCapabilities, ClientType, ConnectionQuality,
    CursorPosition, DirectorData, ErrorCode, FileChange, PaneInfo, PaneKind, PlaybackMetadata,
    RowData, STYLE_BLINK, STYLE_BOLD, STYLE_FAINT, STYLE_INVERSE, STYLE_INVISIBLE, STYLE_ITALIC,
    STYLE_STRIKETHROUGH, STYLE_UNDERLINE, SessionInfo, SessionMode, SessionState, SourceChanges,
    StyleRun, TaskSummary, TerminalCell, TerminalSnapshot,
};

/// Helper for serde skip_serializing_if for zero values.
pub(crate) fn is_zero(val: &u32) -> bool { todo!() }
