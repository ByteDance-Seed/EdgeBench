//! PTY management - re-exported from cas-pty crate
//!
//! This module re-exports the cas-pty crate for backwards compatibility.
//! The PTY implementation has been extracted to allow reuse in other crates
//! like the Tauri desktop app.

pub use cas_pty::*;
