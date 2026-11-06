#[test]
fn test_all_client_type_variants() {
    let variants = vec![ClientType::Tui, ClientType::Desktop, ClientType::Web];

    for client_type in variants {
        let msg = ClientMessage::Connect {
            client_type,
            protocol_version: PROTOCOL_VERSION.to_string(),
            auth_token: None,
            session_id: None,
            capabilities: ClientCapabilities::default(),
        };
        let encoded = codec::encode(&msg).unwrap();
        let decoded: ClientMessage = codec::decode(&encoded).unwrap();
        assert_eq!(msg, decoded, "ClientType {client_type:?} roundtrip failed");
    }
}
