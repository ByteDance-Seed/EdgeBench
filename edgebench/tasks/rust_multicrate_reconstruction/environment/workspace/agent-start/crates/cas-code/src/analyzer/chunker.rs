//! Code chunking for embedding generation.
//!
//! This module breaks code symbols into chunks optimized for
//! semantic search via embeddings.

use crate::types::{CodeSymbol, SymbolKind};

/// Type of chunk representation.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ChunkType {
    /// Full source code of the symbol
    FullSource,
    /// Just the signature (for functions/methods)
    Signature,
    /// Documentation + signature
    DocSignature,
    /// Summary: name + kind + doc (first line)
    Summary,
}

/// Configuration for chunking behavior.
#[derive(Debug, Clone)]
pub struct ChunkConfig {
    /// Maximum chunk size in characters
    pub max_chunk_size: usize,
    /// Whether to include documentation
    pub include_docs: bool,
    /// Whether to include full source for small symbols
    pub include_source: bool,
    /// Chunk types to generate per symbol
    pub chunk_types: Vec<ChunkType>,
}

impl Default for ChunkConfig {
    fn default() -> Self { todo!() }
}

/// A chunk of code ready for embedding.
#[derive(Debug, Clone)]
pub struct CodeChunk {
    /// The symbol this chunk belongs to
    pub symbol_id: String,
    /// Type of this chunk
    pub chunk_type: ChunkType,
    /// Text content to embed
    pub content: String,
    /// Relative importance (0.0 - 1.0)
    pub importance: f32,
}

/// Generates embeddable chunks from code symbols.
pub struct CodeChunker {
    config: ChunkConfig,
}

impl CodeChunker {
    /// Create a new chunker with default config.
    pub fn new() -> Self { todo!() }

    /// Create a new chunker with custom config.
    pub fn with_config(config: ChunkConfig) -> Self { todo!() }

    /// Generate chunks for a single symbol.
    pub fn chunk_symbol(&self, symbol: &CodeSymbol) -> Vec<CodeChunk> { todo!() }

    /// Generate chunks for multiple symbols.
    pub fn chunk_symbols(&self, symbols: &[CodeSymbol]) -> Vec<CodeChunk> { todo!() }

    /// Create a specific chunk type for a symbol.
    fn create_chunk(&self, symbol: &CodeSymbol, chunk_type: ChunkType) -> Option<CodeChunk> { todo!() }

    /// Calculate importance score for a chunk.
    fn calculate_importance(&self, symbol: &CodeSymbol, chunk_type: ChunkType) -> f32 { todo!() }
}

impl Default for CodeChunker {
    fn default() -> Self { todo!() }
}

#[cfg(test)]
mod tests {
    use crate::analyzer::chunker::*;
    use crate::types::Language;
    use chrono::Utc;

    fn make_symbol(
        name: &str,
        kind: SymbolKind,
        doc: Option<&str>,
        sig: Option<&str>,
    ) -> CodeSymbol {
        let now = Utc::now();
        CodeSymbol {
            id: format!("sym-{name}"),
            qualified_name: format!("test::{name}"),
            name: name.to_string(),
            kind,
            language: Language::Rust,
            file_path: "test.rs".to_string(),
            file_id: "file-test".to_string(),
            line_start: 1,
            line_end: 10,
            source: format!("fn {name}() {{}}"),
            documentation: doc.map(String::from),
            signature: sig.map(String::from),
            parent_id: None,
            repository: "test-repo".to_string(),
            commit_hash: None,
            created: now,
            updated: now,
            content_hash: "abc123".to_string(),
            scope: "project".to_string(),
        }
    }

    #[test]
    fn test_chunk_function() {
        let chunker = CodeChunker::new();
        let symbol = make_symbol(
            "hello",
            SymbolKind::Function,
            Some("Says hello"),
            Some("fn hello(name: &str) -> String"),
        );

        let chunks = chunker.chunk_symbol(&symbol);

        // Default config: FullSource only (1 chunk per symbol for performance)
        assert_eq!(chunks.len(), 1);
        assert_eq!(chunks[0].chunk_type, ChunkType::FullSource);
    }

    #[test]
    fn test_chunk_function_dual_mode() {
        // Test the old dual-chunk mode explicitly
        let config = ChunkConfig {
            chunk_types: vec![ChunkType::DocSignature, ChunkType::FullSource],
            ..Default::default()
        };
        let chunker = CodeChunker::with_config(config);
        let symbol = make_symbol(
            "hello",
            SymbolKind::Function,
            Some("Says hello"),
            Some("fn hello(name: &str) -> String"),
        );

        let chunks = chunker.chunk_symbol(&symbol);

        // Should have DocSignature and FullSource
        assert_eq!(chunks.len(), 2);

        let doc_sig = chunks
            .iter()
            .find(|c| c.chunk_type == ChunkType::DocSignature)
            .unwrap();
        assert!(doc_sig.content.contains("Says hello"));
        assert!(doc_sig.content.contains("fn hello"));
    }



    #[test]
    fn test_custom_config() {
        let config = ChunkConfig {
            max_chunk_size: 100,
            include_docs: true,
            include_source: false,
            chunk_types: vec![ChunkType::Summary],
        };

        let chunker = CodeChunker::with_config(config);
        let symbol = make_symbol("test", SymbolKind::Function, Some("Test function"), None);

        let chunks = chunker.chunk_symbol(&symbol);
        assert_eq!(chunks.len(), 1);
        assert_eq!(chunks[0].chunk_type, ChunkType::Summary);
        assert!(chunks[0].content.contains("test::test"));
    }

    #[test]
    fn test_truncate_large_source() {
        let config = ChunkConfig {
            max_chunk_size: 20,
            include_docs: false,
            include_source: true,
            chunk_types: vec![ChunkType::FullSource],
        };

        let chunker = CodeChunker::with_config(config);
        let mut symbol = make_symbol("big", SymbolKind::Function, None, None);
        symbol.source = "fn big() { let x = 1; let y = 2; let z = 3; }".to_string();

        let chunks = chunker.chunk_symbol(&symbol);
        assert_eq!(chunks.len(), 1);
        assert!(chunks[0].content.ends_with("..."));
        assert!(chunks[0].content.len() <= 24); // 20 + "..."
    }
}
