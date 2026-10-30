#[test]
fn test_extraction_result_default() {
    let result = ExtractionResult::default();
    assert!(result.learnings.is_empty());
    assert!(result.preferences.is_empty());
    assert!(result.rules.is_empty());
    assert!(!result.deferred);
}

#[test]
fn test_parse_response_with_markdown() {
    let extractor = AIExtractor::new(AIExtractorConfig::default());
    let response = r#"Here's the extraction:

```json
{
    "learnings": [{"content": "VouchWall uses mise for task running", "quality_score": 7, "confidence": 0.7}]
}
```
"#;

    let result = extractor.parse_response(response, "test-id").unwrap();
    assert_eq!(result.learnings.len(), 1);
}

#[test]
fn test_short_content_filtered() {
    let extractor = AIExtractor::new(AIExtractorConfig::default());
    // Content < 10 chars should be filtered
    let response = r#"{
            "learnings": [
                {"content": "Short", "quality_score": 9, "confidence": 0.9},
                {"content": "This is a longer learning about the project structure", "quality_score": 7, "confidence": 0.8}
            ]
        }"#;

    let result = extractor.parse_response(response, "test-id").unwrap();
    assert_eq!(result.learnings.len(), 1);
    assert!(result.learnings[0].content.contains("longer learning"));
}

#[test]
fn test_parse_response_only_preferences() {
    let extractor = AIExtractor::new(AIExtractorConfig::default());
    let response = r#"{
            "learnings": [],
            "preferences": [
                {"content": "User prefers Tailwind CSS with custom theme colors", "quality_score": 7, "confidence": 0.8, "tags": ["styling"]}
            ],
            "rules": []
        }"#;

    let result = extractor.parse_response(response, "test-id").unwrap();
    assert!(result.learnings.is_empty());
    assert_eq!(result.preferences.len(), 1);
    assert!(result.preferences[0].content.contains("Tailwind"));
}

#[test]
fn test_ai_extractor_sync_defers() {
    let extractor = AIExtractor::new(AIExtractorConfig::default());
    let observation = Entry {
        id: "test".to_string(),
        entry_type: EntryType::Observation,
        content: "Test observation".to_string(),
        ..Default::default()
    };

    // Sync extraction should defer (async needed for AI)
    let result = extractor.extract(&observation).unwrap();
    assert!(result.deferred);
}

#[test]
fn test_default_extractor() {
    let extractor = default_extractor();
    let observation = Entry {
        id: "test".to_string(),
        entry_type: EntryType::Observation,
        content: "Test".to_string(),
        ..Default::default()
    };

    let result = extractor.extract(&observation).unwrap();
    assert!(result.deferred);
}

#[test]
fn test_ai_extractor_constructor() {
    let extractor = ai_extractor();
    // Should have default config
    let observation = Entry {
        id: "test".to_string(),
        entry_type: EntryType::Observation,
        content: "Test observation for extraction".to_string(),
        ..Default::default()
    };

    // Should work without panicking
    let result = extractor.extract(&observation).unwrap();
    assert!(result.deferred);
}

#[test]
fn test_build_batch_prompt_multiple_observations() {
    let extractor = AIExtractor::new(AIExtractorConfig::default());
    let observations = vec![
        Entry {
            id: "obs1".to_string(),
            entry_type: EntryType::Observation,
            content: "Write: created new API handler".to_string(),
            source_tool: Some("Write".to_string()),
            tags: vec!["api".to_string()],
            ..Default::default()
        },
        Entry {
            id: "obs2".to_string(),
            entry_type: EntryType::Observation,
            content: "Bash: cargo test passed".to_string(),
            source_tool: Some("Bash".to_string()),
            ..Default::default()
        },
    ];

    let prompt = extractor.build_batch_prompt(&observations);
    // Both observations should be in the prompt
    assert!(prompt.contains("[Write]"));
    assert!(prompt.contains("[Bash]"));
    assert!(prompt.contains("(tags: api)"));
    assert!(prompt.contains("API handler"));
    assert!(prompt.contains("cargo test"));
}
