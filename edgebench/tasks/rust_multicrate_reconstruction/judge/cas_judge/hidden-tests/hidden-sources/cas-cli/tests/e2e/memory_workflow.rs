#[test]
fn test_memory_delete() {
    let cas = new_cas_instance();
    let entry_id = cas.add_memory("Memory to archive");

    // Archive the entry (CAS's equivalent of soft delete)
    cas.archive(&entry_id);

    // Verify archived
    let output = cas
        .cas_cmd()
        .args(["show", &entry_id, "--json"])
        .output()
        .expect("Failed to show entry");

    let entry: serde_json::Value =
        serde_json::from_str(&String::from_utf8_lossy(&output.stdout)).expect("Failed to parse");
    assert_eq!(entry["archived"], true);
}
