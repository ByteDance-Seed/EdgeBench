//! Schema migration system for CAS
//!
//! Provides versioned, trackable schema migrations that replace ad-hoc
//! ALTER TABLE statements scattered across store init() functions.
//!
//! # Usage
//!
//! ```rust,ignore
//! use cas_core::migration::{run_migrations, check_migrations, MigrationStatus};
//!
//! // Check for pending migrations
//! let status = check_migrations(&cas_dir)?;
//! println!("{} pending migrations", status.pending.len());
//!
//! // Run all pending migrations
//! run_migrations(&cas_dir, false)?;
//! ```

pub mod detector;
mod migrations;

pub use detector::detect_applied_migrations;
pub use migrations::MIGRATIONS;

use chrono::{DateTime, Utc};
use rusqlite::{Connection, params};
use std::path::Path;

use crate::error::CoreError;

/// Result type for migration operations
pub type Result<T> = std::result::Result<T, CoreError>;

/// Subsystem that a migration affects
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Subsystem {
    /// Entry storage (entries, metadata, sessions tables)
    Entries,
    /// Task storage (tasks, dependencies tables)
    Tasks,
    /// Rule storage (rules table)
    Rules,
    /// Skill storage (skills table)
    Skills,
    /// Agent coordination (agents, task_leases, lease_history tables)
    Agents,
    /// Entity/knowledge graph (entities, relationships, mentions tables)
    Entities,
    /// Task verification (verifications, verification_issues tables)
    Verification,
    /// Iteration loops (loops table)
    Loops,
    /// Git worktree management (worktrees table)
    Worktrees,
    // NOTE: Tracing has its own traces.db file and handles migrations internally
}

impl Subsystem {
    /// Get string representation for storage
    pub fn as_str(&self) -> &'static str { todo!() }
}

impl std::fmt::Display for Subsystem {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result { todo!() }
}

/// A single schema migration
#[derive(Debug, Clone)]
pub struct Migration {
    /// Unique sequential ID
    pub id: u32,
    /// Machine-readable name (e.g., "add_epoch_to_task_leases")
    pub name: &'static str,
    /// Subsystem this migration affects
    pub subsystem: Subsystem,
    /// Human-readable description
    pub description: &'static str,
    /// SQL statements to apply (forward migration)
    pub up: &'static [&'static str],
    /// Optional detection query - returns > 0 if migration already applied
    /// Used for bootstrap detection of existing databases
    pub detect: Option<&'static str>,
}

/// Record of an applied migration
#[derive(Debug, Clone)]
pub struct AppliedMigration {
    pub id: u32,
    pub name: String,
    pub subsystem: String,
    pub applied_at: DateTime<Utc>,
}

/// Status of the migration system
#[derive(Debug, Clone)]
pub struct MigrationStatus {
    /// Migrations that have been applied
    pub applied: Vec<AppliedMigration>,
    /// Migrations that are pending
    pub pending: Vec<&'static Migration>,
    /// Current schema version (highest applied migration ID)
    pub current_version: u32,
    /// Latest available version
    pub latest_version: u32,
}

impl MigrationStatus {
    /// Check if there are any pending migrations
    pub fn has_pending(&self) -> bool { todo!() }

    /// Get count of pending migrations
    pub fn pending_count(&self) -> usize { todo!() }
}

/// Schema for the migrations tracking table
const MIGRATIONS_TABLE_SCHEMA: &str = r#"
CREATE TABLE IF NOT EXISTS cas_migrations (
    id INTEGER PRIMARY KEY,
    name TEXT NOT NULL UNIQUE,
    subsystem TEXT NOT NULL,
    applied_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_migrations_subsystem ON cas_migrations(subsystem);
"#;

/// Ensure the migrations table exists
fn ensure_migrations_table(conn: &Connection) -> Result<()> { todo!() }

/// Get list of already applied migrations from the database
fn get_applied_migrations(conn: &Connection) -> Result<Vec<AppliedMigration>> { todo!() }

/// Check migration status for a CAS directory
pub fn check_migrations(cas_dir: &Path) -> Result<MigrationStatus> { todo!() }

/// Bootstrap migration tracking for an existing database
///
/// Detects which migrations have already been applied by examining
/// the database schema, and records them as applied.
///
/// This also detects migrations that were added to the codebase after
/// the database was already at a higher version (gap detection).
pub fn bootstrap_migrations(cas_dir: &Path) -> Result<usize> { todo!() }

/// Apply a single migration
fn apply_migration(conn: &Connection, migration: &Migration) -> Result<()> { todo!() }

/// Result of running migrations
#[derive(Debug, Clone)]
pub struct MigrationResult {
    /// Number of migrations applied
    pub applied_count: usize,
    /// Names of applied migrations
    pub applied_names: Vec<String>,
    /// Any errors encountered (migration name -> error message)
    pub errors: Vec<(String, String)>,
}

/// Run all pending migrations
///
/// If `dry_run` is true, returns what would be done without applying.
pub fn run_migrations(cas_dir: &Path, dry_run: bool) -> Result<MigrationResult> { todo!() }

/// Check if there are pending migrations (for startup warning)
pub fn has_pending_migrations(cas_dir: &Path) -> bool { todo!() }

#[cfg(test)]
mod tests {
    use crate::migration::*;
    use tempfile::TempDir;


    #[test]
    fn test_check_migrations_empty_db() {
        let temp = TempDir::new().unwrap();
        let status = check_migrations(temp.path()).unwrap();

        assert_eq!(status.current_version, 0);
        assert!(!status.pending.is_empty());
    }

    #[test]
    fn test_migration_dry_run() {
        let temp = TempDir::new().unwrap();

        // Create empty database
        let db_path = temp.path().join("cas.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("PRAGMA journal_mode=WAL;").unwrap();
        ensure_migrations_table(&conn).unwrap();
        drop(conn);

        let result = run_migrations(temp.path(), true).unwrap();

        // Should report pending but not apply
        assert!(result.applied_count > 0);
        assert!(result.errors.is_empty());

        // Verify nothing was actually applied
        let status = check_migrations(temp.path()).unwrap();
        assert!(status.has_pending());
    }
}
