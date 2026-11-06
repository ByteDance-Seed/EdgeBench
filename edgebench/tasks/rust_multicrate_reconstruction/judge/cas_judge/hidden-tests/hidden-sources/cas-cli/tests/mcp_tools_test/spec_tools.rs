#[tokio::test]
async fn test_spec_list() {
    let (_temp, service) = setup_cas_service();

    // Create specs
    for i in 1..=2 {
        let mut req = spec_req("create");
        req.title = Some(format!("List Spec {i}"));
        req.summary = Some(format!("Spec {i} for list"));
        req.spec_type = Some("feature".to_string());

        service
            .spec(Parameters(req))
            .await
            .expect("create should succeed");
    }

    // List all
    let list_req = spec_req("list");

    let result = service
        .spec(Parameters(list_req))
        .await
        .expect("spec list should succeed");

    let text = extract_text(result);
    assert!(
        text.contains("spec-") || text.contains("List Spec"),
        "Should list specs: {text}"
    );
}

#[tokio::test]
async fn test_spec_approve() {
    let (_temp, service) = setup_cas_service();

    // Create
    let mut create_req = spec_req("create");
    create_req.title = Some("Approve Test".to_string());
    create_req.spec_type = Some("feature".to_string());

    let result = service.spec(Parameters(create_req)).await.expect("create");
    let spec_id = extract_spec_id(&extract_text(result)).expect("spec ID");

    // Approve
    let mut approve_req = spec_req("approve");
    approve_req.id = Some(spec_id.clone());

    let result = service
        .spec(Parameters(approve_req))
        .await
        .expect("approve");
    let text = extract_text(result);
    assert!(
        text.to_lowercase().contains("approv") || text.contains(&spec_id),
        "Should approve: {text}"
    );
}
