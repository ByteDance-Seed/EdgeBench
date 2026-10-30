use crate::document::*;
use cas_types::{EntryType, Priority, RuleStatus, Scope, SkillStatus, TaskStatus, TaskType};
use chrono::Utc;

// =========================================================================
// Entry tests
// =========================================================================

#[test]
fn test_entry_search_document() {
    let entry = Entry {
        id: "g-2025-01-01-001".to_string(),
        scope: Scope::Global,
        entry_type: EntryType::Learning,
        content: "Always use Option for nullable fields".to_string(),
        tags: vec!["rust".to_string(), "best-practice".to_string()],
        title: Some("Nullable fields".to_string()),
        importance: 0.8,
        helpful_count: 5,
        harmful_count: 0,
        archived: false,
        ..Default::default()
    };

    assert_eq!(entry.doc_id(), "g-2025-01-01-001");
    assert_eq!(entry.doc_content(), "Always use Option for nullable fields");
    assert_eq!(entry.doc_type(), "entry");
    assert_eq!(entry.doc_tags(), vec!["rust", "best-practice"]);
    assert_eq!(entry.doc_title(), Some("Nullable fields"));

    let metadata = entry.doc_metadata();
    assert_eq!(metadata.get("entry_type"), Some(&"learning".to_string()));
    assert_eq!(metadata.get("scope"), Some(&"global".to_string()));
    assert_eq!(metadata.get("importance"), Some(&"0.8".to_string()));
}


// =========================================================================
// Task tests
// =========================================================================


#[test]
fn test_task_embedding_text() {
    let task = Task {
        id: "test".to_string(),
        title: "Title".to_string(),
        description: "Description".to_string(),
        design: "Design".to_string(),
        acceptance_criteria: "Criteria".to_string(),
        created_at: Utc::now(),
        updated_at: Utc::now(),
        ..Default::default()
    };

    let text = task.doc_embedding_text();
    assert!(text.contains("Title"));
    assert!(text.contains("Description"));
    assert!(text.contains("Design"));
    assert!(text.contains("Criteria"));
}

// =========================================================================
// Rule tests
// =========================================================================

#[test]
fn test_rule_search_document() {
    let rule = Rule {
        id: "rule-001".to_string(),
        scope: Scope::Project,
        content: "Always validate input parameters".to_string(),
        status: RuleStatus::Proven,
        tags: vec!["security".to_string(), "validation".to_string()],
        paths: "**/*.rs".to_string(),
        helpful_count: 10,
        harmful_count: 0,
        created: Utc::now(),
        ..Default::default()
    };

    assert_eq!(rule.doc_id(), "rule-001");
    assert_eq!(rule.doc_content(), "Always validate input parameters");
    assert_eq!(rule.doc_type(), "rule");
    assert_eq!(rule.doc_tags(), vec!["security", "validation"]);

    let metadata = rule.doc_metadata();
    assert_eq!(metadata.get("status"), Some(&"Proven".to_string()));
    assert_eq!(metadata.get("paths"), Some(&"**/*.rs".to_string()));
}

// =========================================================================
// Skill tests
// =========================================================================



// =========================================================================
// Spec tests
// =========================================================================

#[test]
fn test_spec_search_document() {
    use cas_types::{SpecStatus, SpecType};

    let spec = Spec {
        id: "spec-001".to_string(),
        scope: Scope::Project,
        title: "Authentication System".to_string(),
        summary: "Design for user authentication".to_string(),
        goals: vec!["Secure login".to_string(), "SSO support".to_string()],
        acceptance_criteria: vec!["Tests pass".to_string()],
        tags: vec!["security".to_string(), "auth".to_string()],
        spec_type: SpecType::Feature,
        status: SpecStatus::Approved,
        version: 2,
        task_id: Some("cas-123".to_string()),
        ..Default::default()
    };

    assert_eq!(spec.doc_id(), "spec-001");
    assert_eq!(spec.doc_content(), "Design for user authentication");
    assert_eq!(spec.doc_type(), "spec");
    assert_eq!(spec.doc_tags(), vec!["security", "auth"]);
    assert_eq!(spec.doc_title(), Some("Authentication System"));

    let metadata = spec.doc_metadata();
    assert_eq!(
        metadata.get("title"),
        Some(&"Authentication System".to_string())
    );
    assert_eq!(metadata.get("spec_type"), Some(&"feature".to_string()));
    assert_eq!(metadata.get("status"), Some(&"approved".to_string()));
    assert_eq!(metadata.get("version"), Some(&"2".to_string()));
    assert_eq!(metadata.get("task_id"), Some(&"cas-123".to_string()));
}

