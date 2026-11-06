//! Code storage operations for indexed source code.
//!
//! This module provides the `CodeStore` trait for storing and querying
//! indexed code files, symbols, relationships, and memory links.

use crate::error::Result;
use cas_code::{
    CodeFile, CodeMemoryLink, CodeMemoryLinkType, CodeRelationship, CodeSymbol, Language,
    SymbolKind,
};

/// Trait for code storage operations.
///
/// Implementations must be thread-safe (Send + Sync).
pub trait CodeStore: Send + Sync {
    /// Initialize the store (create tables, indexes, etc.)
    fn init(&self) -> Result<()>;

    // ========== File Operations ==========

    /// Generate a new unique file ID (random)
    fn generate_file_id(&self) -> Result<String>;

    /// Generate a deterministic file ID based on repository and path.
    /// Re-indexing the same file produces the same ID.
    fn generate_file_id_for(&self, repository: &str, path: &str) -> String;

    /// Add or update a code file
    fn add_file(&self, file: &CodeFile) -> Result<()>;

    /// Get a file by ID
    fn get_file(&self, id: &str) -> Result<CodeFile>;

    /// Get a file by repository and path
    fn get_file_by_path(&self, repository: &str, path: &str) -> Result<Option<CodeFile>>;

    /// List files in a repository
    fn list_files(&self, repository: &str, language: Option<Language>) -> Result<Vec<CodeFile>>;

    /// Delete a file and all its symbols
    fn delete_file(&self, id: &str) -> Result<()>;

    // ========== Symbol Operations ==========

    /// Generate a new unique symbol ID (random)
    fn generate_symbol_id(&self) -> Result<String>;

    /// Generate a deterministic symbol ID based on its identity.
    /// Re-indexing the same symbol produces the same ID.
    fn generate_symbol_id_for(
        &self,
        qualified_name: &str,
        file_path: &str,
        repository: &str,
    ) -> String;

    /// Add or update a code symbol
    fn add_symbol(&self, symbol: &CodeSymbol) -> Result<()>;

    /// Get a symbol by ID
    fn get_symbol(&self, id: &str) -> Result<CodeSymbol>;

    /// Get symbols by qualified name (may return multiple for overloads)
    fn get_symbols_by_name(&self, qualified_name: &str) -> Result<Vec<CodeSymbol>>;

    /// Get all symbols in a file
    fn get_symbols_in_file(&self, file_id: &str) -> Result<Vec<CodeSymbol>>;

    /// Search symbols by name pattern (supports % wildcards)
    fn search_symbols(
        &self,
        name_pattern: &str,
        kind: Option<SymbolKind>,
        language: Option<Language>,
        limit: usize,
    ) -> Result<Vec<CodeSymbol>>;

    /// Search symbols with pagination support for streaming large result sets
    fn search_symbols_paginated(
        &self,
        name_pattern: &str,
        kind: Option<SymbolKind>,
        language: Option<Language>,
        limit: usize,
        offset: usize,
    ) -> Result<Vec<CodeSymbol>>;

    /// Delete a symbol
    fn delete_symbol(&self, id: &str) -> Result<()>;

    /// Delete all symbols in a file
    fn delete_symbols_in_file(&self, file_id: &str) -> Result<()>;

    // ========== Relationship Operations ==========

    /// Generate a new unique relationship ID
    fn generate_relationship_id(&self) -> Result<String>;

    /// Add a relationship between symbols
    fn add_relationship(&self, rel: &CodeRelationship) -> Result<()>;

    /// Get symbols that call/use this symbol (reverse references)
    fn get_callers(&self, symbol_id: &str) -> Result<Vec<CodeSymbol>>;

    /// Get symbols that this symbol calls/uses
    fn get_callees(&self, symbol_id: &str) -> Result<Vec<CodeSymbol>>;

    /// Get all relationships for a symbol (as source)
    fn get_relationships_from(&self, symbol_id: &str) -> Result<Vec<CodeRelationship>>;

    /// Get all relationships to a symbol (as target)
    fn get_relationships_to(&self, symbol_id: &str) -> Result<Vec<CodeRelationship>>;

    /// Delete all relationships involving a symbol
    fn delete_relationships_for_symbol(&self, symbol_id: &str) -> Result<()>;

    // ========== Memory Link Operations ==========

    /// Link a code symbol to a CAS memory entry
    fn link_to_memory(&self, link: &CodeMemoryLink) -> Result<()>;

    /// Get linked memory entry IDs for a code symbol
    fn get_linked_memories(&self, code_id: &str) -> Result<Vec<String>>;

    /// Get linked code symbol IDs for a memory entry
    fn get_linked_code(&self, entry_id: &str) -> Result<Vec<String>>;

    /// Get all links for a code symbol
    fn get_memory_links(&self, code_id: &str) -> Result<Vec<CodeMemoryLink>>;

    /// Delete a specific link
    fn delete_memory_link(
        &self,
        code_id: &str,
        entry_id: &str,
        link_type: CodeMemoryLinkType,
    ) -> Result<()>;

    /// Delete all links for a code symbol
    fn delete_memory_links_for_code(&self, code_id: &str) -> Result<()>;

    // ========== Bulk Operations ==========

    /// Add multiple symbols in a batch (more efficient than individual adds)
    fn add_symbols_batch(&self, symbols: &[CodeSymbol]) -> Result<()>;

    /// Add multiple relationships in a batch
    fn add_relationships_batch(&self, relationships: &[CodeRelationship]) -> Result<()>;

    /// Get multiple symbols by ID in a single query (avoids N+1)
    ///
    /// Returns symbols in arbitrary order. Missing IDs are silently ignored.
    fn get_symbols_batch(&self, ids: &[&str]) -> Result<Vec<CodeSymbol>>;

    // ========== Stats ==========

    /// Get total number of indexed files
    fn count_files(&self) -> Result<usize>;

    /// Get total number of indexed symbols
    fn count_symbols(&self) -> Result<usize>;

    /// Get file counts grouped by language
    fn count_files_by_language(&self) -> Result<std::collections::HashMap<Language, usize>>;

    /// Close the store
    fn close(&self) -> Result<()>;
}
