#[test]
fn test_trace_store_basic() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    let event = TraceEvent {
        id: "tr-001".to_string(),
        event_type: TraceEventType::Search,
        timestamp: Utc::now(),
        session_id: Some("sess-001".to_string()),
        duration_ms: 150,
        input: r#"{"query":"test"}"#.to_string(),
        output: r#"{"results":5}"#.to_string(),
        metadata: r#"{}"#.to_string(),
        success: true,
        error: None,
    };

    store.record(&event).unwrap();

    let recent = store.get_recent(10).unwrap();
    assert_eq!(recent.len(), 1);
    assert_eq!(recent[0].id, "tr-001");
}

#[test]
fn test_tool_trace_classify_command() {
    // Build commands
    assert_eq!(ToolTrace::classify_command("cargo build"), "build");
    assert_eq!(ToolTrace::classify_command("cargo check"), "build");
    assert_eq!(ToolTrace::classify_command("npm run build"), "build");
    assert_eq!(ToolTrace::classify_command("make all"), "build");
    assert_eq!(ToolTrace::classify_command("go build ./..."), "build");

    // Test commands
    assert_eq!(ToolTrace::classify_command("cargo test"), "test");
    assert_eq!(ToolTrace::classify_command("npm test"), "test");
    assert_eq!(ToolTrace::classify_command("pytest"), "test");
    assert_eq!(ToolTrace::classify_command("jest"), "test");
    assert_eq!(ToolTrace::classify_command("go test ./..."), "test");
    assert_eq!(ToolTrace::classify_command("mix test"), "test");

    // Run commands
    assert_eq!(ToolTrace::classify_command("cargo run"), "run");
    assert_eq!(ToolTrace::classify_command("npm start"), "run");
    assert_eq!(ToolTrace::classify_command("node server.js"), "run");
    assert_eq!(ToolTrace::classify_command("python main.py"), "run");
    assert_eq!(ToolTrace::classify_command("mix phx.server"), "run");

    // Git commands
    assert_eq!(ToolTrace::classify_command("git commit -m 'test'"), "git");
    assert_eq!(ToolTrace::classify_command("git push origin main"), "git");

    // Other
    assert_eq!(ToolTrace::classify_command("ls -la"), "other");
    assert_eq!(ToolTrace::classify_command("echo hello"), "other");
}

#[test]
fn test_tool_trace_is_dep_path() {
    assert!(ToolTrace::is_dep_path("/project/deps/lib/file.rs"));
    assert!(ToolTrace::is_dep_path("/app/node_modules/express/index.js"));
    assert!(ToolTrace::is_dep_path("/vendor/bundle/gems/rails/lib.rb"));
    assert!(ToolTrace::is_dep_path(
        "/home/user/.cargo/registry/src/lib.rs"
    ));
    assert!(ToolTrace::is_dep_path(
        "/target/debug/deps/mylib-abc123.rlib"
    ));
    assert!(ToolTrace::is_dep_path(
        "/venv/lib/python3.9/site-packages/requests/api.py"
    ));

    assert!(!ToolTrace::is_dep_path("/project/src/main.rs"));
    assert!(!ToolTrace::is_dep_path("/app/lib/my_code.js"));
}

#[test]
fn test_trace_builder_finish_error() {
    let trace = TraceBuilder::new(TraceEventType::Extraction)
        .session("sess-456")
        .input(&serde_json::json!({"obs_id": "obs-1"}))
        .finish_error("extraction failed");

    assert_eq!(trace.event_type, TraceEventType::Extraction);
    assert!(!trace.success);
    assert_eq!(trace.error, Some("extraction failed".to_string()));
}

#[test]
fn test_trace_store_get_by_type() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    store
        .record(&TraceEvent {
            id: "tr-type-1".to_string(),
            event_type: TraceEventType::Search,
            timestamp: Utc::now(),
            session_id: None,
            duration_ms: 100,
            input: "{}".to_string(),
            output: "{}".to_string(),
            metadata: "{}".to_string(),
            success: true,
            error: None,
        })
        .unwrap();

    store
        .record(&TraceEvent {
            id: "tr-type-2".to_string(),
            event_type: TraceEventType::Extraction,
            timestamp: Utc::now(),
            session_id: None,
            duration_ms: 100,
            input: "{}".to_string(),
            output: "{}".to_string(),
            metadata: "{}".to_string(),
            success: true,
            error: None,
        })
        .unwrap();

    let search_results = store.get_by_type(TraceEventType::Search, 10).unwrap();
    assert_eq!(search_results.len(), 1);

    let extraction_results = store.get_by_type(TraceEventType::Extraction, 10).unwrap();
    assert_eq!(extraction_results.len(), 1);
}

#[test]
fn test_trace_store_search() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    store
        .record(&TraceEvent {
            id: "tr-search-1".to_string(),
            event_type: TraceEventType::Search,
            timestamp: Utc::now(),
            session_id: None,
            duration_ms: 100,
            input: r#"{"query": "unique_pattern_xyz"}"#.to_string(),
            output: "{}".to_string(),
            metadata: "{}".to_string(),
            success: true,
            error: None,
        })
        .unwrap();

    let results = store.search("unique_pattern_xyz", 10).unwrap();
    assert_eq!(results.len(), 1);

    let no_results = store.search("nonexistent_pattern", 10).unwrap();
    assert!(no_results.is_empty());
}

#[test]
fn test_trace_store_tool_traces() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    let tool_trace = ToolTrace::new("sess-tool".to_string(), "Edit".to_string(), 1);
    store.record_tool_trace(&tool_trace).unwrap();

    let traces = store.get_tool_traces("sess-tool", 10).unwrap();
    assert_eq!(traces.len(), 1);
    assert_eq!(traces[0].tool_name, "Edit");

    let last = store.get_last_tool_trace("sess-tool").unwrap();
    assert!(last.is_some());
    assert_eq!(last.unwrap().tool_name, "Edit");
}

#[test]
fn test_trace_store_observation_buffer() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    let obs = BufferedObservation {
        session_id: "sess-obs".to_string(),
        tool_name: "Write".to_string(),
        file_path: Some("/src/main.rs".to_string()),
        content: "fn main() {}".to_string(),
        exit_code: None,
        is_error: false,
        timestamp: Utc::now(),
    };
    store.buffer_observation(&obs).unwrap();

    let count = store.observation_buffer_count("sess-obs").unwrap();
    assert_eq!(count, 1);

    let observations = store.get_buffered_observations("sess-obs").unwrap();
    assert_eq!(observations.len(), 1);
    assert_eq!(observations[0].tool_name, "Write");

    store.clear_observation_buffer("sess-obs").unwrap();
    let count_after = store.observation_buffer_count("sess-obs").unwrap();
    assert_eq!(count_after, 0);
}

#[test]
fn test_trace_stats_success_rate() {
    let stats = TraceStats {
        event_type: TraceEventType::Search,
        count: 10,
        avg_duration_ms: 100.0,
        success_count: 8,
        failure_count: 2,
    };
    assert!((stats.success_rate() - 0.8).abs() < 0.001);

    let zero_stats = TraceStats {
        event_type: TraceEventType::Search,
        count: 0,
        avg_duration_ms: 0.0,
        success_count: 0,
        failure_count: 0,
    };
    assert!((zero_stats.success_rate() - 0.0).abs() < 0.001);
}

#[test]
fn test_generate_trace_id() {
    let id1 = generate_trace_id();
    let id2 = generate_trace_id();

    assert!(id1.starts_with("tr-"));
    assert!(id2.starts_with("tr-"));
    // May be same if called quickly, but format should be correct
}
