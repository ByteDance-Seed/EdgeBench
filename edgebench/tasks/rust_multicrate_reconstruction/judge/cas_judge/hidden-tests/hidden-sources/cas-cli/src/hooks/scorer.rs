    #[test]
    fn test_context_query_with_task() {
        let context = ContextQuery {
            task_titles: vec!["Implement feature X".to_string()],
            cwd: "/project".to_string(),
            user_prompt: None,
            recent_files: vec![],
        };
        assert!(context.has_content());
        assert!(context.to_query_string().contains("Implement feature X"));
    }
