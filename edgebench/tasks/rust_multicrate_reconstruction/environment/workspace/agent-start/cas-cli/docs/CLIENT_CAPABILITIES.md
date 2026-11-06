# Factory Protocol Client Capabilities

This document describes the client capability negotiation system in the CAS Factory Protocol and provides a matrix of features supported by each client type.

## Overview

Clients declare their capabilities when connecting to the Factory Server via the `ClientCapabilities` struct in the `Connect` message. The server uses these capabilities to decide which message types to send to each client.

```rust
pub struct ClientCapabilities {
    /// Client can handle raw PTY output (VT100 sequences)
    pub raw_pty_output: bool,
    /// Client can handle server-rendered RowData snapshots
    pub row_snapshots: bool,
}
```

## Client Capability Matrix

| Feature | TUI | Desktop (Tauri) | Web (ghostty-web) |
|---------|-----|-----------------|-------------------|
| **Compression (LZ4)** | Yes | Yes | Yes |
| **Batch Messages** | Yes | Yes | Yes |
| **Reconnection** | Yes | Yes | Yes |
| **Health Monitoring** | Yes | Yes | Yes |
| **Ping/Pong Keepalive** | Yes | Yes | Yes |
| **Raw PTY Output** | No | Yes | Yes |
| **Row Snapshots** | Yes | No | No |

## Feature Details

### Compression (LZ4)

All clients receive LZ4-compressed messages transparently via the codec layer. The compression prefix byte (`0x00` = uncompressed, `0x01` = compressed) is handled automatically by `cas_factory_protocol::codec`.

**Performance**: 66-99% compression ratio, <1ms overhead per operation.

### Batch Messages

The server may batch multiple messages into a single `ServerMessage::Batch` to reduce WebSocket frame overhead. All clients must recursively unwrap batch messages to process the inner messages.

```rust
ServerMessage::Batch { messages } => {
    for msg in messages {
        handle_message(msg);
    }
}
```

### Reconnection

All clients support automatic reconnection with exponential backoff:

| Parameter | TUI | Desktop |
|-----------|-----|---------|
| Initial delay | 1s | 1s |
| Max delay | 30s | 30s |
| Max attempts | Unlimited | 10 |

The reconnection flow uses `ClientMessage::Reconnect` with session metadata (protocol version, client type, capabilities, and session ID), and the server responds with `ServerMessage::ReconnectAccepted` before replaying missed updates or requesting a full resync.

### Health Monitoring

The server periodically sends `ServerMessage::ConnectionHealth` messages with RTT measurements. Clients should use these for connection quality indicators.

```rust
ServerMessage::ConnectionHealth { rtt_ms, status } => {
    update_connection_indicator(rtt_ms, status);
}
```

### Ping/Pong Keepalive

Clients send `ClientMessage::Ping` messages, and the server responds with `ServerMessage::Pong` containing the original timestamp for RTT calculation.

### Raw PTY Output (`raw_pty_output`)

When `raw_pty_output: true`, the server sends `ServerMessage::PaneOutput` containing raw VT100/ANSI escape sequences. This is preferred for clients with native terminal emulation.

**Clients using this mode:**
- **Desktop (Tauri)**: Uses ghostty-web for native VT100 processing
- **Web**: Uses ghostty-web WASM module

**Benefits:**
- Native cursor handling
- Full VT100 feature support
- Lower server CPU (no parsing)

### Row Snapshots (`row_snapshots`)

When `row_snapshots: true`, the server sends `ServerMessage::PaneRowsUpdate` with pre-rendered `RowData` including styled cells and cursor position. This is for clients without native terminal emulation.

**Clients using this mode:**
- **TUI**: Uses ratatui for rendering server-provided rows

**Benefits:**
- Simpler client implementation
- Consistent rendering across clients
- Server-side scrollback management

## Client Configuration Summary

### TUI Client (`cas-cli/src/ui/factory/client.rs`)

```rust
ClientCapabilities {
    raw_pty_output: false,  // Uses server-rendered rows
    row_snapshots: true,    // Receives RowData snapshots
}
```

The TUI renders server-provided `RowData` using ratatui widgets. This allows the server to handle all terminal emulation and scrollback management.

### Desktop Client (`cas-desktop/src-tauri/src/client.rs`)

```rust
ClientCapabilities {
    raw_pty_output: true,   // Uses ghostty-web's native VT100
    row_snapshots: false,   // Doesn't need server-rendered rows
}
```

The Desktop app embeds ghostty-web which provides full terminal emulation. Raw PTY bytes are passed directly to the ghostty surface for rendering.

### Web Client (Future)

```rust
ClientCapabilities {
    raw_pty_output: true,   // Uses ghostty-web WASM
    row_snapshots: false,   // Doesn't need server-rendered rows
}
```

Web clients will use the ghostty-web WASM module for native terminal emulation, similar to the Desktop client.

## Protocol Version

Current protocol version: Defined in `cas_factory_protocol::PROTOCOL_VERSION`

Clients must send their protocol version in the `Connect` message. The server may reject connections with incompatible versions via `ServerMessage::Error` with `ErrorCode::VersionMismatch`.

## Adding New Capabilities

1. Add the capability flag to `ClientCapabilities` in `crates/cas-factory-protocol/src/messages.rs`
2. Update the server to check the capability before sending capability-specific messages
3. Update this documentation
4. Add protocol tests for the new capability
