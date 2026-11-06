use crate::CodeStore;
use crate::sqlite_code_store::SqliteCodeStore;
use cas_code::{
    CodeFile, CodeMemoryLink, CodeMemoryLinkType, CodeRelationType, CodeRelationship, CodeSymbol,
    Language, SymbolKind,
};
use chrono::Utc;
use rusqlite::Connection;
use tempfile::TempDir;

fn setup_test_db() -> (TempDir, SqliteCodeStore) { todo!() }

#[test]
fn test_file_crud() {
    let (_temp, store) = setup_test_db();

    let file = CodeFile {
        id: store.generate_file_id().unwrap(),
        path: "src/lib.rs".to_string(),
        repository: "test-repo".to_string(),
        language: Language::Rust,
        size: 1024,
        line_count: 50,
        commit_hash: Some("abc123".to_string()),
        content_hash: "hash123".to_string(),
        ..Default::default()
    };

    // Add
    store.add_file(&file).unwrap();

    // Get
    let retrieved = store.get_file(&file.id).unwrap();
    assert_eq!(retrieved.path, "src/lib.rs");
    assert_eq!(retrieved.language, Language::Rust);

    // Get by path
    let by_path = store
        .get_file_by_path("test-repo", "src/lib.rs")
        .unwrap()
        .unwrap();
    assert_eq!(by_path.id, file.id);

    // List
    let files = store.list_files("test-repo", None).unwrap();
    assert_eq!(files.len(), 1);

    // Delete
    store.delete_file(&file.id).unwrap();
    assert!(store.get_file(&file.id).is_err());
}

#[test]
fn test_symbol_crud() {
    let (_temp, store) = setup_test_db();

    let file = CodeFile {
        id: store.generate_file_id().unwrap(),
        path: "src/lib.rs".to_string(),
        repository: "test-repo".to_string(),
        language: Language::Rust,
        content_hash: "hash123".to_string(),
        ..Default::default()
    };
    store.add_file(&file).unwrap();

    let symbol = CodeSymbol {
        id: store.generate_symbol_id().unwrap(),
        qualified_name: "my_crate::my_func".to_string(),
        name: "my_func".to_string(),
        kind: SymbolKind::Function,
        language: Language::Rust,
        file_path: "src/lib.rs".to_string(),
        file_id: file.id.clone(),
        line_start: 10,
        line_end: 20,
        source: "fn my_func() {}".to_string(),
        documentation: Some("A test function".to_string()),
        signature: Some("fn my_func()".to_string()),
        repository: "test-repo".to_string(),
        content_hash: "symhash".to_string(),
        ..Default::default()
    };

    // Add
    store.add_symbol(&symbol).unwrap();

    // Get
    let retrieved = store.get_symbol(&symbol.id).unwrap();
    assert_eq!(retrieved.name, "my_func");
    assert_eq!(retrieved.kind, SymbolKind::Function);

    // Get by name
    let by_name = store.get_symbols_by_name("my_crate::my_func").unwrap();
    assert_eq!(by_name.len(), 1);

    // Get in file
    let in_file = store.get_symbols_in_file(&file.id).unwrap();
    assert_eq!(in_file.len(), 1);

    // Search
    let search_results = store.search_symbols("%my_func%", None, None, 10).unwrap();
    assert_eq!(search_results.len(), 1);

    // Count
    assert_eq!(store.count_symbols().unwrap(), 1);

    // Delete
    store.delete_symbol(&symbol.id).unwrap();
    assert!(store.get_symbol(&symbol.id).is_err());
}

