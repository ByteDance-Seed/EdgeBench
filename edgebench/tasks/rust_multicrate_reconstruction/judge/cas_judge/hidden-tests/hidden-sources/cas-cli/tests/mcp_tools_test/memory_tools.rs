#[tokio::test]
async fn test_get_entry() {
    let (_temp, service) = setup_cas();

    // First create an entry
    let req = RememberRequest {
        scope: "project".to_string(),
        content: "Test get content".to_string(),
        entry_type: "learning".to_string(),
        tags: None,
        title: None,
        importance: 0.5,
        valid_from: None,
        valid_until: None,
        team_id: None,
    };

    let result = service
        .cas_remember(Parameters(req))
        .await
        .expect("remember should succeed");

    let text = extract_text(result);
    let id = extract_entry_id(&text).expect("should have ID");

    // Now get the entry
    let get_req = IdRequest { id: id.to_string() };
    let result = service
        .cas_get(Parameters(get_req))
        .await
        .expect("get should succeed");

    let text = extract_text(result);
    assert!(text.contains("Test get content"));
    assert!(text.contains("Learning"));
}

#[tokio::test]
async fn test_update_entry() {
    let (_temp, service) = setup_cas();

    // Create entry
    let req = RememberRequest {
        scope: "project".to_string(),
        content: "Original content".to_string(),
        entry_type: "learning".to_string(),
        tags: None,
        title: None,
        importance: 0.5,
        valid_from: None,
        valid_until: None,
        team_id: None,
    };

    let result = service
        .cas_remember(Parameters(req))
        .await
        .expect("remember should succeed");

    let text = extract_text(result);
    let id = extract_entry_id(&text).expect("should have ID");

    // Update entry
    let update_req = EntryUpdateRequest {
        id: id.to_string(),
        content: Some("Updated content".to_string()),
        tags: Some("updated,test".to_string()),
        importance: Some(0.9),
    };

    let result = service
        .cas_update(Parameters(update_req))
        .await
        .expect("update should succeed");

    let text = extract_text(result);
    assert!(text.contains("Updated"));
    assert!(text.contains("content"));

    // Verify update
    let get_req = IdRequest { id: id.to_string() };
    let result = service
        .cas_get(Parameters(get_req))
        .await
        .expect("get should succeed");

    let text = extract_text(result);
    assert!(text.contains("Updated content"));
}
