#[tokio::test]
async fn test_handshake_with_50ms_rtt() {
    let latency = LatencyConfig::new(50);
    let server = LatencyMockServer::start(latency).await;

    let start = Instant::now();
    let result = connect_and_handshake(&server.url()).await;
    let elapsed = start.elapsed();

    assert!(result.is_ok(), "Handshake should succeed: {result:?}");
    // RTT is 50ms, handshake requires 1 round trip, expect ~50ms
    assert!(
        elapsed >= Duration::from_millis(40),
        "Should observe latency: {elapsed:?}"
    );
    assert!(
        elapsed < Duration::from_millis(200),
        "Should complete reasonably: {elapsed:?}"
    );

    server.shutdown().await;
}

#[tokio::test]
async fn test_handshake_with_100ms_rtt() {
    let latency = LatencyConfig::new(100);
    let server = LatencyMockServer::start(latency).await;

    let start = Instant::now();
    let result = connect_and_handshake(&server.url()).await;
    let elapsed = start.elapsed();

    assert!(result.is_ok(), "Handshake should succeed: {result:?}");
    // RTT is 100ms, expect ~100ms
    assert!(
        elapsed >= Duration::from_millis(80),
        "Should observe latency: {elapsed:?}"
    );
    assert!(
        elapsed < Duration::from_millis(300),
        "Should complete reasonably: {elapsed:?}"
    );

    server.shutdown().await;
}

#[tokio::test]
async fn test_message_ordering_preserved_under_latency() {
    let latency = LatencyConfig::new(50);
    let server = LatencyMockServer::start(latency).await;

    let (mut write, mut read, _) = connect_and_handshake(&server.url())
        .await
        .expect("Handshake failed");

    // Send multiple inputs rapidly
    for i in 1..=5 {
        let input = ClientMessage::SendInput {
            pane_id: "test".to_string(),
            data: format!("msg{i}").into_bytes(),
        };
        let bytes = codec::encode(&input).unwrap();
        write.send(Message::Binary(bytes)).await.unwrap();
    }

    // Receive responses and verify ordering
    let mut received_seqs = Vec::new();
    for _ in 0..5 {
        let response = timeout(Duration::from_secs(10), read.next())
            .await
            .expect("Timeout")
            .expect("Connection closed")
            .expect("Receive error");

        if let Message::Binary(bytes) = response {
            let msg: ServerMessage = codec::decode(&bytes).expect("Decode failed");
            if let ServerMessage::PaneRowsUpdate { seq, .. } = msg {
                received_seqs.push(seq);
            }
        }
    }

    // Verify messages arrived in order
    assert_eq!(received_seqs.len(), 5, "Should receive all 5 responses");
    for i in 0..4 {
        assert!(
            received_seqs[i] < received_seqs[i + 1],
            "Messages should arrive in order: {received_seqs:?}"
        );
    }

    server.shutdown().await;
}

#[tokio::test]
async fn test_health_monitoring_latency_simulation() {
    // Test that ConnectionHealth message can represent latency
    let health_good = ServerMessage::ConnectionHealth {
        rtt_ms: 20,
        quality: ConnectionQuality::Good,
    };
    let encoded = codec::encode(&health_good).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert!(
        matches!(
            decoded,
            ServerMessage::ConnectionHealth {
                rtt_ms: 20,
                quality: ConnectionQuality::Good,
            }
        ),
        "Good quality with low RTT"
    );

    let health_degraded = ServerMessage::ConnectionHealth {
        rtt_ms: 150,
        quality: ConnectionQuality::Degraded,
    };
    let encoded = codec::encode(&health_degraded).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert!(
        matches!(
            decoded,
            ServerMessage::ConnectionHealth {
                rtt_ms: 150,
                quality: ConnectionQuality::Degraded,
            }
        ),
        "Degraded quality with higher RTT"
    );

    let health_poor = ServerMessage::ConnectionHealth {
        rtt_ms: 500,
        quality: ConnectionQuality::Poor,
    };
    let encoded = codec::encode(&health_poor).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert!(
        matches!(
            decoded,
            ServerMessage::ConnectionHealth {
                rtt_ms: 500,
                quality: ConnectionQuality::Poor,
            }
        ),
        "Poor quality with high RTT"
    );
}
