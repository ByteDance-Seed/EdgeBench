#[tokio::test]
async fn test_mock_server_focus_updates_state() {
    let server = MockFactoryServer::start().await;

    let (mut write, mut read, _) = connect_and_handshake(&server.url(), ClientType::Desktop)
        .await
        .expect("Handshake failed");

    // Send Focus
    let focus = ClientMessage::Focus {
        pane_id: "supervisor".to_string(),
    };
    let bytes = codec::encode(&focus).unwrap();
    write.send(Message::Binary(bytes)).await.unwrap();

    // Receive FullState
    let response = timeout(Duration::from_secs(5), read.next())
        .await
        .expect("Timeout")
        .expect("Connection closed")
        .expect("Receive error");

    if let Message::Binary(bytes) = response {
        let msg: ServerMessage = codec::decode(&bytes).expect("Decode failed");
        match msg {
            ServerMessage::FullState { state } => {
                assert_eq!(
                    state.focused_pane,
                    Some("supervisor".to_string()),
                    "State should reflect focus change"
                );
            }
            _ => panic!("Expected FullState, got {msg:?}"),
        }
    } else {
        panic!("Expected binary message");
    }

    server.shutdown().await;
}

#[tokio::test]
async fn test_mock_server_reconnect_with_resync() {
    let server = MockFactoryServer::start().await;

    // First, connect and get session ID
    let (write, read, session_id) = connect_and_handshake(&server.url(), ClientType::Tui)
        .await
        .expect("Initial handshake failed");

    // Simulate disconnect
    drop(write);
    drop(read);

    // Reconnect with old sequence number (resync needed)
    let (ws_stream, _) = connect_async(&server.url())
        .await
        .expect("Reconnect failed");
    let (mut write, mut read) = ws_stream.split();

    // Send Reconnect message with old seq (< 1000)
    let reconnect_msg = ClientMessage::Reconnect {
        protocol_version: PROTOCOL_VERSION.to_string(),
        auth_token: None,
        client_type: ClientType::Tui,
        capabilities: ClientCapabilities {
            raw_pty_output: false,
            row_snapshots: true,
        },
        session_id: session_id.clone(),
        client_id: "original-client".to_string(),
        last_seq: 500, // Too old, needs resync
    };
    let bytes = codec::encode(&reconnect_msg).unwrap();
    write.send(Message::Binary(bytes)).await.unwrap();

    // Receive ReconnectAccepted with resync_needed = true
    let response = timeout(Duration::from_secs(5), read.next())
        .await
        .expect("Timeout")
        .expect("Connection closed")
        .expect("Receive error");

    if let Message::Binary(bytes) = response {
        let msg: ServerMessage = codec::decode(&bytes).expect("Decode failed");
        match msg {
            ServerMessage::ReconnectAccepted {
                new_client_id,
                resync_needed,
            } => {
                assert!(
                    new_client_id.contains(&session_id),
                    "Should include session ID in new client ID"
                );
                assert!(resync_needed, "Should need resync with old sequence");
            }
            _ => panic!("Expected ReconnectAccepted, got {msg:?}"),
        }
    } else {
        panic!("Expected binary message");
    }

    server.shutdown().await;
}

#[tokio::test]
#[ignore = "See cas-4d96: Implement FactoryServer integration tests"]
async fn test_factory_server_playback_mode_startup() {
    // TODO (cas-687e): Test that FactoryServer starts in playback mode
    //
    // 1. Create a FactoryServer with playback mode config
    // 2. Load a test recording
    // 3. Connect a client
    // 4. Verify Connected response with mode: Playback
    // 5. Verify PlaybackOpened is sent with metadata
    todo!("Implement after cas-687e")
}

#[tokio::test]
#[ignore = "See cas-4d96: Implement FactoryServer integration tests"]
async fn test_factory_server_resize() {
    // TODO (cas-687e): Test Resize command
    //
    // 1. Start FactoryServer
    // 2. Connect client
    // 3. Verify initial dimensions in FullState
    // 4. Send Resize { cols: 120, rows: 40 }
    // 5. Verify FullState update with new dimensions
    todo!("Implement after cas-687e")
}

#[tokio::test]
#[ignore = "See cas-4d96: Implement FactoryServer integration tests"]
async fn test_factory_server_playback_seek() {
    // TODO (cas-687e): Test playback seeking
    //
    // 1. Start FactoryServer in playback mode with test recording
    // 2. Connect client
    // 3. Send PlaybackSeek { timestamp_ms: 5000 }
    // 4. Verify PlaybackSnapshot received with correct timestamp
    // 5. Verify snapshot content matches recording at that time
    todo!("Implement after cas-687e")
}

#[tokio::test]
#[ignore = "See cas-4d96: Implement FactoryServer integration tests"]
async fn test_factory_server_error_handling() {
    // TODO (cas-687e): Test error responses
    //
    // 1. Start FactoryServer
    // 2. Connect client
    // 3. Send Focus { pane_id: "nonexistent" }
    // 4. Verify Error response with code: PaneNotFound
    // 5. Send invalid mode operation
    // 6. Verify Error with code: InvalidMode
    todo!("Implement after cas-687e")
}
