use crate::tracing::*;
use chrono::Utc;
use tempfile::TempDir;


#[test]
fn test_trace_builder() {
    let trace = TraceBuilder::new(TraceEventType::ContextInjection)
        .session("sess-123")
        .input(&serde_json::json!({"cwd": "/test"}))
        .finish_success(&serde_json::json!({"tokens": 500}));

    assert_eq!(trace.event_type, TraceEventType::ContextInjection);
    assert!(trace.success);
    assert!(trace.session_id.is_some());
}

#[test]
fn test_trace_stats() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    // Record multiple events
    for i in 0..5 {
        store
            .record(&TraceEvent {
                id: format!("tr-{i}"),
                event_type: TraceEventType::Search,
                timestamp: Utc::now(),
                session_id: None,
                duration_ms: 100,
                input: "{}".to_string(),
                output: "{}".to_string(),
                metadata: "{}".to_string(),
                success: i % 2 == 0,
                error: None,
            })
            .unwrap();
    }

    let stats = store.get_stats().unwrap();
    assert!(!stats.is_empty());

    let search_stats = stats
        .iter()
        .find(|s| s.event_type == TraceEventType::Search)
        .unwrap();
    assert_eq!(search_stats.count, 5);
    assert_eq!(search_stats.success_count, 3);
    assert_eq!(search_stats.failure_count, 2);
}

// =========================================================================
// TraceEventType tests
// =========================================================================

#[test]
fn test_trace_event_type_display() {
    assert_eq!(
        TraceEventType::ContextInjection.to_string(),
        "context_injection"
    );
    assert_eq!(TraceEventType::Search.to_string(), "search");
    assert_eq!(
        TraceEventType::RuleApplication.to_string(),
        "rule_application"
    );
    assert_eq!(TraceEventType::Extraction.to_string(), "extraction");
    assert_eq!(
        TraceEventType::MemoryRetrieval.to_string(),
        "memory_retrieval"
    );
    assert_eq!(
        TraceEventType::SkillInvocation.to_string(),
        "skill_invocation"
    );
    assert_eq!(TraceEventType::CommandExecution.to_string(), "command");
    assert_eq!(TraceEventType::ClaudeApiCall.to_string(), "claude_api");
    assert_eq!(TraceEventType::StoreOperation.to_string(), "store_op");
    assert_eq!(TraceEventType::HookEvent.to_string(), "hook");
}

#[test]
fn test_trace_event_type_from_str() {
    assert_eq!(
        TraceEventType::parse("context_injection"),
        Some(TraceEventType::ContextInjection)
    );
    assert_eq!(
        TraceEventType::parse("search"),
        Some(TraceEventType::Search)
    );
    assert_eq!(
        TraceEventType::parse("rule_application"),
        Some(TraceEventType::RuleApplication)
    );
    assert_eq!(
        TraceEventType::parse("command"),
        Some(TraceEventType::CommandExecution)
    );
    assert_eq!(
        TraceEventType::parse("command_execution"),
        Some(TraceEventType::CommandExecution)
    );
    assert_eq!(
        TraceEventType::parse("claude_api"),
        Some(TraceEventType::ClaudeApiCall)
    );
    assert_eq!(
        TraceEventType::parse("claude_api_call"),
        Some(TraceEventType::ClaudeApiCall)
    );
    assert_eq!(
        TraceEventType::parse("store_op"),
        Some(TraceEventType::StoreOperation)
    );
    assert_eq!(
        TraceEventType::parse("store_operation"),
        Some(TraceEventType::StoreOperation)
    );
    assert_eq!(
        TraceEventType::parse("hook"),
        Some(TraceEventType::HookEvent)
    );
    assert_eq!(
        TraceEventType::parse("hook_event"),
        Some(TraceEventType::HookEvent)
    );
    assert_eq!(TraceEventType::parse("invalid"), None);
}

// =========================================================================
// ToolTrace tests
// =========================================================================

#[test]
fn test_tool_trace_new() {
    let trace = ToolTrace::new("sess-123".to_string(), "Edit".to_string(), 5);
    assert!(trace.id.starts_with("tt-"));
    assert_eq!(trace.session_id, "sess-123");
    assert_eq!(trace.tool_name, "Edit");
    assert_eq!(trace.sequence_pos, 5);
    assert!(trace.success);
    assert!(!trace.prev_failed);
}

#[test]
fn test_tool_trace_hash_content() {
    let hash1 = ToolTrace::hash_content("hello world");
    let hash2 = ToolTrace::hash_content("hello world");
    let hash3 = ToolTrace::hash_content("different content");

    assert_eq!(hash1, hash2);
    assert_ne!(hash1, hash3);
    assert_eq!(hash1.len(), 16); // 64 bits as hex = 16 chars
}

