//! Comprehensive integration tests for cas-factory-protocol.
//!
//! Tests cover:
//! - Edge cases (empty data, large payloads, Unicode)
//! - All message variants and enum types
//! - Error handling (malformed messages)
//! - Complex nested types (DirectorData, SessionState)

#[path = "protocol_tests/edge_cases.rs"]
mod edge_cases;
#[path = "protocol_tests/enums_and_nested.rs"]
mod enums_and_nested;
#[path = "protocol_tests/errors_and_boundaries.rs"]
mod errors_and_boundaries;
#[path = "protocol_tests/framed_and_rows.rs"]
mod framed_and_rows;
#[path = "protocol_tests/web_flow.rs"]
mod web_flow;

pub(crate) use cas_factory_protocol::{
    ActivityEvent, AgentSummary, ClientCapabilities, ClientMessage, ClientType, CursorPosition,
    DirectorData, ErrorCode, FileChange, PROTOCOL_VERSION, PaneInfo, PaneKind, PlaybackMetadata,
    RowData, STYLE_BOLD, STYLE_FAINT, STYLE_INVERSE, STYLE_ITALIC, STYLE_STRIKETHROUGH,
    STYLE_UNDERLINE, ServerMessage, SessionMode, SessionState, SourceChanges, StyleRun,
    TaskSummary, TerminalCell, TerminalSnapshot, codec,
};
pub(crate) use std::collections::HashMap;
