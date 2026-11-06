//! Code analysis and indexing for CAS (Coding Agent System).
//!
//! This crate provides code parsing, symbol extraction, and indexing
//! capabilities for semantic code search across multiple languages.
//!
//! # Supported Languages
//!
//! - Rust (via tree-sitter-rust)
//! - TypeScript/JavaScript (planned)
//! - Python (planned)
//! - Go (planned)
//!
//! # Example
//!
//! ```rust,ignore
//! use cas_code::parser::MultiLanguageParser;
//! use std::path::Path;
//!
//! let mut parser = MultiLanguageParser::new()?;
//! let result = parser.parse_file(
//!     Path::new("src/main.rs"),
//!     source_code,
//!     "my-repo"
//! )?;
//!
//! for symbol in result.symbols {
//!     println!("{}: {} ({})",
//!         symbol.kind,
//!         symbol.qualified_name,
//!         symbol.line_start
//!     );
//! }
//! ```

pub mod analyzer;
pub mod error;
pub mod parser;
pub mod types;

// Re-export main types
pub use analyzer::{ChunkConfig, ChunkType, CodeChunk, CodeChunker};
pub use error::{CodeError, Result};
pub use parser::{LanguageParser, MultiLanguageParser, RustParser};
pub use types::{
    CodeFile, CodeMemoryLink, CodeMemoryLinkType, CodeRelationType, CodeRelationship, CodeSymbol,
    Import, Language, ParseResult, SymbolKind,
};
