//! Message type tests.

use claude_rs::message::*;
use serde_json::json;

#[test]
fn test_system_message_parsing() {
    let json = json!({
        "type": "system",
        "subtype": "init",
        "uuid": "msg-123",
        "session_id": "session-456",
        "model": "claude-sonnet-4-5-20250929",
        "cwd": "/home/user",
        "permission_mode": "default",
        "tools": [
            {"name": "Bash", "description": "Run bash commands"}
        ],
        "mcp_servers": [
            {"name": "test-server", "status": "connected"}
        ]
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::System(sys) => {
            assert!(sys.is_init());
            assert_eq!(sys.session_id.as_deref(), Some("session-456"));
            assert_eq!(sys.model.as_deref(), Some("claude-sonnet-4-5-20250929"));
            assert_eq!(sys.cwd.as_deref(), Some("/home/user"));
            assert!(sys.tools.is_some());
            assert_eq!(sys.tool_names(), vec!["Bash"]);
        }
        _ => panic!("Expected System message"),
    }
}

#[test]
fn test_assistant_message_with_text() {
    let json = json!({
        "type": "assistant",
        "uuid": "msg-789",
        "session_id": "session-456",
        "message": {
            "role": "assistant",
            "content": [
                {"type": "text", "text": "Hello! "},
                {"type": "text", "text": "How can I help?"}
            ]
        }
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::Assistant(assistant) => {
            assert_eq!(assistant.text(), "Hello! How can I help?");
            assert_eq!(assistant.text_blocks(), vec!["Hello! ", "How can I help?"]);
            assert!(!assistant.has_tool_use());
        }
        _ => panic!("Expected Assistant message"),
    }
}

#[test]
fn test_assistant_message_with_tool_use() {
    let json = json!({
        "type": "assistant",
        "session_id": "session-456",
        "message": {
            "role": "assistant",
            "content": [
                {"type": "text", "text": "Let me run that command."},
                {
                    "type": "tool_use",
                    "id": "tool_123",
                    "name": "Bash",
                    "input": {"command": "ls -la"}
                }
            ]
        }
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::Assistant(assistant) => {
            assert!(assistant.has_tool_use());
            let tool_uses = assistant.tool_uses();
            assert_eq!(tool_uses.len(), 1);
            assert_eq!(tool_uses[0].name, "Bash");
            assert_eq!(tool_uses[0].id, "tool_123");
        }
        _ => panic!("Expected Assistant message"),
    }
}

#[test]
fn test_assistant_message_with_thinking() {
    let json = json!({
        "type": "assistant",
        "session_id": "session-456",
        "message": {
            "role": "assistant",
            "content": [
                {"type": "thinking", "thinking": "Let me think about this..."},
                {"type": "text", "text": "The answer is 42."}
            ]
        }
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::Assistant(assistant) => {
            assert_eq!(assistant.thinking(), Some("Let me think about this..."));
            assert_eq!(assistant.text(), "The answer is 42.");
        }
        _ => panic!("Expected Assistant message"),
    }
}

#[test]
fn test_user_message_parsing() {
    let json = json!({
        "type": "user",
        "uuid": "msg-user",
        "session_id": "session-456",
        "message": {
            "role": "user",
            "content": [{"type": "text", "text": "Hello Claude"}]
        },
        "is_replay": false
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::User(user) => {
            assert!(!user.is_replay());
            assert_eq!(user.text(), "Hello Claude");
        }
        _ => panic!("Expected User message"),
    }
}

#[test]
fn test_user_replay_message() {
    let json = json!({
        "type": "user",
        "session_id": "session-456",
        "message": {
            "role": "user",
            "content": [{"type": "text", "text": "Previous message"}]
        },
        "is_replay": true
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    assert!(msg.is_replay());
}

#[test]
fn test_result_success() {
    let json = json!({
        "type": "result",
        "subtype": "success",
        "uuid": "msg-result",
        "session_id": "session-456",
        "result": "Task completed successfully",
        "total_cost_usd": 0.0023,
        "duration_ms": 1234,
        "num_turns": 3,
        "usage": {
            "input_tokens": 100,
            "output_tokens": 50
        }
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::Result(result) => {
            assert!(result.is_success());
            assert!(!result.is_max_turns());
            assert!(!result.is_budget_exceeded());
            assert_eq!(result.text(), "Task completed successfully");
            assert_eq!(result.total_cost_usd, Some(0.0023));
            assert_eq!(result.input_tokens(), 100);
            assert_eq!(result.output_tokens(), 50);
        }
        _ => panic!("Expected Result message"),
    }
}

#[test]
fn test_result_max_turns() {
    let json = json!({
        "type": "result",
        "subtype": "error_max_turns",
        "session_id": "session-456",
        "is_error": true
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::Result(result) => {
            assert!(!result.is_success());
            assert!(result.is_max_turns());
        }
        _ => panic!("Expected Result message"),
    }
}

#[test]
fn test_result_budget_exceeded() {
    let json = json!({
        "type": "result",
        "subtype": "error_max_budget_usd",
        "session_id": "session-456",
        "is_error": true,
        "total_cost_usd": 5.0
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::Result(result) => {
            assert!(result.is_budget_exceeded());
        }
        _ => panic!("Expected Result message"),
    }
}

#[test]
fn test_tool_progress_message() {
    let json = json!({
        "type": "tool_progress",
        "uuid": "msg-progress",
        "session_id": "session-456",
        "tool_name": "Read",
        "tool_use_id": "tool_456",
        "elapsed_time_seconds": 1.5
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::ToolProgress(progress) => {
            assert_eq!(progress.tool_name.as_deref(), Some("Read"));
            assert_eq!(progress.elapsed_time_seconds, Some(1.5));
        }
        _ => panic!("Expected ToolProgress message"),
    }
}

#[test]
fn test_status_message() {
    let json = json!({
        "type": "status",
        "session_id": "session-456",
        "status": "compacting"
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::Status(status) => {
            assert_eq!(status.status.as_deref(), Some("compacting"));
        }
        _ => panic!("Expected Status message"),
    }
}

#[test]
fn test_hook_input_message() {
    let json = json!({
        "type": "hook_input",
        "event": "PreToolUse",
        "hook_id": "hook_123",
        "uuid": "msg-hook",
        "session_id": "session-456",
        "input": {
            "tool_name": "Bash",
            "tool_input": {"command": "rm -rf /"}
        }
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::HookInput(hook) => {
            assert_eq!(hook.event_type(), Some("PreToolUse"));
            assert_eq!(hook.hook_id.as_deref(), Some("hook_123"));
        }
        _ => panic!("Expected HookInput message"),
    }
}

#[test]
fn test_compact_boundary_message() {
    let json = json!({
        "type": "compact_boundary",
        "uuid": "msg-compact",
        "session_id": "session-456",
        "compact_metadata": {"reason": "context_limit"}
    });

    let msg: Message = serde_json::from_value(json).unwrap();

    match msg {
        Message::CompactBoundary(boundary) => {
            assert_eq!(boundary.session_id.as_deref(), Some("session-456"));
            assert!(boundary.compact_metadata.is_some());
        }
        _ => panic!("Expected CompactBoundary message"),
    }
}

#[test]
fn test_message_session_id() {
    let json = json!({
        "type": "system",
        "session_id": "test-session"
    });

    let msg: Message = serde_json::from_value(json).unwrap();
    assert_eq!(msg.session_id(), Some("test-session"));
}

#[test]
fn test_message_uuid() {
    let json = json!({
        "type": "system",
        "uuid": "test-uuid"
    });

    let msg: Message = serde_json::from_value(json).unwrap();
    assert_eq!(msg.uuid(), Some("test-uuid"));
}

#[test]
fn test_content_block_tool_use() {
    let json = json!({
        "type": "tool_use",
        "id": "tool_abc",
        "name": "Edit",
        "input": {
            "file_path": "/test.txt",
            "old_string": "foo",
            "new_string": "bar"
        }
    });

    let block: ContentBlock = serde_json::from_value(json).unwrap();

    match block {
        ContentBlock::ToolUse(tu) => {
            assert_eq!(tu.id, "tool_abc");
            assert_eq!(tu.name, "Edit");
            assert_eq!(tu.get_input("file_path"), Some(&json!("/test.txt")));
        }
        _ => panic!("Expected ToolUse block"),
    }
}

#[test]
fn test_content_block_tool_result() {
    let json = json!({
        "type": "tool_result",
        "tool_use_id": "tool_abc",
        "content": "File edited successfully",
        "is_error": false
    });

    let block: ContentBlock = serde_json::from_value(json).unwrap();

    match block {
        ContentBlock::ToolResult(tr) => {
            assert_eq!(tr.tool_use_id, "tool_abc");
            assert!(!tr.is_error);
        }
        _ => panic!("Expected ToolResult block"),
    }
}
