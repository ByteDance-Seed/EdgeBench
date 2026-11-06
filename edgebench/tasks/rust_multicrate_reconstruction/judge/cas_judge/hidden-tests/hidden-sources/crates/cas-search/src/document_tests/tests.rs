#[test]
fn test_entry_embedding_text() {
    let entry = Entry {
        id: "test".to_string(),
        content: "Content here".to_string(),
        title: Some("Title".to_string()),
        ..Default::default()
    };

    let text = entry.doc_embedding_text();
    assert!(text.contains("Title"));
    assert!(text.contains("Content here"));
}

#[test]
fn test_task_search_document() {
    let task = Task {
        id: "cas-a1b2".to_string(),
        scope: Scope::Project,
        title: "Implement search feature".to_string(),
        description: "Add full-text search capability".to_string(),
        design: "Use tantivy for BM25".to_string(),
        acceptance_criteria: "Search returns relevant results".to_string(),
        status: TaskStatus::InProgress,
        priority: Priority::HIGH,
        task_type: TaskType::Feature,
        labels: vec!["search".to_string(), "v1".to_string()],
        assignee: Some("alice".to_string()),
        created_at: Utc::now(),
        updated_at: Utc::now(),
        ..Default::default()
    };

    assert_eq!(task.doc_id(), "cas-a1b2");
    assert_eq!(task.doc_content(), "Add full-text search capability");
    assert_eq!(task.doc_type(), "task");
    assert_eq!(task.doc_tags(), vec!["search", "v1"]);
    assert_eq!(task.doc_title(), Some("Implement search feature"));

    let metadata = task.doc_metadata();
    assert_eq!(metadata.get("status"), Some(&"in_progress".to_string()));
    assert_eq!(metadata.get("task_type"), Some(&"feature".to_string()));
    assert_eq!(metadata.get("assignee"), Some(&"alice".to_string()));
}

#[test]
fn test_skill_search_document() {
    let skill = Skill {
        id: "skill-001".to_string(),
        scope: Scope::Global,
        name: "commit".to_string(),
        summary: "Create git commits".to_string(),
        description: "Full commit workflow with staging".to_string(),
        tags: vec!["git".to_string(), "workflow".to_string()],
        status: SkillStatus::Enabled,
        invokable: true,
        invocation: "/commit".to_string(),
        usage_count: 42,
        created_at: Utc::now(),
        updated_at: Utc::now(),
        ..Default::default()
    };

    assert_eq!(skill.doc_id(), "skill-001");
    assert_eq!(skill.doc_content(), "Full commit workflow with staging");
    assert_eq!(skill.doc_type(), "skill");
    assert_eq!(skill.doc_tags(), vec!["git", "workflow"]);
    assert_eq!(skill.doc_title(), Some("commit"));

    let metadata = skill.doc_metadata();
    assert_eq!(metadata.get("name"), Some(&"commit".to_string()));
    assert_eq!(metadata.get("invocation"), Some(&"/commit".to_string()));
    assert_eq!(metadata.get("status"), Some(&"enabled".to_string()));
}

#[test]
fn test_skill_embedding_text() {
    let skill = Skill {
        id: "test".to_string(),
        name: "commit".to_string(),
        summary: "Short summary".to_string(),
        description: "Full description".to_string(),
        created_at: Utc::now(),
        updated_at: Utc::now(),
        ..Default::default()
    };

    let text = skill.doc_embedding_text();
    assert!(text.contains("commit"));
    assert!(text.contains("Short summary"));
    assert!(text.contains("Full description"));
}

#[test]
fn test_spec_content_fallback_to_title() {
    let spec = Spec {
        id: "spec-003".to_string(),
        title: "Title Only".to_string(),
        summary: String::new(),
        ..Default::default()
    };

    // When summary is empty, doc_content should return the title
    assert_eq!(spec.doc_content(), "Title Only");
}

#[test]
fn test_index_and_search_all_types() {
    use crate::{Bm25Index, TextIndex};
    use cas_code::{Language, SymbolKind};

    // Create an in-memory BM25 index
    let index = Bm25Index::in_memory().expect("Failed to create index");

    // Create test documents of each type
    let entry = Entry {
        id: "entry-001".to_string(),
        content: "Authentication tokens should be validated on every request".to_string(),
        title: Some("Token validation".to_string()),
        tags: vec!["security".to_string()],
        ..Default::default()
    };

    let task = Task {
        id: "task-001".to_string(),
        title: "Implement token validation".to_string(),
        description: "Add middleware to validate authentication tokens".to_string(),
        created_at: Utc::now(),
        updated_at: Utc::now(),
        ..Default::default()
    };

    let rule = Rule {
        id: "rule-001".to_string(),
        content: "Always validate authentication tokens before processing requests".to_string(),
        tags: vec!["security".to_string(), "auth".to_string()],
        created: Utc::now(),
        ..Default::default()
    };

    let skill = Skill {
        id: "skill-001".to_string(),
        name: "validate-tokens".to_string(),
        description: "Skill for validating authentication tokens".to_string(),
        created_at: Utc::now(),
        updated_at: Utc::now(),
        ..Default::default()
    };

    let symbol = CodeSymbol {
        id: "sym-001".to_string(),
        qualified_name: "auth::token::validate".to_string(),
        name: "validate".to_string(),
        kind: SymbolKind::Function,
        language: Language::Rust,
        file_path: "src/auth/token.rs".to_string(),
        file_id: "file-001".to_string(),
        source: "pub fn validate(token: &str) -> bool { /* validate token */ true }".to_string(),
        created: Utc::now(),
        updated: Utc::now(),
        content_hash: "hash".to_string(),
        scope: "project".to_string(),
        ..Default::default()
    };

    // Index all documents
    index.index(&entry).expect("Failed to index entry");
    index.index(&task).expect("Failed to index task");
    index.index(&rule).expect("Failed to index rule");
    index.index(&skill).expect("Failed to index skill");
    index.index(&symbol).expect("Failed to index symbol");

    // Search for "authentication" - should find entries across multiple types
    let results = index.search("authentication", 10).expect("Search failed");
    assert!(
        !results.is_empty(),
        "Expected results for 'authentication' query"
    );

    // Verify we can find results from different document types
    // Results are (doc_id, score) tuples
    let result_ids: Vec<&str> = results.iter().map(|(id, _score)| id.as_str()).collect();

    // At least entry, task, and rule should match "authentication"
    assert!(
        result_ids.contains(&"entry-001")
            || result_ids.contains(&"task-001")
            || result_ids.contains(&"rule-001"),
        "Expected at least one document about authentication in results: {result_ids:?}"
    );

    // Search for "validate" - should find all types
    let validate_results = index.search("validate", 10).expect("Search failed");
    assert!(
        !validate_results.is_empty(),
        "Expected results for 'validate' query"
    );

    // Search for "token" - common across all documents
    let token_results = index.search("token", 10).expect("Search failed");
    assert!(
        token_results.len() >= 3,
        "Expected at least 3 results for 'token' query, got {}",
        token_results.len()
    );

    // Test type-filtered search
    let entry_results = index
        .search_with_type("token", "entry", 10)
        .expect("Type-filtered search failed");
    assert_eq!(
        entry_results.len(),
        1,
        "Type filter should return exactly one entry"
    );
    assert_eq!(
        entry_results[0].0, "entry-001",
        "Entry result should be entry-001"
    );

    // Test tag-filtered search
    let security_results = index
        .search_with_tags("token", &["security"], 10)
        .expect("Tag-filtered search failed");
    assert!(
        !security_results.is_empty(),
        "Tag filter should return security-tagged documents"
    );
}
