# cas-recording

Binary recording format and utilities for CAS Factory terminal recordings.

## File Format

Recording files (`.rec`) capture PTY output with precise timestamps for exact replay.

### Structure

```
+------------------+
| RecordingHeader  |  Magic bytes + metadata
+------------------+
| Event 0          |  Variable-size events
| Event 1          |
| ...              |
| Event N          |
+------------------+
| KeyframeIndex    |  Index for fast seeking
+------------------+
| index_offset: u64|  Offset to index (last 8 bytes)
+------------------+
```

### Header

| Field | Type | Description |
|-------|------|-------------|
| magic | `[u8; 8]` | `CASREC\x00\x01` |
| version | `u16` | Format version (currently 1) |
| cols | `u16` | Initial terminal width |
| rows | `u16` | Initial terminal height |
| created_at | `DateTime<Utc>` | Recording start time |
| agent_name | `String` | Agent identifier |
| session_id | `String` | Factory session ID |

### Events

All events carry a `timestamp_ms` (milliseconds since recording start).

#### Output
Raw PTY bytes. Captures all terminal output including ANSI sequences.

```rust
Output { timestamp_ms: u64, data: Vec<u8> }
```

#### Resize
Terminal dimension change.

```rust
Resize { timestamp_ms: u64, cols: u16, rows: u16 }
```

#### Keyframe
Snapshot marker for fast seeking.

```rust
Keyframe { timestamp_ms: u64, snapshot_offset: u64, snapshot_size: u32 }
```

### Keyframe Index

Located at end of file (offset in last 8 bytes). Enables O(log n) seeking.

| Field | Type | Description |
|-------|------|-------------|
| entries | `Vec<KeyframeEntry>` | Sorted by timestamp |
| total_duration_ms | `u64` | Recording length |
| total_events | `u64` | Event count |

Each `KeyframeEntry`:
- `timestamp_ms` - When the keyframe was taken
- `event_offset` - File offset to Keyframe event
- `snapshot_offset` - File offset to snapshot data

## Seeking Algorithm

To seek to timestamp T:

1. Read `index_offset` from last 8 bytes
2. Load `KeyframeIndex` at that offset
3. Binary search for largest timestamp ≤ T
4. Load snapshot at keyframe's offset
5. Replay events from keyframe to T

Target: <100ms seek time.

## Serialization

All structures use [bincode](https://github.com/bincode-org/bincode) for serialization:
- Compact binary encoding
- Fast serialization/deserialization
- Rust-native with serde support

## RecordingWriter

Async writer for recording terminal sessions with automatic compression.

### Usage

```rust
use cas_recording::{RecordingWriter, WriterConfig};

// Create writer with default config (~/.cas/recordings)
let config = WriterConfig::default();
let writer = RecordingWriter::new(80, 24, "agent-1", "session-abc", "worker", config).await?;

// Write PTY output (non-blocking, sent to background task)
writer.write_output(b"Hello, World!\n").await?;

// Write resize event
writer.write_resize(120, 40).await?;

// Generate keyframes periodically
if writer.should_generate_keyframe() {
    let snapshot = serialize_terminal_state();
    writer.write_keyframe(snapshot).await?;
}

// Close and finalize
let stats = writer.close().await?;
println!("Recorded {} events, {} bytes", stats.total_events, stats.file_size);
```

### Configuration

| Field | Default | Description |
|-------|---------|-------------|
| `recordings_dir` | `~/.cas/recordings` | Base directory |
| `keyframe_interval_ms` | `30000` | Keyframe interval (30s) |
| `compression_level` | `3` | zstd level (1-22) |
| `buffer_size` | `1024` | Channel buffer size |

### File Path

Recordings are written to: `{recordings_dir}/{session_id}/{agent_name}.rec`

### Features

- **Async I/O**: Background task handles writes, never blocks terminal
- **zstd compression**: Streaming compression for compact files
- **Auto keyframes**: `should_generate_keyframe()` checks interval
- **Statistics**: Returns event count, duration, file size on close

## RecordingReader

Fast reader for playback with keyframe-based seeking.

### Usage

```rust
use cas_recording::RecordingReader;

// Open recording (decompresses to memory)
let reader = RecordingReader::open("session/agent.rec")?;

// Get metadata
println!("Duration: {}ms", reader.duration_ms());
println!("Events: {}", reader.total_events());
println!("Keyframes: {}", reader.keyframe_count());

// Seek to 45 seconds (finds nearest keyframe via binary search)
let position = reader.seek_to(45_000)?;

// Read events from that position
for event in reader.read_events_from(position) {
    match event? {
        RecordingEvent::Output { timestamp_ms, data } => { /* ... */ }
        RecordingEvent::Resize { timestamp_ms, cols, rows } => { /* ... */ }
        RecordingEvent::Keyframe { timestamp_ms, .. } => { /* ... */ }
    }
}

// Read snapshot data for playback state restoration
if let Some(keyframe) = reader.keyframe_index().entries.first() {
    let snapshot = reader.read_snapshot(keyframe)?;
    // Deserialize and restore terminal state...
}
```

### Memory-Mapped I/O

For large recordings (>100MB decompressed), use mmap:

```rust
let reader = RecordingReader::open_mmap("large_recording.rec")?;
```

### Seeking Performance

- Binary search on keyframe index: O(log k)
- 2-hour recording with 30s keyframes (240 keyframes): ~8 comparisons
- Target: <100ms to any point

### Methods

| Method | Description |
|--------|-------------|
| `open(path)` | Open and decompress to memory |
| `open_mmap(path)` | Open with mmap (for large files) |
| `seek_to(ms)` | Seek to timestamp, returns position |
| `read_events_from(pos)` | Iterator from position |
| `read_all_events()` | Iterator from start |
| `read_snapshot(keyframe)` | Get snapshot bytes |
| `header()` | Recording metadata |
| `duration_ms()` | Total duration |
| `total_events()` | Event count |

## Storage Estimates

- Raw PTY output: ~1-5 KB/s typical
- Keyframes: ~50-200 KB each (compressed terminal state)
- Total: ~10-30 MB per agent per hour (with zstd compression)
