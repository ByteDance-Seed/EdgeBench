//! Code analysis and chunking for embeddings.
//!
//! This module provides utilities for breaking parsed code into
//! chunks suitable for embedding and semantic search.

mod chunker;

pub use chunker::{ChunkConfig, ChunkType, CodeChunk, CodeChunker};
