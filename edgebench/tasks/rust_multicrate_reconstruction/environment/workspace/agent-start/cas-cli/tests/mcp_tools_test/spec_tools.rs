use crate::support::*;
use cas::mcp::tools::service::SpecRequest;
use cas::mcp::tools::*;
use rmcp::handler::server::wrapper::Parameters;
use tempfile::TempDir;

/// Helper to setup CAS with CasService for consolidated tools
fn setup_cas_service() -> (TempDir, CasService) { todo!() }

/// Create a SpecRequest with only the action set
fn spec_req(action: &str) -> SpecRequest { todo!() }

/// Extract spec ID from output text
fn extract_spec_id(text: &str) -> Option<String> { todo!() }

#[tokio::test]
async fn test_spec_create_basic() {
    let (_temp, service) = setup_cas_service();

    let mut req = spec_req("create");
    req.title = Some("Test Spec".to_string());
    req.summary = Some("A test specification".to_string());
    req.spec_type = Some("feature".to_string());

    let result = service
        .spec(Parameters(req))
        .await
        .expect("spec create should succeed");

    let text = extract_text(result);
    assert!(
        text.contains("spec-") || text.to_lowercase().contains("created"),
        "Should create spec: {text}"
    );
}

#[tokio::test]
async fn test_spec_create_with_fields() {
    let (_temp, service) = setup_cas_service();

    let mut req = spec_req("create");
    req.title = Some("Full Spec".to_string());
    req.summary = Some("Comprehensive test spec".to_string());
    req.goals = Some("Goal 1,Goal 2".to_string());
    req.acceptance_criteria = Some("Tests pass".to_string());
    req.spec_type = Some("epic".to_string());
    req.tags = Some("important".to_string());

    let result = service
        .spec(Parameters(req))
        .await
        .expect("spec create should succeed");

    let text = extract_text(result);
    assert!(
        extract_spec_id(&text).is_some() || text.to_lowercase().contains("created"),
        "Should create spec: {text}"
    );
}

#[tokio::test]
async fn test_spec_show() {
    let (_temp, service) = setup_cas_service();

    // Create a spec
    let mut create_req = spec_req("create");
    create_req.title = Some("Show Test Spec".to_string());
    create_req.summary = Some("Spec for show test".to_string());
    create_req.spec_type = Some("feature".to_string());

    let result = service
        .spec(Parameters(create_req))
        .await
        .expect("spec create should succeed");

    let text = extract_text(result);
    let spec_id = extract_spec_id(&text).expect("should have spec ID");

    // Show the spec
    let mut show_req = spec_req("show");
    show_req.id = Some(spec_id.clone());

    let result = service
        .spec(Parameters(show_req))
        .await
        .expect("spec show should succeed");

    let text = extract_text(result);
    assert!(
        text.contains("Show Test Spec") || text.contains(&spec_id),
        "Should show spec: {text}"
    );
}


#[tokio::test]
async fn test_spec_update() {
    let (_temp, service) = setup_cas_service();

    // Create
    let mut create_req = spec_req("create");
    create_req.title = Some("Original Title".to_string());
    create_req.summary = Some("Original summary".to_string());
    create_req.spec_type = Some("feature".to_string());

    let result = service.spec(Parameters(create_req)).await.expect("create");
    let spec_id = extract_spec_id(&extract_text(result)).expect("spec ID");

    // Update
    let mut update_req = spec_req("update");
    update_req.id = Some(spec_id.clone());
    update_req.title = Some("Updated Title".to_string());

    let result = service.spec(Parameters(update_req)).await.expect("update");
    let text = extract_text(result);
    assert!(
        text.to_lowercase().contains("updat") || text.contains(&spec_id),
        "Should update: {text}"
    );
}


#[tokio::test]
async fn test_spec_delete() {
    let (_temp, service) = setup_cas_service();

    // Create
    let mut create_req = spec_req("create");
    create_req.title = Some("Delete Test".to_string());
    create_req.spec_type = Some("feature".to_string());

    let result = service.spec(Parameters(create_req)).await.expect("create");
    let spec_id = extract_spec_id(&extract_text(result)).expect("spec ID");

    // Delete
    let mut delete_req = spec_req("delete");
    delete_req.id = Some(spec_id.clone());

    let result = service.spec(Parameters(delete_req)).await.expect("delete");
    let text = extract_text(result);
    assert!(
        text.to_lowercase().contains("delet") || text.contains(&spec_id),
        "Should delete: {text}"
    );
}

#[tokio::test]
async fn test_spec_types() {
    let (_temp, service) = setup_cas_service();

    for spec_type in ["epic", "feature", "api", "component", "migration"] {
        let mut req = spec_req("create");
        req.title = Some(format!("{spec_type} Spec"));
        req.spec_type = Some(spec_type.to_string());

        let result = service.spec(Parameters(req)).await;
        assert!(result.is_ok(), "{spec_type} spec should create");
    }
}