#[test]
fn test_tool_trace_classify_error() {
    // Type errors
    assert_eq!(
        ToolTrace::classify_error("type mismatch: expected i32"),
        "type_error"
    );
    assert_eq!(
        ToolTrace::classify_error("cannot find type Foo"),
        "type_error"
    );

    // Import errors
    assert_eq!(
        ToolTrace::classify_error("unresolved import std::foo"),
        "import_error"
    );
    assert_eq!(
        ToolTrace::classify_error("no module named requests"),
        "import_error"
    );
    assert_eq!(
        ToolTrace::classify_error("cannot find Bar in this scope"),
        "import_error"
    );

    // Syntax errors
    assert_eq!(
        ToolTrace::classify_error("syntax error near line 10"),
        "syntax_error"
    );
    assert_eq!(
        ToolTrace::classify_error("unexpected token ';'"),
        "syntax_error"
    );

    // Undefined errors
    assert_eq!(
        ToolTrace::classify_error("undefined variable x"),
        "undefined_error"
    );
    assert_eq!(
        ToolTrace::classify_error("method not found in struct"),
        "undefined_error"
    );

    // Argument errors
    assert_eq!(
        ToolTrace::classify_error("wrong number of arguments"),
        "argument_error"
    );
    assert_eq!(
        ToolTrace::classify_error("invalid parameter count"),
        "argument_error"
    );

    // Borrow errors (Rust)
    assert_eq!(
        ToolTrace::classify_error("cannot borrow as mutable"),
        "borrow_error"
    );
    assert_eq!(
        ToolTrace::classify_error("value moved here"),
        "borrow_error"
    );

    // Runtime errors
    assert_eq!(
        ToolTrace::classify_error("thread panicked at"),
        "runtime_error"
    );
    assert_eq!(
        ToolTrace::classify_error("nil pointer dereference"),
        "runtime_error"
    );

    // Permission errors
    assert_eq!(
        ToolTrace::classify_error("permission denied"),
        "permission_error"
    );

    // Network errors
    assert_eq!(
        ToolTrace::classify_error("connection refused"),
        "network_error"
    );
    assert_eq!(
        ToolTrace::classify_error("network timeout"),
        "network_error"
    );

    // Other
    assert_eq!(ToolTrace::classify_error("some random error"), "other");
}



// =========================================================================
// TraceBuilder tests
// =========================================================================


#[test]
fn test_trace_builder_with_metadata() {
    let trace = TraceBuilder::new(TraceEventType::Search)
        .session("sess-789")
        .input(&serde_json::json!({"query": "test"}))
        .metadata(&serde_json::json!({"source": "hybrid"}))
        .output(&serde_json::json!({"count": 10}))
        .duration_ms(250)
        .finish_success(&serde_json::json!({"results": 5}));

    assert_eq!(trace.duration_ms, 250);
    assert!(trace.success);
    assert!(trace.metadata.contains("hybrid"));
}

#[test]
fn test_trace_builder_finish_custom() {
    let trace = TraceBuilder::new(TraceEventType::HookEvent).finish(false, Some("timeout"));

    assert!(!trace.success);
    assert_eq!(trace.error, Some("timeout".to_string()));
}

// =========================================================================
// TraceStore additional tests
// =========================================================================

#[test]
fn test_trace_store_get() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    let event = TraceEvent {
        id: "tr-get-001".to_string(),
        event_type: TraceEventType::Search,
        timestamp: Utc::now(),
        session_id: Some("sess-001".to_string()),
        duration_ms: 100,
        input: "{}".to_string(),
        output: "{}".to_string(),
        metadata: "{}".to_string(),
        success: true,
        error: None,
    };
    store.record(&event).unwrap();

    let found = store.get("tr-get-001").unwrap();
    assert!(found.is_some());
    assert_eq!(found.unwrap().id, "tr-get-001");

    let not_found = store.get("nonexistent").unwrap();
    assert!(not_found.is_none());
}

#[test]
fn test_trace_store_get_by_session() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    for i in 0..3 {
        store
            .record(&TraceEvent {
                id: format!("tr-sess-{i}"),
                event_type: TraceEventType::Search,
                timestamp: Utc::now(),
                session_id: Some("session-A".to_string()),
                duration_ms: 100,
                input: "{}".to_string(),
                output: "{}".to_string(),
                metadata: "{}".to_string(),
                success: true,
                error: None,
            })
            .unwrap();
    }

    let results = store.get_by_session("session-A").unwrap();
    assert_eq!(results.len(), 3);

    let results_b = store.get_by_session("session-B").unwrap();
    assert!(results_b.is_empty());
}



#[test]
fn test_trace_store_count() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    assert_eq!(store.count().unwrap(), 0);

    for i in 0..5 {
        store
            .record(&TraceEvent {
                id: format!("tr-count-{i}"),
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
    }

    assert_eq!(store.count().unwrap(), 5);
}


#[test]
fn test_trace_store_surfaced_items() {
    let temp = TempDir::new().unwrap();
    let store = TraceStore::open(&temp.path().join("traces.db")).unwrap();

    let item = SurfacedItem {
        session_id: "sess-surf".to_string(),
        item_id: "mem-001".to_string(),
        item_type: "memory".to_string(),
        item_preview: Some("Test memory".to_string()),
        surfaced_at: Utc::now(),
        feedback_given: false,
    };
    store.record_surfaced_item(&item).unwrap();

    let unfeedback = store.get_unfeedback_surfaced_items(10).unwrap();
    assert_eq!(unfeedback.len(), 1);

    store.mark_surfaced_feedback("mem-001").unwrap();

    let unfeedback_after = store.get_unfeedback_surfaced_items(10).unwrap();
    assert!(unfeedback_after.is_empty());
}


// =========================================================================
// TraceStats tests
// =========================================================================


// =========================================================================
// TraceTimer tests
// =========================================================================

#[test]
fn test_trace_timer() {
    let timer = TraceTimer::new();
    std::thread::sleep(std::time::Duration::from_millis(10));
    let elapsed = timer.elapsed_ms();
    assert!(elapsed >= 10);
}

#[test]
fn test_trace_timer_default() {
    let timer = TraceTimer::default();
    assert!(timer.elapsed_ms() < 1000);
}

// =========================================================================
// generate_trace_id tests
// =========================================================================

