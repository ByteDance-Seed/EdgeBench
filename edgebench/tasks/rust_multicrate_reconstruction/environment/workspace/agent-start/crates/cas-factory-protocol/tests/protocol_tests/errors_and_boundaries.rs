use crate::*;


#[test]
fn test_decode_invalid_msgpack() {
    // Random bytes that aren't valid MessagePack
    let garbage = vec![0xFF, 0xFE, 0xFD, 0xFC];
    let result = codec::decode::<ClientMessage>(&garbage);
    assert!(result.is_err());
}


#[test]
fn test_decode_truncated_message() {
    let msg = ClientMessage::InjectPrompt {
        pane_id: "test".to_string(),
        prompt: "Some prompt text".to_string(),
    };
    let encoded = codec::encode(&msg).unwrap();

    // Truncate the message
    let truncated = &encoded[..encoded.len() / 2];
    let result = codec::decode::<ClientMessage>(truncated);
    assert!(result.is_err());
}

#[test]
fn test_decode_extra_bytes_appended() {
    let msg = ClientMessage::Ping { id: 42 };
    let mut encoded = codec::encode(&msg).unwrap();

    // Append extra bytes
    encoded.extend_from_slice(b"extra garbage bytes");

    // MessagePack should still decode successfully (ignoring trailing data)
    // This behavior depends on rmp-serde implementation
    let result = codec::decode::<ClientMessage>(&encoded);
    // Either succeeds (ignoring extra) or fails - both are acceptable
    if let Ok(decoded) = result {
        assert_eq!(decoded, msg);
    }
}

// =============================================================================
// Boundary Values
// =============================================================================

#[test]
fn test_max_u32_ping_id() {
    let msg = ClientMessage::Ping { id: u32::MAX };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}


#[test]
fn test_max_u64_timestamp() {
    let msg = ClientMessage::PlaybackSeek {
        timestamp_ms: u64::MAX,
    };
    let encoded = codec::encode(&msg).unwrap();
    let decoded: ClientMessage = codec::decode(&encoded).unwrap();
    assert_eq!(msg, decoded);
}

#[test]
fn test_playback_speed_edge_values() {
    let speeds = vec![
        0.0,
        0.01,
        0.5,
        1.0,
        2.0,
        10.0,
        100.0,
        f32::MAX,
        f32::MIN_POSITIVE,
    ];

    for speed in speeds {
        let msg = ClientMessage::PlaybackSetSpeed { speed };
        let encoded = codec::encode(&msg).unwrap();
        let decoded: ClientMessage = codec::decode(&encoded).unwrap();
        assert_eq!(msg, decoded, "Speed {speed} roundtrip failed");
    }
}

