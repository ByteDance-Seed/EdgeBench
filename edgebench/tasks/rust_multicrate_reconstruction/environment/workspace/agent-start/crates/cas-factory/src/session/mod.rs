//! Session lifecycle management for factory sessions.
//!
//! SessionManager handles the full lifecycle of factory sessions:
//! - Create new sessions with metadata
//! - Pause/resume sessions for continuity
//! - Archive completed sessions
//! - Persist session state across app restarts
//!
//! Sessions are stored in `~/.cas/sessions/` as JSON files.
//!
//! # Session Types
//!
//! - **Factory**: Multi-agent sessions with supervisor and workers
//! - **Managed**: Single-agent sessions with auto-save and recording
//! - **Recording**: Playback/recording sessions for session capture

pub(crate) mod lifecycle;
pub(crate) mod resume;
pub(crate) mod state;

#[allow(unused_imports)]
pub(crate) use lifecycle::SessionManager;
#[allow(unused_imports)]
pub(crate) use resume::{
    SharedUnifiedSessionManager, UnifiedSessionConfig, UnifiedSessionManager,
    new_shared_unified_manager,
};
#[allow(unused_imports)]
pub(crate) use state::{
    AgentState, Result, SessionCache, SessionError, SessionId, SessionInfo, SessionState,
    SessionSummary, SessionType,
};

#[cfg(test)]
mod lifecycle_tests;
#[cfg(test)]
mod resume_tests;
#[cfg(test)]
mod state_tests;
