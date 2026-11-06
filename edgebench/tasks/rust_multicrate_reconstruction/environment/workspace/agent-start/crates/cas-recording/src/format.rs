//! Binary recording file format for CAS Factory terminal recordings.
//!
//! # File Format Overview
//!
//! A `.rec` file consists of:
//! 1. **Header** - Magic bytes, version, dimensions, creation time
//! 2. **Event Stream** - Sequence of timestamped events (output, resize, keyframe)
//! 3. **Keyframe Index** - Located at end of file for fast seeking
//!
//! ## File Structure
//!
//! ```text
//! +------------------+
//! | RecordingHeader  |  Fixed size header with magic bytes
//! +------------------+
//! | Event 0          |  Variable size events
//! | Event 1          |
//! | ...              |
//! | Event N          |
//! +------------------+
//! | KeyframeIndex    |  Index for fast seeking (at file end)
//! +------------------+
//! | index_offset: u64|  Offset to KeyframeIndex from file start
//! +------------------+
//! ```
//!
//! ## Seeking Strategy
//!
//! To seek to timestamp T:
//! 1. Read `index_offset` from last 8 bytes of file
//! 2. Read KeyframeIndex at that offset
//! 3. Find keyframe with largest timestamp <= T
//! 4. Seek to keyframe's file offset
//! 5. Replay events from keyframe to T

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

/// Magic bytes identifying a CAS recording file: "CASREC\x00\x01"
pub const MAGIC: [u8; 8] = [b'C', b'A', b'S', b'R', b'E', b'C', 0x00, 0x01];

/// Current format version
pub const FORMAT_VERSION: u16 = 1;

/// Default keyframe interval in milliseconds (30 seconds)
pub const DEFAULT_KEYFRAME_INTERVAL_MS: u64 = 30_000;

/// Recording file header containing metadata about the recording.
///
/// This is written at the start of every `.rec` file and contains
/// information needed to initialize playback.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub struct RecordingHeader {
    /// Magic bytes for file type identification
    pub magic: [u8; 8],
    /// Format version for backwards compatibility
    pub version: u16,
    /// Terminal width in columns at recording start
    pub cols: u16,
    /// Terminal height in rows at recording start
    pub rows: u16,
    /// When the recording was started
    pub created_at: DateTime<Utc>,
    /// Agent name (e.g., "swift-fox", "supervisor")
    pub agent_name: String,
    /// Session ID this recording belongs to
    pub session_id: String,
    /// Agent role: "supervisor", "worker", or "primary"
    #[serde(default)]
    pub agent_role: String,
}

impl RecordingHeader {
    /// Create a new recording header with default magic bytes and version.
    pub fn new(
        cols: u16,
        rows: u16,
        agent_name: String,
        session_id: String,
        agent_role: String,
    ) -> Self { todo!() }

    /// Validate the header magic bytes and version.
    pub fn validate(&self) -> Result<(), FormatError> { todo!() }
}

/// Events that can be recorded in the terminal stream.
///
/// Each event carries a timestamp relative to recording start (in milliseconds)
/// to enable precise replay timing.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq)]
pub enum RecordingEvent {
    /// Raw PTY output bytes with timestamp.
    ///
    /// This is the primary event type - captures all terminal output
    /// including ANSI escape sequences, text, and control characters.
    Output {
        /// Milliseconds since recording start
        timestamp_ms: u64,
        /// Raw bytes from PTY (may contain partial UTF-8 sequences)
        data: Vec<u8>,
    },

    /// Terminal resize event.
    ///
    /// Recorded when the terminal dimensions change during recording.
    /// Playback must update the virtual terminal size accordingly.
    Resize {
        /// Milliseconds since recording start
        timestamp_ms: u64,
        /// New terminal width in columns
        cols: u16,
        /// New terminal height in rows
        rows: u16,
    },

    /// Keyframe marker with snapshot reference.
    ///
    /// Keyframes enable fast seeking by providing periodic snapshots
    /// of complete terminal state. The `snapshot_offset` points to
    /// a serialized terminal state that can be loaded directly.
    Keyframe {
        /// Milliseconds since recording start
        timestamp_ms: u64,
        /// File offset where the snapshot data is stored
        snapshot_offset: u64,
        /// Size of the snapshot data in bytes
        snapshot_size: u32,
    },
}

impl RecordingEvent {
    /// Get the timestamp of this event in milliseconds.
    pub fn timestamp_ms(&self) -> u64 { todo!() }

    /// Create an output event.
    pub fn output(timestamp_ms: u64, data: Vec<u8>) -> Self { todo!() }

    /// Create a resize event.
    pub fn resize(timestamp_ms: u64, cols: u16, rows: u16) -> Self { todo!() }

    /// Create a keyframe event.
    pub fn keyframe(timestamp_ms: u64, snapshot_offset: u64, snapshot_size: u32) -> Self { todo!() }
}

