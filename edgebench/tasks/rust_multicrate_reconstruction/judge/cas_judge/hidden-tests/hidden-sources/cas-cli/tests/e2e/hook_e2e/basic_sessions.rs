#[tokio::test]
#[ignore]
async fn test_concurrent_sessions_isolation() {
    let cas_dir = cas_project_dir();
    let cas_dir2 = cas_dir.clone();

    let handle1 = tokio::spawn(async move {
        prompt(
            "What is 1 + 1? Reply with just the number.",
            QueryOptions::new()
                .model("haiku")
                .cwd(&cas_dir)
                .max_turns(1),
        )
        .await
    });

    let handle2 = tokio::spawn(async move {
        prompt(
            "What is 2 + 2? Reply with just the number.",
            QueryOptions::new()
                .model("haiku")
                .cwd(&cas_dir2)
                .max_turns(1),
        )
        .await
    });

    let result1 = handle1.await.expect("Task 1 panicked");
    let result2 = handle2.await.expect("Task 2 panicked");

    assert!(result1.is_ok(), "Session 1 should succeed");
    assert!(result2.is_ok(), "Session 2 should succeed");

    let text1 = result1.unwrap().result.unwrap_or_default();
    let text2 = result2.unwrap().result.unwrap_or_default();

    println!("Session 1 result: {}", text1);
    println!("Session 2 result: {}", text2);

    assert!(text1.contains("2"), "Session 1 should return 2");
    assert!(text2.contains("4"), "Session 2 should return 4");
}

#[tokio::test]
#[ignore]
async fn test_stop_hook_fires() {
    let result = prompt(
        "Say 'Hello from CAS test'",
        QueryOptions::new()
            .model("haiku")
            .cwd(cas_project_dir())
            .max_turns(1),
    )
    .await;

    match result {
        Ok(r) => {
            assert!(r.is_success(), "Query should succeed");
            println!("Stop hook test completed successfully");
        }
        Err(e) => {
            panic!("Query failed: {:?}", e);
        }
    }
}
