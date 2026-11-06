use super::*;

#[tokio::test]
#[ignore]
async fn test_session_start_injects_task_context() {
    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(cas_project_dir())
            .max_turns(1),
        |mut sess| async move {
            sess.send("What tasks are currently ready according to your context? Just list the task IDs if any.").await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Result(ref r) = msg {
                    println!("Response: {:?}", r.result);
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            assert!(r.is_success(), "Query should succeed");
            let text = r.result.as_deref().unwrap_or("");
            println!("SessionStart context test result: {}", text);
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}

/// Test that CAS SessionStart hook provides memory context
#[tokio::test]
#[ignore]
async fn test_session_start_injects_memory_context() {
    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(cas_project_dir())
            .max_turns(1),
        |mut sess| async move {
            sess.send("What helpful memories or learnings do you have in your context? List a few if any.").await?;

            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Result(ref r) = msg {
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            assert!(r.is_success(), "Query should succeed");
            let text = r.result.as_deref().unwrap_or("");
            println!("Memory context test result: {}", text);
        }
        Err(e) => {
            panic!("Session failed: {:?}", e);
        }
    }
}

// =============================================================================
// PreToolUse Hook Tests
// =============================================================================

/// Test that CAS PreToolUse hook allows Read operations
#[tokio::test]
#[ignore]
async fn test_pre_tool_use_allows_read() {
    let result = prompt(
        "Read the contents of CLAUDE.md and tell me what the first heading says.",
        QueryOptions::new()
            .model("haiku")
            .cwd(cas_project_dir())
            .max_turns(3),
    )
    .await;

    match result {
        Ok(r) => {
            assert!(r.is_success(), "Query should succeed");
            let text = r.result.as_deref().unwrap_or("");
            println!("PreToolUse Read test result: {}", text);
            assert!(
                text.to_lowercase().contains("cas") || text.to_lowercase().contains("claude"),
                "Response should mention CAS or Claude from CLAUDE.md"
            );
        }
        Err(e) => {
            panic!("Query failed: {:?}", e);
        }
    }
}

/// Test that CAS PreToolUse hook allows Bash operations
#[tokio::test]
#[ignore]
async fn test_pre_tool_use_allows_bash() {
    let result = prompt(
        "Run 'ls -la' in the current directory and tell me how many items there are.",
        QueryOptions::new()
            .model("haiku")
            .cwd(cas_project_dir())
            .max_turns(3),
    )
    .await;

    match result {
        Ok(r) => {
            assert!(r.is_success(), "Query should succeed");
            let text = r.result.as_deref().unwrap_or("");
            println!("PreToolUse Bash test result: {}", text);
        }
        Err(e) => {
            panic!("Query failed: {:?}", e);
        }
    }
}

// =============================================================================
// Multi-turn Session Tests
// =============================================================================

/// Test multi-turn session with CAS hooks
#[tokio::test]
#[ignore]
async fn test_multi_turn_with_hooks() {
    let result = session(
        QueryOptions::new()
            .model("haiku")
            .cwd(cas_project_dir())
            .max_turns(5),
        |mut sess| async move {
            sess.send("What project am I in according to your context?")
                .await?;
            loop {
                let msg = sess.await_response(None).await?;
                if matches!(msg, Message::Result(_)) {
                    break;
                }
            }

            sess.send("What are the main directories in this project?")
                .await?;
            loop {
                let msg = sess.await_response(None).await?;
                if let Message::Result(ref r) = msg {
                    println!("Multi-turn result: {:?}", r.result);
                    return Ok(r.clone());
                }
            }
        },
    )
    .await;

    match result {
        Ok(r) => {
            assert!(r.is_success(), "Query should succeed");
            let text = r.result.as_deref().unwrap_or("");
            assert!(
                text.to_lowercase().contains("cas") || text.to_lowercase().contains("cli"),
                "Response should mention CAS project structure"
            );
        }
        Err(e) => {
            panic!("Multi-turn session failed: {:?}", e);
        }
    }
}

// =============================================================================
// Concurrent Session Tests
// =============================================================================

/// Test that concurrent sessions don't interfere with each other

// =============================================================================
// Stop Hook Tests
// =============================================================================

/// Test that Stop hook fires and can provide feedback

// =============================================================================
// Verification Jail Tests
// =============================================================================

// Test that verification jail blocks tool use when task has pending_verification.
