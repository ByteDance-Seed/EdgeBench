//! Factory Server Integration Tests
//!
//! Tests for the WebSocket client-server communication layer in CAS Factory.
//! These tests verify the integration between:
//! - FactoryServer (WebSocket server accepting client connections)
//! - Factory protocol messages (ClientMessage, ServerMessage)
//! - State synchronization (FullState, DirectorUpdate, etc.)
//!
//! # Prerequisites
//!
//! Some tests are marked with #[ignore] pending implementation.
//! See cas-4d96 for the task to implement these tests.
//!
//! # Running
//!
//! ```bash
//! # Run all factory server tests
//! cargo test --test factory_server_test
//!
//! # Run including ignored tests (after cas-4d96 implementation)
//! cargo test --test factory_server_test -- --include-ignored
//! ```

use std::net::SocketAddr;
use std::time::Duration;

use cas_factory_protocol::{
    ClientCapabilities, ClientMessage, ClientType, ErrorCode, PROTOCOL_VERSION, RowData,
    ServerMessage, SessionMode, SessionState, StyleRun, codec,
};
use futures_util::{SinkExt, StreamExt};
use tokio::net::TcpListener;
use tokio::sync::mpsc;
use tokio::time::timeout;
use tokio_tungstenite::tungstenite::Message;
use tokio_tungstenite::{accept_async, connect_async};

// =============================================================================
// Test Fixtures
// =============================================================================

/// Mock Factory server for testing client behavior.
///
/// Listens on a random port and handles protocol messages.
struct MockFactoryServer {
    addr: SocketAddr,
    shutdown_tx: mpsc::Sender<()>,
}

impl MockFactoryServer {
    /// Start a mock server that responds with basic protocol messages.
    async fn start() -> Self { todo!() }

    /// Handle a client message and return an appropriate response.
    fn handle_message(msg: ClientMessage) -> Option<ServerMessage> { todo!() }

    fn url(&self) -> String { todo!() }

    async fn shutdown(self) { todo!() }
}

/// Helper to connect and complete handshake with a mock server.
async fn connect_and_handshake(
    url: &str,
    client_type: ClientType,
) -> Result<
    (
        futures_util::stream::SplitSink<
            tokio_tungstenite::WebSocketStream<
                tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
            >,
            Message,
        >,
        futures_util::stream::SplitStream<
            tokio_tungstenite::WebSocketStream<
                tokio_tungstenite::MaybeTlsStream<tokio::net::TcpStream>,
            >,
        >,
        String,
    ),
    String,
> { todo!() }

// =============================================================================
// Protocol Handshake Tests
// =============================================================================

#[path = "factory_server_test_cases/tests.rs"]
mod tests;
