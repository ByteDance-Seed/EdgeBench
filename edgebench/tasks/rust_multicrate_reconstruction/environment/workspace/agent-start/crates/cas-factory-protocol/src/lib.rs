//! Protocol types for CAS Factory client-server communication.
//!
//! This crate defines the message types and codec for WebSocket communication
//! between Factory servers and clients (TUI, Tauri desktop app, web).
//!
//! # Protocol Overview
//!
//! All messages are encoded using MessagePack for efficient binary serialization.
//! The protocol supports two modes:
//!
//! - **Live mode**: Real-time terminal multiplexing with PTY I/O
//! - **Playback mode**: Recording playback with seek/speed control
//!
//! # Example
//!
//! ```rust
//! use cas_factory_protocol::{ClientMessage, codec};
//!
//! // Encode a client message
//! let msg = ClientMessage::Ping { id: 42 };
//! let bytes = codec::encode(&msg).unwrap();
//!
//! // Decode a client message
//! let decoded: ClientMessage = codec::decode(&bytes).unwrap();
//! assert_eq!(msg, decoded);
//! ```

pub mod codec;
pub mod compression;
mod messages;
pub mod transport;

pub use codec::{ProtocolError, decode, encode};
pub use compression::{COMPRESSION_THRESHOLD, CompressionError};
pub use messages::*;
pub use transport::TransportError;

/// Protocol version for compatibility checking.
///
/// Clients should send this in the Connect message.
/// Servers should reject connections with incompatible versions.
///
/// Version history:
/// - 1.0.0: Initial protocol with basic messaging
/// - 1.1.0: Added Batch, Reconnect, ReconnectAccepted, ConnectionHealth messages
/// - 1.2.0: Reconnect handshake includes client metadata; server supports delta replay
pub const PROTOCOL_VERSION: &str = "1.2.0";
