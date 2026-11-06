//! Git worktree management for CAS
//!
//! This module provides functionality for creating, managing, and cleaning up
//! git worktrees associated with CAS tasks. It enables isolated development
//! environments for each task.
//!
//! ## Git Submodules
//!
//! When creating worktrees, this module automatically initializes git submodules
//! using `git submodule update --init --recursive`. This is necessary because
//! `git worktree add` does not populate submodule contents.
//!
//! If submodule initialization fails (e.g., due to network issues), a warning
//! is printed to stderr but worktree creation continues. This allows workers
//! to use the worktree for tasks that don't require vendored submodules.
//!
//! ### Manual Submodule Setup
//!
//! If you need to build components that depend on vendored submodules (like
//! `ghostty_vt_sys`), run the following in your worktree:
//!
//! ```bash
//! git submodule update --init --recursive
//! ```
//!
//! The `ghostty_vt_sys/build.rs` will provide a clear error message if vendor
//! files are missing.

pub mod git;
mod manager;

pub use git::{GitError, GitOperations};
pub use manager::{WorktreeConfig, WorktreeManager, WorktreeResult};
