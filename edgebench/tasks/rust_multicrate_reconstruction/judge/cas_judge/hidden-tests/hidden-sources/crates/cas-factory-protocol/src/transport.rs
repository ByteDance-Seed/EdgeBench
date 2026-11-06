    #[tokio::test]
    async fn test_protocol_handshake() {
        let addr = start_protocol_server().await;
        let url = format!("ws://{addr}");

        let (ws_stream, _) = connect_async(&url).await.unwrap();
        let (mut write, mut read) = ws_stream.split();

        // Send Connect
        let connect = ClientMessage::Connect {
            client_type: ClientType::Tui,
            protocol_version: crate::PROTOCOL_VERSION.to_string(),
            auth_token: None, // Localhost test - no auth needed
            session_id: None,
            capabilities: ClientCapabilities::default(),
        };
        send_message(&mut write, &connect).await.unwrap();

        // Receive Connected
        let response: ServerMessage = recv_message(&mut read).await.unwrap();
        match response {
            ServerMessage::Connected {
                session_id,
                client_id,
                mode,
            } => {
                assert_eq!(session_id, "test-session");
                assert_eq!(client_id, 1);
                assert_eq!(mode, SessionMode::Live);
            }
            _ => panic!("Expected Connected, got {response:?}"),
        }

        // Send Ping
        let ping = ClientMessage::Ping { id: 123 };
        send_message(&mut write, &ping).await.unwrap();

        // Receive Pong
        let pong: ServerMessage = recv_message(&mut read).await.unwrap();
        match pong {
            ServerMessage::Pong { id } => {
                assert_eq!(id, 123);
            }
            _ => panic!("Expected Pong, got {pong:?}"),
        }
    }

    #[tokio::test]
    async fn test_unsplit_send_recv() {
        let addr = start_echo_server().await;
        let url = format!("ws://{addr}");

        let (mut ws_stream, _) = connect_async(&url).await.unwrap();

        // Send using unsplit API
        let msg = ClientMessage::Resize {
            cols: 120,
            rows: 40,
        };
        send(&mut ws_stream, &msg).await.unwrap();

        // Receive using unsplit API
        let received: ClientMessage = recv(&mut ws_stream).await.unwrap();
        assert_eq!(msg, received);
    }

    #[tokio::test]
    async fn test_binary_data_transport() {
        let addr = start_echo_server().await;
        let url = format!("ws://{addr}");

        let (mut ws_stream, _) = connect_async(&url).await.unwrap();

        // Send message with binary data
        let binary_data: Vec<u8> = (0..=255).collect();
        let msg = ClientMessage::SendInput {
            pane_id: "test-pane".to_string(),
            data: binary_data.clone(),
        };
        send(&mut ws_stream, &msg).await.unwrap();

        // Receive and verify
        let received: ClientMessage = recv(&mut ws_stream).await.unwrap();
        match received {
            ClientMessage::SendInput { pane_id, data } => {
                assert_eq!(pane_id, "test-pane");
                assert_eq!(data, binary_data);
            }
            _ => panic!("Wrong message type"),
        }
    }
