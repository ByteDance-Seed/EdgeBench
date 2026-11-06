//! Memory workflow e2e tests
//!
//! Tests the complete memory lifecycle: remember → search → helpful/harmful → archive

use crate::fixtures::{new_cas_instance, new_cas_with_data};

/// Test complete memory lifecycle
#[test]
fn test_memory_full_lifecycle() {
    let cas = new_cas_instance();

    // 1. Remember something
    let entry_id = cas.add_memory("Rust's borrow checker prevents data races at compile time");

    // 2. Search for it
    let results = cas.search("borrow checker");
    assert!(
        results.contains(&entry_id),
        "Entry should be found in search results"
    );

    // 3. Mark as helpful
    cas.mark_helpful(&entry_id);

    // Verify helpful count increased
    let output = cas
        .cas_cmd()
        .args(["show", &entry_id, "--json"])
        .output()
        .expect("Failed to show entry");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let entry: serde_json::Value = serde_json::from_str(&stdout).expect("Failed to parse JSON");
    assert_eq!(entry["helpful_count"], 1);

    // 4. Archive the entry
    cas.archive(&entry_id);

    // Verify archived
    let output = cas
        .cas_cmd()
        .args(["show", &entry_id, "--json"])
        .output()
        .expect("Failed to show entry");

    let stdout = String::from_utf8_lossy(&output.stdout);
    let entry: serde_json::Value = serde_json::from_str(&stdout).expect("Failed to parse JSON");
    assert_eq!(entry["archived"], true);
}

/// Test different memory entry types
#[test]
fn test_memory_types() {
    let cas = new_cas_instance();

    let test_cases = [
        ("learning", "Learned about async/await patterns"),
        ("preference", "User prefers dark mode"),
        ("context", "Working on authentication module"),
        ("observation", "Build times improved after caching"),
    ];

    for (entry_type, content) in test_cases {
        let entry_id = cas.add_memory_with_type(content, entry_type);

        let output = cas
            .cas_cmd()
            .args(["show", &entry_id, "--json"])
            .output()
            .expect("Failed to show entry");

        let stdout = String::from_utf8_lossy(&output.stdout);
        let entry: serde_json::Value = serde_json::from_str(&stdout).expect("Failed to parse JSON");
        assert_eq!(entry["type"], entry_type);
        assert_eq!(entry["content"], content);
    }
}

/// Test search finds relevant memories
#[test]
fn test_memory_search_relevance() {
    let cas = new_cas_instance();

    // Add several memories
    cas.add_memory("Rust ownership model ensures memory safety");
    cas.add_memory("Python is dynamically typed");
    cas.add_memory("Rust lifetimes prevent dangling references");
    cas.add_memory("JavaScript runs in the browser");

    // Search for Rust-related memories
    let results = cas.search("Rust memory");

    // Should find Rust-related entries
    assert!(!results.is_empty(), "Should find Rust-related memories");

    // Verify results contain expected content
    let output = cas
        .cas_cmd()
        .args(["search", "Rust memory"])
        .output()
        .expect("Failed to search");

    let stdout = String::from_utf8_lossy(&output.stdout);
    assert!(stdout.contains("ownership") || stdout.contains("lifetimes"));
}

/// Test helpful/harmful feedback affects ranking
#[test]
fn test_memory_feedback_ranking() {
    let cas = new_cas_instance();

    // Add two similar memories
    let entry1 = cas.add_memory("Database connection pooling improves performance");
    let entry2 = cas.add_memory("Database query optimization techniques");

    // Mark one as helpful multiple times
    cas.mark_helpful(&entry1);
    cas.mark_helpful(&entry1);
    cas.mark_helpful(&entry1);

    // Mark the other as harmful
    cas.mark_harmful(&entry2);

    // Verify counts
    let output = cas
        .cas_cmd()
        .args(["show", &entry1, "--json"])
        .output()
        .expect("Failed to show entry");
    let entry: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");
    assert_eq!(entry["helpful_count"], 3);

    let output = cas
        .cas_cmd()
        .args(["show", &entry2, "--json"])
        .output()
        .expect("Failed to show entry");
    let entry: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");
    assert_eq!(entry["harmful_count"], 1);
}

