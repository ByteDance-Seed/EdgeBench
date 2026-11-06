    #[test]
    fn test_no_assistant_messages() {
        let entries = vec![
            r#"{"type":"user","message":{"role":"user","content":[{"type":"text","text":"Hello"}]}}"#,
            r#"{"type":"queue-operation","operation":"enqueue"}"#,
        ];

        let file = create_test_transcript(&entries);
        let result = get_last_assistant_text(file.path()).unwrap();
        assert_eq!(result, None);
    }

    #[test]
    fn test_multiple_content_blocks() {
        let entries = vec![
            r#"{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Part 1"},{"type":"text","text":"Part 2"}]}}"#,
        ];

        let file = create_test_transcript(&entries);
        let result = get_last_assistant_text(file.path()).unwrap();

        assert_eq!(result, Some("Part 1\nPart 2".to_string()));
    }

    #[test]
    fn test_tool_use_blocks_ignored() {
        let entries = vec![
            r#"{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Using tool"},{"type":"tool_use","id":"123","name":"Read","input":{}}]}}"#,
        ];

        let file = create_test_transcript(&entries);
        let result = get_last_assistant_text(file.path()).unwrap();

        assert_eq!(result, Some("Using tool".to_string()));
    }

    #[test]
    fn test_parse_transcript_nonexistent_file() {
        let path = Path::new("/nonexistent/transcript.jsonl");
        let messages = parse_transcript_to_messages(path).unwrap();
        assert!(messages.is_empty());
    }

    #[test]
    fn test_extract_transcript_metadata_no_model() {
        // Transcript without model info (e.g., older format)
        let entries = vec![
            r#"{"type":"user","version":"2.0.50","message":{"role":"user","content":[{"type":"text","text":"Hello"}]}}"#,
            r#"{"type":"assistant","version":"2.0.50","message":{"role":"assistant","content":[{"type":"text","text":"Hi there!"}]}}"#,
        ];

        let file = create_test_transcript(&entries);
        let metadata = extract_transcript_metadata(file.path()).unwrap();

        assert_eq!(metadata.model, None);
        assert_eq!(metadata.tool_version, Some("2.0.50".to_string()));
    }
