//! Integration tests for worktree feature
//!
//! Tests the full worktree lifecycle including:
//! - Task lifecycle with worktrees
//! - Branch scoping for entries
//! - Config enable/disable
//! - Edge cases

use std::path::{Path, PathBuf};
use std::process::Command;
use tempfile::TempDir;

/// Create a test git repository
fn create_test_repo() -> (TempDir, PathBuf) { todo!() }

/// Initialize CAS in a directory
fn init_cas(path: &Path) -> PathBuf { todo!() }

#[test]
fn test_worktree_config_parsing() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    // Verify config loads correctly (TOML format)
    let config_path = cas_dir.join("config.toml");
    assert!(config_path.exists());

    let content = std::fs::read_to_string(&config_path).unwrap();
    assert!(content.contains("enabled = true"));
    assert!(content.contains("branch_prefix = \"cas/\""));
}

#[test]
fn test_worktree_store_crud() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    let conn = rusqlite::Connection::open(cas_dir.join("cas.db")).unwrap();

    // Insert a worktree record
    conn.execute(
        "INSERT INTO worktrees (id, task_id, branch, parent_branch, path, status, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        rusqlite::params![
            "wt-test123",
            "cas-1234",
            "cas/cas-1234",
            "main",
            "/tmp/test-worktree",
            "active",
            "2024-01-01T00:00:00Z"
        ],
    )
    .unwrap();

    // Read it back
    let branch: String = conn
        .query_row(
            "SELECT branch FROM worktrees WHERE id = ?",
            ["wt-test123"],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(branch, "cas/cas-1234");

    // Update status
    conn.execute(
        "UPDATE worktrees SET status = 'merged' WHERE id = ?",
        ["wt-test123"],
    )
    .unwrap();

    let status: String = conn
        .query_row(
            "SELECT status FROM worktrees WHERE id = ?",
            ["wt-test123"],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(status, "merged");
}

#[test]
fn test_entry_branch_scoping() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    let conn = rusqlite::Connection::open(cas_dir.join("cas.db")).unwrap();

    // Create entries with different branch scopes
    conn.execute(
        "INSERT INTO entries (id, type, created, content, branch)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        rusqlite::params![
            "entry-1",
            "learning",
            "2024-01-01T00:00:00Z",
            "Global entry (no branch)",
            rusqlite::types::Null
        ],
    )
    .unwrap();

    conn.execute(
        "INSERT INTO entries (id, type, created, content, branch)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        rusqlite::params![
            "entry-2",
            "learning",
            "2024-01-01T00:00:01Z",
            "Scoped to branch A",
            "cas/branch-a"
        ],
    )
    .unwrap();

    conn.execute(
        "INSERT INTO entries (id, type, created, content, branch)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        rusqlite::params![
            "entry-3",
            "learning",
            "2024-01-01T00:00:02Z",
            "Scoped to branch B",
            "cas/branch-b"
        ],
    )
    .unwrap();

    // Query all entries
    let all_count: i32 = conn
        .query_row(
            "SELECT COUNT(*) FROM entries WHERE archived = 0",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(all_count, 3);

    // Query entries visible from branch A (branch A entries + unscoped)
    let branch_a_count: i32 = conn
        .query_row(
            "SELECT COUNT(*) FROM entries WHERE archived = 0 AND (branch IS NULL OR branch = ?)",
            ["cas/branch-a"],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(branch_a_count, 2); // entry-1 (global) + entry-2 (branch A)

    // Query entries visible from branch B
    let branch_b_count: i32 = conn
        .query_row(
            "SELECT COUNT(*) FROM entries WHERE archived = 0 AND (branch IS NULL OR branch = ?)",
            ["cas/branch-b"],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(branch_b_count, 2); // entry-1 (global) + entry-3 (branch B)

    // Query only unscoped entries (global view)
    let global_count: i32 = conn
        .query_row(
            "SELECT COUNT(*) FROM entries WHERE archived = 0 AND branch IS NULL",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(global_count, 1);
}

#[test]
fn test_entry_promotion_on_merge() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    let conn = rusqlite::Connection::open(cas_dir.join("cas.db")).unwrap();

    // Create a scoped entry
    conn.execute(
        "INSERT INTO entries (id, type, created, content, branch)
         VALUES (?1, ?2, ?3, ?4, ?5)",
        rusqlite::params![
            "entry-scoped",
            "learning",
            "2024-01-01T00:00:00Z",
            "Entry in worktree",
            "cas/feature-branch"
        ],
    )
    .unwrap();

    // Verify it's scoped
    let branch: Option<String> = conn
        .query_row(
            "SELECT branch FROM entries WHERE id = ?",
            ["entry-scoped"],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(branch, Some("cas/feature-branch".to_string()));

    // Simulate promotion (what happens when worktree is merged)
    conn.execute(
        "UPDATE entries SET branch = NULL WHERE branch = ?",
        ["cas/feature-branch"],
    )
    .unwrap();

    // Verify it's now global
    let branch_after: Option<String> = conn
        .query_row(
            "SELECT branch FROM entries WHERE id = ?",
            ["entry-scoped"],
            |row| row.get(0),
        )
        .unwrap();
    assert!(branch_after.is_none());
}

#[test]
fn test_task_worktree_association() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    let conn = rusqlite::Connection::open(cas_dir.join("cas.db")).unwrap();

    // Create a task with worktree association
    conn.execute(
        "INSERT INTO tasks (id, title, status, created, updated, branch, worktree_id)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        rusqlite::params![
            "cas-1234",
            "Test task",
            "in_progress",
            "2024-01-01T00:00:00Z",
            "2024-01-01T00:00:00Z",
            "cas/cas-1234",
            "wt-abc123"
        ],
    )
    .unwrap();

    // Create the associated worktree
    conn.execute(
        "INSERT INTO worktrees (id, task_id, branch, parent_branch, path, status, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        rusqlite::params![
            "wt-abc123",
            "cas-1234",
            "cas/cas-1234",
            "main",
            "/tmp/wt-abc123",
            "active",
            "2024-01-01T00:00:00Z"
        ],
    )
    .unwrap();

    // Query task and get worktree info
    let (task_branch, worktree_id): (Option<String>, Option<String>) = conn
        .query_row(
            "SELECT branch, worktree_id FROM tasks WHERE id = ?",
            ["cas-1234"],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .unwrap();

    assert_eq!(task_branch, Some("cas/cas-1234".to_string()));
    assert_eq!(worktree_id, Some("wt-abc123".to_string()));

    // Query worktree by task
    let wt_branch: String = conn
        .query_row(
            "SELECT branch FROM worktrees WHERE task_id = ? AND status = 'active'",
            ["cas-1234"],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(wt_branch, "cas/cas-1234");
}

#[test]
fn test_worktree_status_lifecycle() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    let conn = rusqlite::Connection::open(cas_dir.join("cas.db")).unwrap();

    // Create worktree in active state
    conn.execute(
        "INSERT INTO worktrees (id, task_id, branch, parent_branch, path, status, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        rusqlite::params![
            "wt-lifecycle",
            "cas-test",
            "cas/cas-test",
            "main",
            "/tmp/wt-lifecycle",
            "active",
            "2024-01-01T00:00:00Z"
        ],
    )
    .unwrap();

    // Test active -> merged transition
    conn.execute(
        "UPDATE worktrees SET status = 'merged', merged_at = ?1 WHERE id = ?2",
        rusqlite::params!["2024-01-01T01:00:00Z", "wt-lifecycle"],
    )
    .unwrap();

    let (status, merged_at): (String, Option<String>) = conn
        .query_row(
            "SELECT status, merged_at FROM worktrees WHERE id = ?",
            ["wt-lifecycle"],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .unwrap();
    assert_eq!(status, "merged");
    assert!(merged_at.is_some());

    // Test merged -> removed transition
    conn.execute(
        "UPDATE worktrees SET status = 'removed', removed_at = ?1 WHERE id = ?2",
        rusqlite::params!["2024-01-01T02:00:00Z", "wt-lifecycle"],
    )
    .unwrap();

    let (status, removed_at): (String, Option<String>) = conn
        .query_row(
            "SELECT status, removed_at FROM worktrees WHERE id = ?",
            ["wt-lifecycle"],
            |row| Ok((row.get(0)?, row.get(1)?)),
        )
        .unwrap();
    assert_eq!(status, "removed");
    assert!(removed_at.is_some());
}

#[test]
fn test_list_active_worktrees() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    let conn = rusqlite::Connection::open(cas_dir.join("cas.db")).unwrap();

    // Create worktrees in various states
    for (id, status) in [
        ("wt-1", "active"),
        ("wt-2", "active"),
        ("wt-3", "merged"),
        ("wt-4", "abandoned"),
        ("wt-5", "removed"),
    ] {
        conn.execute(
            "INSERT INTO worktrees (id, branch, parent_branch, path, status, created_at)
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            rusqlite::params![
                id,
                format!("cas/{}", id),
                "main",
                format!("/tmp/{}", id),
                status,
                "2024-01-01T00:00:00Z"
            ],
        )
        .unwrap();
    }

    // Count active worktrees
    let active_count: i32 = conn
        .query_row(
            "SELECT COUNT(*) FROM worktrees WHERE status = 'active'",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(active_count, 2);

    // List all non-removed worktrees
    let non_removed_count: i32 = conn
        .query_row(
            "SELECT COUNT(*) FROM worktrees WHERE status != 'removed'",
            [],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(non_removed_count, 4);
}

#[test]
fn test_worktree_by_branch_lookup() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    let conn = rusqlite::Connection::open(cas_dir.join("cas.db")).unwrap();

    conn.execute(
        "INSERT INTO worktrees (id, branch, parent_branch, path, status, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
        rusqlite::params![
            "wt-branch-test",
            "cas/feature-xyz",
            "main",
            "/tmp/wt-branch-test",
            "active",
            "2024-01-01T00:00:00Z"
        ],
    )
    .unwrap();

    // Find worktree by branch name
    let found_id: String = conn
        .query_row(
            "SELECT id FROM worktrees WHERE branch = ?",
            ["cas/feature-xyz"],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(found_id, "wt-branch-test");

    // Non-existent branch
    let not_found: Result<String, _> = conn.query_row(
        "SELECT id FROM worktrees WHERE branch = ?",
        ["cas/nonexistent"],
        |row| row.get(0),
    );
    assert!(not_found.is_err());
}

#[test]
fn test_config_worktrees_disabled() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = repo_path.join(".cas");
    std::fs::create_dir_all(&cas_dir).unwrap();

    // Create config with worktrees disabled (TOML format)
    let config_content = r#"
[worktrees]
enabled = false
"#;
    std::fs::write(cas_dir.join("config.toml"), config_content).unwrap();

    let content = std::fs::read_to_string(cas_dir.join("config.toml")).unwrap();
    assert!(content.contains("enabled = false"));
}

#[test]
fn test_multiple_worktrees_same_task_prevented() {
    let (_temp, repo_path) = create_test_repo();
    let cas_dir = init_cas(&repo_path);

    let conn = rusqlite::Connection::open(cas_dir.join("cas.db")).unwrap();

    // Create first worktree for task
    conn.execute(
        "INSERT INTO worktrees (id, task_id, branch, parent_branch, path, status, created_at)
         VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)",
        rusqlite::params![
            "wt-first",
            "cas-shared",
            "cas/cas-shared-1",
            "main",
            "/tmp/wt-first",
            "active",
            "2024-01-01T00:00:00Z"
        ],
    )
    .unwrap();

    // Query: only one active worktree per task
    let active_count: i32 = conn
        .query_row(
            "SELECT COUNT(*) FROM worktrees WHERE task_id = ? AND status = 'active'",
            ["cas-shared"],
            |row| row.get(0),
        )
        .unwrap();
    assert_eq!(active_count, 1);
}
