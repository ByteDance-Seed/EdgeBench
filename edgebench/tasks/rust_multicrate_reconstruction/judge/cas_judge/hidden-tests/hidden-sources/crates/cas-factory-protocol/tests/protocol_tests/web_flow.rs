#[test]
fn test_ping_pong_keepalive() {
    // Server Ping (for health monitoring)
    let ping = ServerMessage::Ping { id: 12345 };
    let encoded = codec::encode(&ping).unwrap();
    let decoded: ServerMessage = codec::decode(&encoded).unwrap();
    assert_eq!(ping, decoded);

    // Client Pong response
    let pong = ClientMessage::Pong { id: 12345 };
    let encoded = codec::encode(&pong).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(pong, decoded);
}