#[test]
fn test_spec_embedding_text() {
    let spec = Spec {
        id: "spec-002".to_string(),
        title: "API Design".to_string(),
        summary: "REST API specification".to_string(),
        goals: vec!["Clear endpoints".to_string()],
        acceptance_criteria: vec!["Documented".to_string()],
        design_notes: "Use OpenAPI 3.0".to_string(),
        ..Default::default()
    };

    let text = spec.doc_embedding_text();
    assert!(text.contains("API Design"));
    assert!(text.contains("REST API specification"));
    assert!(text.contains("Clear endpoints"));
    assert!(text.contains("Documented"));
    assert!(text.contains("Use OpenAPI 3.0"));
}


// =========================================================================
// CodeSymbol tests
// =========================================================================

#[test]
fn test_code_symbol_search_document() {
    use cas_code::{Language, SymbolKind};

    let symbol = CodeSymbol {
        id: "sym-001".to_string(),
        qualified_name: "cas_search::traits::SearchDocument::doc_id".to_string(),
        name: "doc_id".to_string(),
        kind: SymbolKind::Method,
        language: Language::Rust,
        file_path: "crates/cas-search/src/traits.rs".to_string(),
        file_id: "file-001".to_string(),
        line_start: 44,
        line_end: 44,
        source: "fn doc_id(&self) -> &str;".to_string(),
        documentation: Some("Unique identifier for the document".to_string()),
        signature: Some("fn doc_id(&self) -> &str".to_string()),
        parent_id: Some("sym-000".to_string()),
        repository: "cas".to_string(),
        commit_hash: None,
        created: Utc::now(),
        updated: Utc::now(),
        content_hash: "abc123".to_string(),
        scope: "project".to_string(),
    };

    assert_eq!(symbol.doc_id(), "sym-001");
    assert_eq!(symbol.doc_content(), "fn doc_id(&self) -> &str;");
    assert_eq!(symbol.doc_type(), "code_symbol");
    assert!(symbol.doc_tags().is_empty()); // CodeSymbol has no tags
    assert_eq!(
        symbol.doc_title(),
        Some("cas_search::traits::SearchDocument::doc_id")
    );

    let metadata = symbol.doc_metadata();
    assert_eq!(metadata.get("name"), Some(&"doc_id".to_string()));
    assert_eq!(metadata.get("kind"), Some(&"Method".to_string()));
    assert_eq!(metadata.get("language"), Some(&"Rust".to_string()));
}

#[test]
fn test_code_symbol_embedding_text() {
    use cas_code::{Language, SymbolKind};

    let symbol = CodeSymbol {
        id: "test".to_string(),
        qualified_name: "my::module::func".to_string(),
        name: "func".to_string(),
        kind: SymbolKind::Function,
        language: Language::Rust,
        file_path: "src/lib.rs".to_string(),
        file_id: "file".to_string(),
        line_start: 1,
        line_end: 10,
        source: "fn func() { /* long source code */ }".to_string(),
        documentation: Some("A function".to_string()),
        signature: Some("fn func()".to_string()),
        parent_id: None,
        repository: "test".to_string(),
        commit_hash: None,
        created: Utc::now(),
        updated: Utc::now(),
        content_hash: "hash".to_string(),
        scope: "project".to_string(),
    };

    let text = symbol.doc_embedding_text();
    assert!(text.contains("my::module::func"));
    assert!(text.contains("A function"));
    assert!(text.contains("fn func()"));
}

// =========================================================================
// Integration test: index all types, search across them
// =========================================================================

