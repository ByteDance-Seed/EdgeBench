# Changelog

All notable changes to the CAS Factory Protocol will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-01-31

### Added
- Reconnect handshake now includes protocol metadata (client type, capabilities, auth token) so the server can resume sessions without a prior Connect
- Delta replay buffer on the server for true incremental resync when `last_seq` is within the retained window
- Reconnect flow now replays missed updates or performs a full state + content resync

### Changed
- `Reconnect` message now includes `protocol_version`, `client_type`, and `capabilities`
- Protocol version bumped from `1.1.0` to `1.2.0`

## [1.1.0] - 2026-01-31

### Added

#### Compression
- **LZ4 compression** for messages larger than 256 bytes
- Prefix byte detection for compression state:
  - `0x00`: Uncompressed MessagePack
  - `0x01`: LZ4 compressed MessagePack
- Compression is transparent to clients (codec handles automatically)
- Typical 30-50% reduction in WebSocket bandwidth for terminal updates

#### New Message Types

**ClientMessage:**
- `Reconnect { protocol_version, auth_token, client_type, capabilities, session_id, client_id, last_seq }` - Resume session after disconnect with sequence tracking
- `Pong { id }` - Response to server-initiated health check pings

**ServerMessage:**
- `Batch { messages }` - Bundle multiple updates into single WebSocket frame for efficiency
- `ReconnectAccepted { new_client_id, resync_needed }` - Confirms session resumption with resync indicator
- `ConnectionHealth { rtt_ms, quality }` - Periodic connection quality metrics
- `Ping { id }` - Server-initiated health check for RTT measurement

#### New Types
- `ConnectionQuality` enum with thresholds:
  - `Excellent` - RTT < 50ms
  - `Good` - RTT < 150ms
  - `Fair` - RTT < 300ms
  - `Poor` - RTT >= 300ms

### Changed

- `Connected` message now includes `client_id: u64` field for reconnection tracking
- Protocol version bumped from `1.0.0` to `1.1.0`

### Wire Format

Messages are encoded as:
```
[prefix_byte][payload]
```

Where:
- `prefix_byte = 0x00`: payload is raw MessagePack
- `prefix_byte = 0x01`: payload is LZ4-compressed MessagePack

Decompression yields the original MessagePack bytes which deserialize to `ClientMessage` or `ServerMessage`.

### Reconnection Flow

1. Client detects disconnect
2. Client reconnects WebSocket
3. Client sends `Reconnect { protocol_version, auth_token, client_type, capabilities, session_id, client_id, last_seq }`
4. Server responds with `ReconnectAccepted { new_client_id, resync_needed }`
5. If `resync_needed = true`, server sends `FullState` and initial terminal content
6. If `resync_needed = false`, server replays incremental updates from the replay buffer after `last_seq`

Gap threshold: >1000 missed sequences triggers full resync.

### Health Monitoring Flow

1. Server sends `Ping { id }` periodically (every 10 seconds)
2. Client responds with `Pong { id }`
3. Server calculates RTT and sends `ConnectionHealth { rtt_ms, quality }`
4. Clients can display quality indicator and adjust behavior

### Message Coalescing

The `Batch` message enables efficient update delivery:
- Server buffers `PaneRowsUpdate` messages within an 8ms window
- Updates for the same pane are merged (rows concatenated)
- Buffer flushes when window expires or size exceeds 64KB
- Reduces WebSocket frame overhead by ~30%

## [1.0.0] - 2026-01-15

### Added
- Initial protocol release
- WebSocket-based communication between Factory Server and clients
- MessagePack serialization for all messages
- Client types: TUI, Desktop, Web
- Session management with connect/disconnect
- Live mode with terminal multiplexing
- Playback mode for session recordings
- Director panel updates for supervisor UI
