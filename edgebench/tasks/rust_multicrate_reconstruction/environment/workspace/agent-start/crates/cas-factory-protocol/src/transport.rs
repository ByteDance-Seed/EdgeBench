//! WebSocket transport utilities for Factory protocol.
//!
//! Provides async send/receive functions for protocol messages over WebSocket connections.
//!
//! # Example
//!
//! ```rust,ignore
//! use cas_factory_protocol::{ClientMessage, ServerMessage, transport};
//! use tokio_tungstenite::connect_async;
//!
//! // Connect to server
//! let (ws_stream, _) = connect_async("ws://localhost:8080").await?;
//! let (mut write, mut read) = ws_stream.split();
//!
//! // Send a message
//! let msg = ClientMessage::Ping { id: 42 };
//! transport::send_message(&mut write, &msg).await?;
//!
//! // Receive a message
//! let response: ServerMessage = transport::recv_message(&mut read).await?;
//! ```

use futures_util::stream::{SplitSink, SplitStream};
use futures_util::{SinkExt, StreamExt};
use serde::{Serialize, de::DeserializeOwned};
use thiserror::Error;
use tokio_tungstenite::WebSocketStream;
use tokio_tungstenite::tungstenite::Message;

use crate::codec;

/// Errors that can occur during WebSocket transport.
#[derive(Debug, Error)]
pub enum TransportError {
    /// WebSocket error.
    #[error("websocket error: {0}")]
    WebSocket(#[from] tokio_tungstenite::tungstenite::Error),

    /// Protocol encoding/decoding error.
    #[error("protocol error: {0}")]
    Protocol(#[from] codec::ProtocolError),

    /// Connection was closed.
    #[error("connection closed")]
    ConnectionClosed,

    /// Received unexpected message type (not binary).
    #[error("unexpected message type: expected binary, got {0}")]
    UnexpectedMessageType(String),
}

/// Send a message over a WebSocket connection.
///
/// Encodes the message using MessagePack and sends it as a binary WebSocket message.
///
/// # Type Parameters
///
/// * `S` - The underlying stream type (e.g., `TcpStream`, `MaybeTlsStream`)
/// * `T` - The message type to send (must implement `Serialize`)
///
/// # Errors
///
/// Returns `TransportError::Protocol` if encoding fails.
/// Returns `TransportError::WebSocket` if sending fails.
pub async fn send_message<S, T>(
    sink: &mut SplitSink<WebSocketStream<S>, Message>,
    msg: &T,
) -> Result<(), TransportError>
where
    S: tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin,
    T: Serialize,
{ todo!() }

/// Receive a message from a WebSocket connection.
///
/// Receives a binary WebSocket message and decodes it using MessagePack.
///
/// # Type Parameters
///
/// * `S` - The underlying stream type (e.g., `TcpStream`, `MaybeTlsStream`)
/// * `T` - The message type to receive (must implement `DeserializeOwned`)
///
/// # Errors
///
/// Returns `TransportError::ConnectionClosed` if the connection is closed.
/// Returns `TransportError::UnexpectedMessageType` if a non-binary message is received.
/// Returns `TransportError::Protocol` if decoding fails.
pub async fn recv_message<S, T>(
    stream: &mut SplitStream<WebSocketStream<S>>,
) -> Result<T, TransportError>
where
    S: tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin,
    T: DeserializeOwned,
{ todo!() }

/// Send a message over a WebSocket connection (unsplit stream).
///
/// Convenience function for when you have an unsplit WebSocket stream.
pub async fn send<S, T>(ws: &mut WebSocketStream<S>, msg: &T) -> Result<(), TransportError>
where
    S: tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin,
    T: Serialize,
{ todo!() }

/// Receive a message from a WebSocket connection (unsplit stream).
///
/// Convenience function for when you have an unsplit WebSocket stream.
pub async fn recv<S, T>(ws: &mut WebSocketStream<S>) -> Result<T, TransportError>
where
    S: tokio::io::AsyncRead + tokio::io::AsyncWrite + Unpin,
    T: DeserializeOwned,
{ todo!() }

#[cfg(test)]
mod tests {
    use crate::transport::*;
    use crate::{ClientCapabilities, ClientMessage, ClientType, ServerMessage, SessionMode};
    use futures_util::StreamExt;
    use std::net::SocketAddr;
    use tokio::net::TcpListener;
    use tokio_tungstenite::{accept_async, connect_async};

    /// Start a test WebSocket server that echoes messages back.
    async fn start_echo_server() -> SocketAddr {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();

        tokio::spawn(async move {
            if let Ok((stream, _)) = listener.accept().await {
                let ws_stream = accept_async(stream).await.unwrap();
                let (mut write, mut read) = ws_stream.split();

                // Echo all binary messages back
                while let Some(Ok(msg)) = read.next().await {
                    if let Message::Binary(data) = msg {
                        let _ = write.send(Message::Binary(data)).await;
                    }
                }
            }
        });

        addr
    }

    /// Start a test WebSocket server that responds to Connect with Connected.
    async fn start_protocol_server() -> SocketAddr {
        let listener = TcpListener::bind("127.0.0.1:0").await.unwrap();
        let addr = listener.local_addr().unwrap();

        tokio::spawn(async move {
            if let Ok((stream, _)) = listener.accept().await {
                let ws_stream = accept_async(stream).await.unwrap();
                let (mut write, mut read) = ws_stream.split();

                // Wait for Connect message
                if let Some(Ok(Message::Binary(bytes))) = read.next().await {
                    let msg: ClientMessage = codec::decode(&bytes).unwrap();
                    if matches!(msg, ClientMessage::Connect { .. }) {
                        // Send Connected response
                        let response = ServerMessage::Connected {
                            session_id: "test-session".to_string(),
                            client_id: 1,
                            mode: SessionMode::Live,
                        };
                        let response_bytes = codec::encode(&response).unwrap();
                        let _ = write.send(Message::Binary(response_bytes.into())).await;
                    }
                }

                // Echo subsequent messages
                while let Some(Ok(msg)) = read.next().await {
                    if let Message::Binary(data) = msg {
                        // Decode as ClientMessage, re-encode as ServerMessage response
                        if let Ok(client_msg) = codec::decode::<ClientMessage>(&data) {
                            let response = match client_msg {
                                ClientMessage::Ping { id } => ServerMessage::Pong { id },
                                _ => continue,
                            };
                            let response_bytes = codec::encode(&response).unwrap();
                            let _ = write.send(Message::Binary(response_bytes.into())).await;
                        }
                    }
                }
            }
        });

        addr
    }

    #[tokio::test]
    async fn test_send_recv_roundtrip() {
        let addr = start_echo_server().await;
        let url = format!("ws://{addr}");

        let (ws_stream, _) = connect_async(&url).await.unwrap();
        let (mut write, mut read) = ws_stream.split();

        // Send a client message
        let msg = ClientMessage::Ping { id: 42 };
        send_message(&mut write, &msg).await.unwrap();

        // Receive the echoed message
        let received: ClientMessage = recv_message(&mut read).await.unwrap();
        assert_eq!(msg, received);
    }



}
