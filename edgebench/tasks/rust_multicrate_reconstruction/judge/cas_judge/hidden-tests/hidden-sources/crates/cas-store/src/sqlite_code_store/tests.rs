#[test]
fn test_memory_link_operations() {
    let (_temp, store) = setup_test_db();

    let link = CodeMemoryLink {
        code_id: "sym-12345".to_string(),
        entry_id: "2024-01-15-123".to_string(),
        link_type: CodeMemoryLinkType::Documents,
        confidence: 0.9,
        created: Utc::now(),
    };

    // Add link
    store.link_to_memory(&link).unwrap();

    // Get linked memories
    let memories = store.get_linked_memories("sym-12345").unwrap();
    assert_eq!(memories.len(), 1);
    assert_eq!(memories[0], "2024-01-15-123");

    // Get linked code
    let code = store.get_linked_code("2024-01-15-123").unwrap();
    assert_eq!(code.len(), 1);
    assert_eq!(code[0], "sym-12345");

    // Get memory links
    let links = store.get_memory_links("sym-12345").unwrap();
    assert_eq!(links.len(), 1);
    assert_eq!(links[0].link_type, CodeMemoryLinkType::Documents);

    // Delete link
    store
        .delete_memory_link("sym-12345", "2024-01-15-123", CodeMemoryLinkType::Documents)
        .unwrap();
    let memories = store.get_linked_memories("sym-12345").unwrap();
    assert!(memories.is_empty());
}
