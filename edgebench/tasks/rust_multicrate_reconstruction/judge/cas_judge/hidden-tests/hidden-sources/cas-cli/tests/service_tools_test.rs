#[test]
fn test_skill_request_create() {
    let json = json!({
        "action": "create",
        "name": "Format Code",
        "description": "Run cargo fmt",
        "invocation": "cargo fmt",
        "skill_type": "command"
    });

    let req: SkillRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.action, "create");
    assert_eq!(req.name, Some("Format Code".to_string()));
    assert_eq!(req.description, Some("Run cargo fmt".to_string()));
    assert_eq!(req.invocation, Some("cargo fmt".to_string()));
    assert_eq!(req.skill_type, Some("command".to_string()));
}

#[test]
fn test_all_rule_actions_recognized() {
    let actions = vec![
        "create", "show", "update", "delete", "list", "list_all", "helpful", "harmful", "sync",
    ];

    for action in actions {
        let json = json!({ "action": action });
        let req: RuleRequest = serde_json::from_value(json).unwrap();
        assert_eq!(req.action, action);
    }
}

#[test]
fn test_all_skill_actions_recognized() {
    let actions = vec![
        "create", "show", "update", "delete", "list", "list_all", "enable", "disable", "sync",
        "use",
    ];

    for action in actions {
        let json = json!({ "action": action });
        let req: SkillRequest = serde_json::from_value(json).unwrap();
        assert_eq!(req.action, action);
    }
}

#[test]
fn test_all_agent_actions_recognized() {
    let actions = vec![
        "register",
        "unregister",
        "whoami",
        "heartbeat",
        "list",
        "cleanup",
        "loop_start",
        "loop_cancel",
        "loop_status",
        "lease_history",
    ];

    for action in actions {
        let json = json!({ "action": action });
        let req: AgentRequest = serde_json::from_value(json).unwrap();
        assert_eq!(req.action, action);
    }
}

#[test]
fn test_context_for_subagent() {
    let json = json!({
        "action": "context_for_subagent",
        "task_id": "cas-1234",
        "max_tokens": 3000,
        "include_memories": false
    });

    let req: SearchContextRequest = serde_json::from_value(json).unwrap();
    assert_eq!(req.task_id, Some("cas-1234".to_string()));
    assert_eq!(req.max_tokens, Some(3000));
    assert_eq!(req.include_memories, Some(false));
}
