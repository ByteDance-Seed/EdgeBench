//! Schema migration system for CAS
//!
//! Provides versioned, trackable schema migrations that replace ad-hoc
//! ALTER TABLE statements scattered across store init() functions.
//!
//! # Usage
//!
//! ```rust,ignore
//! use cas::migration::{run_migrations, check_migrations, MigrationStatus};
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

use crate::error::CasError;

/// Result type for migration operations
pub type Result<T> = std::result::Result<T, CasError>;

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
    /// Code analysis (code_files, code_symbols, code_relationships tables)
    Code,
    /// Activity events for sidecar feed
    Events,
    /// Factory recording text search
    Recording,
    /// Terminal recordings for time-travel playback
    Recordings,
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

/// Check if the database has been initialized with base schemas.
///
/// Returns true if core tables (entries, rules, tasks) exist,
/// indicating `cas init` has been run.
fn is_db_initialized(conn: &Connection) -> bool { todo!() }

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

        // Initialize CAS properly (creates base tables)
        crate::store::init_cas_dir(temp.path()).unwrap();

        let result = run_migrations(temp.path().join(".cas").as_path(), true).unwrap();

        // Should report pending but not apply
        // (init_cas_dir already runs migrations, so pending may be 0)
        assert!(result.errors.is_empty());
    }

    #[test]
    fn test_detect_already_applied_migration_via_schema() {
        // Test that migrations are detected as applied even after bootstrap,
        // if the schema change was made before the migration existed.
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("cas.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("PRAGMA journal_mode=WAL;").unwrap();
        ensure_migrations_table(&conn).unwrap();

        // Create a table with a column that a migration would add
        conn.execute_batch("CREATE TABLE test_table (id INTEGER PRIMARY KEY, test_column TEXT);")
            .unwrap();

        // Simulate a migration that's NOT recorded but column exists
        // This is the scenario: schema was updated before migration system existed
        conn.execute(
            "INSERT INTO cas_migrations (id, name, subsystem, applied_at) VALUES (999, 'fake_migration', 'test', 'TEST')",
            [],
        )
        .unwrap();
        drop(conn);

        // Now check_migrations should detect via schema that column exists
        // and NOT return the migration as pending (using detect query)
        // Note: We can't test with actual migrations without more setup,
        // but we can verify the detection mechanism works by checking
        // that the code path is exercised
        let status = check_migrations(temp.path()).unwrap();

        // The key assertion: migrations with detect queries that return > 0
        // should not be in pending, even if not in cas_migrations
        // Since we don't have the actual schema, all real migrations
        // will still be pending, but no errors from duplicate columns
        assert!(!status.applied.is_empty()); // At least our fake migration
    }

    #[test]
    fn test_run_migrations_rejects_uninitialized_db() {
        // run_migrations should refuse to run on a database where
        // cas init hasn't been run (no base tables)
        let temp = TempDir::new().unwrap();

        // Create an empty database with only the migrations table
        let db_path = temp.path().join("cas.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("PRAGMA journal_mode=WAL;").unwrap();
        ensure_migrations_table(&conn).unwrap();
        drop(conn);

        // Should fail with NotInitialized error
        let result = run_migrations(temp.path(), false);
        assert!(result.is_err());
        assert!(
            matches!(result.unwrap_err(), CasError::NotInitialized),
            "Expected NotInitialized error"
        );
    }

    #[test]
    fn test_failing_migration_rolls_back_cleanly() {
        let temp = TempDir::new().unwrap();
        let db_path = temp.path().join("cas.db");
        let conn = Connection::open(&db_path).unwrap();
        conn.execute_batch("PRAGMA journal_mode=WAL;").unwrap();
        ensure_migrations_table(&conn).unwrap();

        // Create base tables so migration flow is considered initialized.
        conn.execute_batch(
            "CREATE TABLE entries (id TEXT PRIMARY KEY);
             CREATE TABLE rules (id TEXT PRIMARY KEY);
             CREATE TABLE tasks (id TEXT PRIMARY KEY);",
        )
        .unwrap();

        let failing = Migration {
            id: 999_999,
            name: "test_failing_migration",
            subsystem: Subsystem::Tasks,
            description: "test migration that should fail and roll back",
            up: &[
                "CREATE TABLE should_not_exist (id INTEGER PRIMARY KEY)",
                "THIS IS INVALID SQL",
            ],
            detect: None,
        };

        conn.execute("BEGIN IMMEDIATE", []).unwrap();
        let result = apply_migration(&conn, &failing);
        assert!(result.is_err(), "migration should fail");
        conn.execute("ROLLBACK", []).unwrap();

        let table_exists: i64 = conn
            .query_row(
                "SELECT COUNT(*) FROM sqlite_master WHERE type='table' AND name='should_not_exist'",
                [],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(table_exists, 0, "failed migration should be rolled back");

        let recorded: i64 = conn
            .query_row(
                "SELECT COUNT(*) FROM cas_migrations WHERE id = ?",
                [failing.id],
                |row| row.get(0),
            )
            .unwrap();
        assert_eq!(recorded, 0, "failed migration must not be recorded");
    }
}
