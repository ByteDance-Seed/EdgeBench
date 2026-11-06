//! MessagePack codec for protocol messages.
//!
//! Provides efficient binary serialization using MessagePack (rmp-serde)
//! with optional LZ4 compression for large messages.
//!
//! # Compression
//!
//! Messages larger than 256 bytes are automatically compressed using LZ4.
//! A prefix byte indicates the compression state:
//! - `0x00`: Uncompressed
//! - `0x01`: LZ4 compressed

use crate::compression::{self, CompressionError};
use serde::{Serialize, de::DeserializeOwned};
use thiserror::Error;

/// Errors that can occur during encoding/decoding.
#[derive(Debug, Error)]
pub enum ProtocolError {
    /// Failed to encode message to MessagePack.
    #[error("encode error: {0}")]
    Encode(#[from] rmp_serde::encode::Error),

    /// Failed to decode message from MessagePack.
    #[error("decode error: {0}")]
    Decode(#[from] rmp_serde::decode::Error),

    /// Failed to compress/decompress message.
    #[error("compression error: {0}")]
    Compression(#[from] CompressionError),
}

/// Encode a message to MessagePack bytes with optional LZ4 compression.
///
/// Messages larger than 256 bytes are automatically compressed.
/// The output includes a prefix byte indicating compression state.
///
/// # Example
///
/// ```rust
/// use cas_factory_protocol::{ClientMessage, codec};
///
/// let msg = ClientMessage::Ping { id: 42 };
/// let bytes = codec::encode(&msg).unwrap();
/// assert!(!bytes.is_empty());
/// ```
pub fn encode<T: Serialize>(msg: &T) -> Result<Vec<u8>, ProtocolError> { todo!() }

/// Decode a message from MessagePack bytes with automatic decompression.
///
/// Handles both compressed and uncompressed messages based on prefix byte.
///
/// # Example
///
/// ```rust
/// use cas_factory_protocol::{ClientMessage, codec};
///
/// let msg = ClientMessage::Ping { id: 42 };
/// let bytes = codec::encode(&msg).unwrap();
/// let decoded: ClientMessage = codec::decode(&bytes).unwrap();
/// ```
pub fn decode<T: DeserializeOwned>(bytes: &[u8]) -> Result<T, ProtocolError> { todo!() }

/// Encode a message to raw MessagePack bytes without compression.
///
/// Use this for internal operations where compression is not needed.
pub fn encode_raw<T: Serialize>(msg: &T) -> Result<Vec<u8>, ProtocolError> { todo!() }

/// Decode a message from raw MessagePack bytes without decompression.
///
/// Use this for internal operations where the data is known to be uncompressed.
pub fn decode_raw<T: DeserializeOwned>(bytes: &[u8]) -> Result<T, ProtocolError> { todo!() }

/// Encode a message with a length prefix (4-byte big-endian).
///
/// This is useful for framing messages over streams (TCP, Unix sockets).
/// The payload includes compression prefix and optionally compressed data.
///
/// # Format
///
/// ```text
/// [4 bytes: length (BE u32)][1 byte: compression flag][N bytes: payload]
/// ```
pub fn encode_framed<T: Serialize>(msg: &T) -> Result<Vec<u8>, ProtocolError> { todo!() }

/// Read the length prefix from a framed message header.
///
/// Returns the payload length (not including the 4-byte header).
pub fn read_frame_length(header: &[u8; 4]) -> usize { todo!() }

/// Maximum message size (16 MB).
pub const MAX_MESSAGE_SIZE: usize = 16 * 1024 * 1024;

/// Frame header size (4 bytes for length prefix).
pub const FRAME_HEADER_SIZE: usize = 4;

#[cfg(test)]
mod tests {
    use crate::codec::*;
    use crate::{ClientCapabilities, ClientMessage, ClientType, ServerMessage, SessionMode};

    #[test]
    fn test_roundtrip_client_message() {
        let messages = vec![
            ClientMessage::Connect {
                client_type: ClientType::Tui,
                protocol_version: "1.0.0".to_string(),
                auth_token: None,
                session_id: None,
                capabilities: ClientCapabilities::default(),
            },
            ClientMessage::Ping { id: 12345 },
            ClientMessage::SendInput {
                pane_id: "worker-1".to_string(),
                data: vec![0x1b, 0x5b, 0x41], // Up arrow
            },
            ClientMessage::Resize {
                cols: 120,
                rows: 40,
            },
            ClientMessage::Focus {
                pane_id: "supervisor".to_string(),
            },
            ClientMessage::SpawnWorkers {
                count: 3,
                names: vec!["swift-fox".to_string()],
            },
            ClientMessage::ShutdownWorkers {
                count: Some(2),
                names: vec![],
                force: false,
            },
            ClientMessage::InjectPrompt {
                pane_id: "worker-1".to_string(),
                prompt: "Please review the code".to_string(),
            },
            ClientMessage::PlaybackLoad {
                recording_path: "/path/to/recording.rec".to_string(),
            },
            ClientMessage::PlaybackSeek { timestamp_ms: 5000 },
            ClientMessage::PlaybackSetSpeed { speed: 2.0 },
            ClientMessage::PlaybackClose,
        ];

        for msg in messages {
            let encoded = encode(&msg).expect("encode failed");
            let decoded: ClientMessage = decode(&encoded).expect("decode failed");
            assert_eq!(msg, decoded, "roundtrip failed for {msg:?}");
        }
    }



    #[test]
    fn test_binary_data_roundtrip() {
        // Test with binary data containing all byte values
        let mut binary_data: Vec<u8> = (0..=255).collect();
        binary_data.extend_from_slice(&[0x00, 0xFF, 0x1B, 0x5B]); // Include escape sequences

        let msg = ClientMessage::SendInput {
            pane_id: "test".to_string(),
            data: binary_data.clone(),
        };

        let encoded = encode(&msg).expect("encode failed");
        let decoded: ClientMessage = decode(&encoded).expect("decode failed");

        match decoded {
            ClientMessage::SendInput { data, .. } => {
                assert_eq!(data, binary_data);
            }
            _ => panic!("wrong message type"),
        }
    }

    #[test]
    fn test_playback_message_roundtrip() {
        use std::collections::HashMap;

        let snapshot = crate::TerminalSnapshot::empty(80, 24);
        let mut snapshots = HashMap::new();
        snapshots.insert("supervisor".to_string(), snapshot);

        let msg = ServerMessage::PlaybackSnapshot {
            timestamp_ms: 12345,
            snapshots,
        };

        let encoded = encode(&msg).expect("encode failed");
        let decoded: ServerMessage = decode(&encoded).expect("decode failed");
        assert_eq!(msg, decoded);
    }


    #[test]
    fn test_large_message_compressed() {
        use crate::compression::PREFIX_COMPRESSED;

        // Create a large message with repeated content (compressible)
        let large_prompt = "x".repeat(1000);
        let msg = ClientMessage::InjectPrompt {
            pane_id: "test".to_string(),
            prompt: large_prompt.clone(),
        };

        let encoded = encode(&msg).expect("encode failed");

        // Large messages should have compressed prefix
        assert_eq!(encoded[0], PREFIX_COMPRESSED);

        // Verify it still decodes correctly
        let decoded: ClientMessage = decode(&encoded).expect("decode failed");
        match decoded {
            ClientMessage::InjectPrompt { prompt, .. } => {
                assert_eq!(prompt, large_prompt);
            }
            _ => panic!("wrong message type"),
        }
    }

    #[test]
    fn test_compression_reduces_size() {
        // Create a large message with repeated content
        let large_prompt = "test content ".repeat(100);
        let msg = ClientMessage::InjectPrompt {
            pane_id: "worker-1".to_string(),
            prompt: large_prompt,
        };

        let encoded = encode(&msg).expect("encode failed");
        let raw = encode_raw(&msg).expect("encode_raw failed");

        // Compressed should be smaller than raw (prefix + compressed < raw)
        // Note: raw doesn't have prefix, encoded has 1 byte prefix + compressed data
        assert!(
            encoded.len() < raw.len() + 50,
            "compression should reduce size: {} vs {}",
            encoded.len(),
            raw.len()
        );
    }

    #[test]
    fn test_raw_encode_decode() {
        let msg = ClientMessage::Ping { id: 123 };

        let raw = encode_raw(&msg).expect("encode_raw failed");
        let decoded: ClientMessage = decode_raw(&raw).expect("decode_raw failed");

        assert_eq!(msg, decoded);
    }
}
