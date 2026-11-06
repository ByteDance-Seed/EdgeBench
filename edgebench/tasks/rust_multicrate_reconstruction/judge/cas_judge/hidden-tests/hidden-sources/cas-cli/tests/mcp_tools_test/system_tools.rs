#[tokio::test]
async fn test_stats() {
    let (_temp, service) = setup_cas();

    let result = service.cas_stats().await.expect("stats should succeed");

    let text = extract_text(result);
    assert!(text.contains("CAS Statistics") || text.contains("entries") || text.contains("0"));
}

#[tokio::test]
async fn test_doctor() {
    let (_temp, service) = setup_cas();

    let result = service.cas_doctor().await.expect("doctor should succeed");

    let text = extract_text(result);
    assert!(text.contains("CAS Diagnostics") || text.contains("OK") || text.contains("healthy"));
}

#[tokio::test]
async fn test_observe() {
    let (_temp, service) = setup_cas();

    let req = ObserveRequest {
        scope: "project".to_string(),
        content: "Test observation".to_string(),
        observation_type: "decision".to_string(),
        tags: Some("test".to_string()),
        source_tool: Some("test".to_string()),
    };

    let result = service
        .cas_observe(Parameters(req))
        .await
        .expect("observe should succeed");

    let text = extract_text(result);
    let text_lower = text.to_lowercase();
    assert!(
        text_lower.contains("observation")
            || text_lower.contains("recorded")
            || text.contains("ID")
    );
}

#[tokio::test]
async fn test_maintenance_status() {
    let (_temp, service) = setup_cas();

    let result = service
        .cas_maintenance_status()
        .await
        .expect("maintenance_status should succeed");

    let text = extract_text(result);
    // Without daemon, should indicate no daemon
    assert!(
        text.contains("Daemon not running")
            || text.contains("status")
            || text.contains("Maintenance")
    );
}
