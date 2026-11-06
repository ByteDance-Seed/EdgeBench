//! Terminal recording format and utilities for CAS Factory.
//!
//! This crate provides the binary file format for recording and playing back
//! terminal sessions from CAS Factory agents.
//!
//! # Overview
//!
//! The recording system captures raw PTY output with precise timestamps,
//! enabling exact replay of terminal sessions. Key features:
//!
//! - **Efficient storage**: Raw bytes with timestamps, not cell snapshots
//! - **Fast seeking**: Keyframe index enables <100ms seeks via binary search
//! - **Streaming writes**: Events appended without blocking terminal
//! - **Compression**: zstd streaming compression for compact storage
//! - **Memory-mapped I/O**: Optional mmap support for large recordings
//!
//! # Recording Example
//!
//! ```ignore
//! use cas_recording::{RecordingWriter, WriterConfig};
//!
//! // Create writer with default config
//! let config = WriterConfig::default();
//! let writer = RecordingWriter::new(80, 24, "agent-1", "session-abc", "worker", config).await?;
//!
//! // Write terminal output
//! writer.write_output(b"Hello, World!\n").await?;
//!
//! // Check if keyframe needed (every 30s by default)
//! if writer.should_generate_keyframe() {
//!     let snapshot = get_terminal_snapshot(); // Your snapshot logic
//!     writer.write_keyframe(snapshot).await?;
//! }
//!
//! // Close and get stats
//! let stats = writer.close().await?;
//! println!("Recorded {} events", stats.total_events);
//! ```
//!
//! # Playback Example
//!
//! ```ignore
//! use cas_recording::RecordingReader;
//!
//! // Open recording
//! let reader = RecordingReader::open("session/agent.rec")?;
//!
//! // Get metadata
//! println!("Duration: {}ms, Events: {}", reader.duration_ms(), reader.total_events());
//!
//! // Seek to 45 seconds (finds nearest keyframe)
//! let position = reader.seek_to(45_000)?;
//!
//! // Read events from that position
//! for event in reader.read_events_from(position) {
//!     let event = event?;
//!     // Process event...
//! }
//! ```

pub mod export;
pub mod format;
pub mod reader;
pub mod writer;

pub use format::{
    DEFAULT_KEYFRAME_INTERVAL_MS, FORMAT_VERSION, FormatError, KeyframeEntry, KeyframeIndex, MAGIC,
    RecordingEvent, RecordingHeader,
};

pub use reader::{EventIterator, ReadPosition, RecordingReader};
pub use writer::{RecordingWriter, WriterConfig, WriterStats};

pub use export::{
    ARCHIVE_MAGIC, ARCHIVE_VERSION, AgentManifest, ArchiveManifest, ExportConfig, ExportError,
    ExportResult, ExportStats, ManifestExtra, RecordedEvent, export_session, import_archive,
    read_manifest,
};
