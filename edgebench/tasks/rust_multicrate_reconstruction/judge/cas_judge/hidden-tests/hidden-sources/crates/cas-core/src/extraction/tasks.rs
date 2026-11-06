    #[test]
    fn test_extract_from_close_reason_numbered() {
        let reason = r#"Implemented SSR hydration fix:
1. Changed createRoot to hydrateRoot for SSR compatibility
2. Added useIsClient hook using useSyncExternalStore
3. Created ClientOnly wrapper component for browser-only code"#;

        let learnings = extract_from_close_reason(reason, "cas-1234");
        assert_eq!(learnings.len(), 3);
        assert!(learnings[0].content.contains("hydrateRoot"));
        assert!(learnings[1].content.contains("useIsClient"));
        assert!(learnings[2].content.contains("ClientOnly"));
    }

    #[test]
    fn test_extract_discoveries_from_notes() {
        let notes = r#"[14:30] Started investigation
DISCOVERY: ExClaude Session API returns messages one-by-one via await_response/2
[15:00] Implemented fix
Decision: Use streaming approach instead of batch"#;

        let (discoveries, decisions) = extract_from_notes(notes, "cas-abcd");
        assert_eq!(discoveries.len(), 1);
        assert!(discoveries[0].content.contains("ExClaude"));
        assert_eq!(decisions.len(), 1);
    }

    #[test]
    fn test_build_task_extraction_prompt() {
        let task = Task {
            id: "cas-1234".to_string(),
            title: "Fix SSR hydration".to_string(),
            task_type: TaskType::Bug,
            status: TaskStatus::Closed,
            priority: Priority::HIGH,
            close_reason: Some("Fixed by using hydrateRoot".to_string()),
            notes: "Some notes here".to_string(),
            ..Default::default()
        };

        let prompt = build_task_extraction_prompt(&task);
        assert!(prompt.contains("cas-1234"));
        assert!(prompt.contains("Fix SSR hydration"));
        assert!(prompt.contains("hydrateRoot"));
    }
