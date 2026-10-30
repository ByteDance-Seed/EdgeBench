    #[tokio::test]
    async fn test_async_send_input() {
        let mut runner = AsyncPtyRunner::new();
        runner.spawn("cat", &[]).await.expect("spawn failed");

        // Give cat time to start
        runner.wait(Duration::from_millis(100)).await;

        // Send input
        runner
            .send_input("test input\n")
            .await
            .expect("send failed");

        // Wait for echo
        runner
            .wait_for_text("test input", Duration::from_secs(5))
            .await
            .expect("wait failed");

        // Clean up
        runner.send_key(Key::CtrlD).await.expect("send key failed");
    }

    #[tokio::test]
    async fn test_async_wait_stable() {
        let mut runner = AsyncPtyRunner::new();
        runner
            .spawn("echo", &["quick output"])
            .await
            .expect("spawn failed");

        // Wait for output to stabilize
        runner
            .wait_stable(Duration::from_millis(200))
            .await
            .expect("wait stable failed");

        let output = runner.get_output();
        assert!(output.contains("quick output"));
    }

    #[tokio::test]
    async fn test_async_wait_for_condition() {
        let mut runner = AsyncPtyRunner::new();
        runner
            .spawn("sh", &["-c", "echo 'line1'; sleep 0.1; echo 'line2'"])
            .await
            .expect("spawn failed");

        // Wait for both lines
        runner
            .wait_for(
                |output| output.contains("line1") && output.contains("line2"),
                Duration::from_secs(5),
            )
            .await
            .expect("wait failed");
    }

    #[tokio::test]
    async fn test_async_process_exit_detection() {
        let mut runner = AsyncPtyRunner::new();
        runner
            .spawn("sh", &["-c", "exit 0"])
            .await
            .expect("spawn failed");

        // Wait for process to exit
        runner.wait(Duration::from_millis(200)).await;

        // Now waiting for text should fail with ProcessExited
        let result = runner
            .wait_for_text("will not appear", Duration::from_secs(1))
            .await;

        assert!(matches!(result, Err(AsyncPtyError::ProcessExited)));
    }