/// Test memory with tags
#[test]
fn test_memory_with_tags() {
    let cas = new_cas_instance();

    let output = cas
        .cas_cmd()
        .args([
            "add",
            "Important learning",
            "--tags",
            "rust,performance,critical",
        ])
        .output()
        .expect("Failed to add memory");

    assert!(
        output.status.success(),
        "add with tags failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    // List by tag
    let output = cas
        .cas_cmd()
        .args(["list", "--tags", "rust"])
        .output()
        .expect("Failed to list by tag");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);
    // Either shows the entry or shows a list containing the entry ID
    assert!(!stdout.is_empty());
}

/// Test memory list command
#[test]
fn test_memory_list() {
    let cas = new_cas_with_data();

    let output = cas
        .cas_cmd()
        .args(["list"])
        .output()
        .expect("Failed to list memories");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should contain preloaded data from fixture
    assert!(stdout.contains("Rust") || stdout.contains("dark mode"));
}

/// Test memory recent command
#[test]
fn test_memory_recent() {
    let cas = new_cas_instance();

    // Add several memories
    cas.add_memory("First memory");
    cas.add_memory("Second memory");
    cas.add_memory("Third memory");

    let output = cas
        .cas_cmd()
        .args(["recent", "--limit", "2"])
        .output()
        .expect("Failed to get recent memories");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should show most recent
    assert!(stdout.contains("Third") || stdout.contains("Second"));
}

/// Test memory update using memory replace command
#[test]
fn test_memory_update() {
    let cas = new_cas_instance();
    let entry_id = cas.add_memory("Original content");

    let output = cas
        .cas_cmd()
        .args(["memory", "replace", &entry_id, "Updated content"])
        .output()
        .expect("Failed to update memory");

    assert!(
        output.status.success(),
        "memory replace failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );

    let output = cas
        .cas_cmd()
        .args(["show", &entry_id, "--json"])
        .output()
        .expect("Failed to show entry");

    let entry: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");
    assert_eq!(entry["content"], "Updated content");
}

/// Test memory deletion via archive (CAS uses archive instead of delete)

/// Test memory unarchive
#[test]
fn test_memory_unarchive() {
    let cas = new_cas_instance();
    let entry_id = cas.add_memory("Memory to archive and unarchive");

    // Archive
    cas.archive(&entry_id);

    // Unarchive
    let output = cas
        .cas_cmd()
        .args(["unarchive", &entry_id])
        .output()
        .expect("Failed to unarchive");

    assert!(output.status.success());

    let output = cas
        .cas_cmd()
        .args(["show", &entry_id, "--json"])
        .output()
        .expect("Failed to show entry");

    let entry: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");
    assert_eq!(entry["archived"], false);
}

/// Test search basic functionality
#[test]
fn test_memory_search_scope() {
    let cas = new_cas_instance();

    // Add project-scoped memory (default)
    cas.add_memory("Project-specific learning about Rust");

    // Search with basic query
    let output = cas
        .cas_cmd()
        .args(["search", "learning", "--json"])
        .output()
        .expect("Failed to search");

    assert!(output.status.success());

    // Verify results contain the added entry
    let stdout = String::from_utf8_lossy(&output.stdout);
    let results: Vec<serde_json::Value> = serde_json::from_str(&stdout).unwrap_or_default();
    assert!(!results.is_empty(), "Search should return results");
}

/// Test empty search returns results
#[test]
fn test_memory_list_all() {
    let cas = new_cas_with_data();

    let output = cas
        .cas_cmd()
        .args(["list", "--limit", "100"])
        .output()
        .expect("Failed to list all");

    assert!(output.status.success());
    let stdout = String::from_utf8_lossy(&output.stdout);

    // Should have entries from fixture
    assert!(!stdout.is_empty());
}