/// Entry in the keyframe index for fast seeking.
///
/// Each entry points to a keyframe event in the recording file.
#[derive(Debug, Clone, Copy, Serialize, Deserialize, PartialEq, Eq)]
pub struct KeyframeEntry {
    /// Timestamp of this keyframe in milliseconds
    pub timestamp_ms: u64,
    /// File offset to the keyframe event
    pub event_offset: u64,
    /// File offset to the snapshot data
    pub snapshot_offset: u64,
}

/// Index of all keyframes in a recording for fast seeking.
///
/// The index is written at the end of the recording file and enables
/// O(log n) seeking to any point in the recording.
#[derive(Debug, Clone, Serialize, Deserialize, PartialEq, Eq, Default)]
pub struct KeyframeIndex {
    /// All keyframe entries, sorted by timestamp
    pub entries: Vec<KeyframeEntry>,
    /// Total duration of the recording in milliseconds
    pub total_duration_ms: u64,
    /// Total number of events in the recording
    pub total_events: u64,
}

impl KeyframeIndex {
    /// Create a new empty keyframe index.
    pub fn new() -> Self { todo!() }

    /// Add a keyframe entry to the index.
    pub fn add_keyframe(&mut self, entry: KeyframeEntry) { todo!() }

    /// Find the keyframe entry for seeking to the given timestamp.
    ///
    /// Returns the keyframe with the largest timestamp <= target,
    /// or None if the recording has no keyframes.
    pub fn find_keyframe(&self, target_timestamp_ms: u64) -> Option<&KeyframeEntry> { todo!() }

    /// Get the number of keyframes in the index.
    pub fn len(&self) -> usize { todo!() }

    /// Check if the index is empty.
    pub fn is_empty(&self) -> bool { todo!() }
}

/// Errors that can occur when reading or writing recording files.
#[derive(Debug, thiserror::Error)]
pub enum FormatError {
    #[error("Invalid magic bytes - not a CAS recording file")]
    InvalidMagic,

    #[error("Unsupported format version: {0}")]
    UnsupportedVersion(u16),

    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),

    #[error("Serialization error: {0}")]
    Bincode(#[from] bincode::Error),

    #[error("Unexpected end of file")]
    UnexpectedEof,

    #[error("Corrupted keyframe index")]
    CorruptedIndex,
}

#[cfg(test)]
mod tests {
    use crate::format::*;

    #[test]
    fn test_header_validation() {
        let header = RecordingHeader::new(
            80,
            24,
            "test-agent".to_string(),
            "session-123".to_string(),
            "worker".to_string(),
        );
        assert!(header.validate().is_ok());
    }

    #[test]
    fn test_header_invalid_magic() {
        let mut header = RecordingHeader::new(
            80,
            24,
            "test-agent".to_string(),
            "session-123".to_string(),
            "worker".to_string(),
        );
        header.magic = [0; 8];
        assert!(matches!(header.validate(), Err(FormatError::InvalidMagic)));
    }


    #[test]
    fn test_keyframe_index_find() {
        let mut index = KeyframeIndex::new();
        index.add_keyframe(KeyframeEntry {
            timestamp_ms: 0,
            event_offset: 100,
            snapshot_offset: 200,
        });
        index.add_keyframe(KeyframeEntry {
            timestamp_ms: 30_000,
            event_offset: 5000,
            snapshot_offset: 6000,
        });
        index.add_keyframe(KeyframeEntry {
            timestamp_ms: 60_000,
            event_offset: 10000,
            snapshot_offset: 12000,
        });

        // Before first keyframe - returns first
        let kf = index.find_keyframe(0).unwrap();
        assert_eq!(kf.timestamp_ms, 0);

        // Exactly at keyframe
        let kf = index.find_keyframe(30_000).unwrap();
        assert_eq!(kf.timestamp_ms, 30_000);

        // Between keyframes - returns earlier one
        let kf = index.find_keyframe(45_000).unwrap();
        assert_eq!(kf.timestamp_ms, 30_000);

        // After last keyframe
        let kf = index.find_keyframe(90_000).unwrap();
        assert_eq!(kf.timestamp_ms, 60_000);
    }

    #[test]
    fn test_keyframe_index_empty() {
        let index = KeyframeIndex::new();
        assert!(index.find_keyframe(1000).is_none());
        assert!(index.is_empty());
    }

    #[test]
    fn test_header_serialization() {
        let header = RecordingHeader::new(
            80,
            24,
            "test-agent".to_string(),
            "session-123".to_string(),
            "supervisor".to_string(),
        );

        let encoded = bincode::serialize(&header).unwrap();
        let decoded: RecordingHeader = bincode::deserialize(&encoded).unwrap();

        assert_eq!(header, decoded);
    }

    #[test]
    fn test_event_serialization() {
        let events = vec![
            RecordingEvent::output(100, vec![0x1b, b'[', b'H']),
            RecordingEvent::resize(200, 120, 40),
            RecordingEvent::keyframe(300, 1024, 512),
        ];

        for event in events {
            let encoded = bincode::serialize(&event).unwrap();
            let decoded: RecordingEvent = bincode::deserialize(&encoded).unwrap();
            assert_eq!(event, decoded);
        }
    }
}