#[test]
fn test_relationship_operations() {
    let (_temp, store) = setup_test_db();

    // Create file and symbols
    let file = CodeFile {
        id: store.generate_file_id().unwrap(),
        path: "src/lib.rs".to_string(),
        repository: "test-repo".to_string(),
        language: Language::Rust,
        content_hash: "hash123".to_string(),
        ..Default::default()
    };
    store.add_file(&file).unwrap();

    let caller = CodeSymbol {
        id: store.generate_symbol_id().unwrap(),
        qualified_name: "my_crate::caller".to_string(),
        name: "caller".to_string(),
        kind: SymbolKind::Function,
        file_id: file.id.clone(),
        repository: "test-repo".to_string(),
        content_hash: "h1".to_string(),
        ..Default::default()
    };
    let callee = CodeSymbol {
        id: store.generate_symbol_id().unwrap(),
        qualified_name: "my_crate::callee".to_string(),
        name: "callee".to_string(),
        kind: SymbolKind::Function,
        file_id: file.id.clone(),
        repository: "test-repo".to_string(),
        content_hash: "h2".to_string(),
        ..Default::default()
    };
    store.add_symbol(&caller).unwrap();
    store.add_symbol(&callee).unwrap();

    // Add relationship
    let rel = CodeRelationship {
        id: store.generate_relationship_id().unwrap(),
        source_id: caller.id.clone(),
        target_id: callee.id.clone(),
        relation_type: CodeRelationType::Calls,
        weight: 1.0,
        created: Utc::now(),
    };
    store.add_relationship(&rel).unwrap();

    // Get callers of callee
    let callers = store.get_callers(&callee.id).unwrap();
    assert_eq!(callers.len(), 1);
    assert_eq!(callers[0].name, "caller");

    // Get callees of caller
    let callees = store.get_callees(&caller.id).unwrap();
    assert_eq!(callees.len(), 1);
    assert_eq!(callees[0].name, "callee");

    // Get relationships
    let rels_from = store.get_relationships_from(&caller.id).unwrap();
    assert_eq!(rels_from.len(), 1);

    let rels_to = store.get_relationships_to(&callee.id).unwrap();
    assert_eq!(rels_to.len(), 1);
}


#[test]
fn test_batch_operations() {
    let (_temp, store) = setup_test_db();

    let file = CodeFile {
        id: store.generate_file_id().unwrap(),
        path: "src/lib.rs".to_string(),
        repository: "test-repo".to_string(),
        content_hash: "hash123".to_string(),
        ..Default::default()
    };
    store.add_file(&file).unwrap();

    let symbols: Vec<CodeSymbol> = (0..5)
        .map(|i| CodeSymbol {
            id: format!("sym-{i}"),
            qualified_name: format!("my_crate::func_{i}"),
            name: format!("func_{i}"),
            kind: SymbolKind::Function,
            file_id: file.id.clone(),
            repository: "test-repo".to_string(),
            content_hash: format!("h{i}"),
            ..Default::default()
        })
        .collect();

    store.add_symbols_batch(&symbols).unwrap();
    assert_eq!(store.count_symbols().unwrap(), 5);
}

#[test]
fn test_normalize_path() {
    // Test leading ./
    assert_eq!(
        SqliteCodeStore::normalize_path("./src/lib.rs"),
        "src/lib.rs"
    );
    // Test leading /
    assert_eq!(SqliteCodeStore::normalize_path("/src/lib.rs"), "src/lib.rs");
    // Test multiple leading ./
    assert_eq!(
        SqliteCodeStore::normalize_path("././src/lib.rs"),
        "src/lib.rs"
    );
    // Test embedded .
    assert_eq!(
        SqliteCodeStore::normalize_path("src/./lib.rs"),
        "src/lib.rs"
    );
    // Test no prefix
    assert_eq!(SqliteCodeStore::normalize_path("src/lib.rs"), "src/lib.rs");
    // Test absolute path normalization
    assert_eq!(
        SqliteCodeStore::normalize_path("/Users/test/project/src/lib.rs"),
        "Users/test/project/src/lib.rs"
    );
    // Test Windows-style paths
    assert_eq!(
        SqliteCodeStore::normalize_path(".\\src\\lib.rs"),
        "src/lib.rs"
    );
    // Test whitespace trimming
    assert_eq!(
        SqliteCodeStore::normalize_path("  ./src/lib.rs  "),
        "src/lib.rs"
    );
}

#[test]
fn test_deterministic_symbol_id_normalization() {
    // Same file with different path representations should produce same ID
    let id1 =
        SqliteCodeStore::generate_deterministic_symbol_id("my_crate::func", "./src/lib.rs", "repo");
    let id2 =
        SqliteCodeStore::generate_deterministic_symbol_id("my_crate::func", "src/lib.rs", "repo");
    let id3 = SqliteCodeStore::generate_deterministic_symbol_id(
        "my_crate::func",
        "././src/lib.rs",
        "repo",
    );
    assert_eq!(id1, id2);
    assert_eq!(id2, id3);
}
