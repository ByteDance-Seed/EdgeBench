//! Core types for code analysis and indexing.

use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use std::fmt;
use std::str::FromStr;

use crate::error::CodeError;

/// Programming language identifier.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
#[serde(rename_all = "lowercase")]
pub enum Language {
    Rust,
    TypeScript,
    JavaScript,
    Python,
    Go,
    Elixir,
    #[default]
    Unknown,
}

impl Language {
    /// Get file extensions for this language.
    pub fn extensions(&self) -> &[&str] { todo!() }

    /// Detect language from file extension.
    pub fn from_extension(ext: &str) -> Self { todo!() }
}

impl fmt::Display for Language {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for Language {
    type Err = CodeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Type of code symbol (function, class, struct, etc.).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum SymbolKind {
    #[default]
    Function,
    Method,
    Class,
    Struct,
    Enum,
    Trait,
    Interface,
    Module,
    Constant,
    Variable,
    Type,
    Import,
    Impl,
    Macro,
}

impl fmt::Display for SymbolKind {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl SymbolKind {
    /// Returns true if this symbol kind is valuable enough to generate embeddings for.
    /// Low-value symbols (imports, variables, constants) are still indexed in BM25
    /// for keyword search, but skip the expensive embedding step.
    pub fn should_embed(&self) -> bool { todo!() }
}

impl FromStr for SymbolKind {
    type Err = CodeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Relationship type between code symbols.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum CodeRelationType {
    #[default]
    Imports,
    Calls,
    Extends,
    Implements,
    Contains,
    References,
    Tests,
}

impl fmt::Display for CodeRelationType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for CodeRelationType {
    type Err = CodeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// Link type between code and CAS memories.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize, Default)]
#[serde(rename_all = "snake_case")]
pub enum CodeMemoryLinkType {
    #[default]
    Documents,
    BugReport,
    DesignDecision,
    Learning,
    Reference,
}

impl fmt::Display for CodeMemoryLinkType {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result { todo!() }
}

impl FromStr for CodeMemoryLinkType {
    type Err = CodeError;

    fn from_str(s: &str) -> Result<Self, Self::Err> { todo!() }
}

/// A tracked source code file.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeFile {
    /// Unique identifier (e.g., "file-a1b2c3d4")
    pub id: String,

    /// Path relative to repository root
    pub path: String,

    /// Repository/project identifier
    pub repository: String,

    /// Programming language
    pub language: Language,

    /// File size in bytes
    pub size: usize,

    /// Number of lines
    pub line_count: usize,

    /// Git commit hash when indexed
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub commit_hash: Option<String>,

    /// SHA-256 hash of content for change detection
    pub content_hash: String,

    /// When first indexed
    pub created: DateTime<Utc>,

    /// When last updated
    pub updated: DateTime<Utc>,

    /// Scope (global or project)
    #[serde(default = "default_scope")]
    pub scope: String,
}

fn default_scope() -> String { todo!() }

impl Default for CodeFile {
    fn default() -> Self { todo!() }
}

/// A code symbol (function, class, struct, etc.) extracted from source.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeSymbol {
    /// Unique identifier (e.g., "sym-a1b2c3d4")
    pub id: String,

    /// Fully qualified name (e.g., "cas_cli::search::hybrid::HybridSearch::search")
    pub qualified_name: String,

    /// Short name (e.g., "search")
    pub name: String,

    /// Type of symbol
    pub kind: SymbolKind,

    /// Programming language
    pub language: Language,

    /// File path relative to repository root
    pub file_path: String,

    /// File ID (foreign key to code_files)
    pub file_id: String,

    /// Line range (start, end) - 1-indexed
    pub line_start: usize,
    pub line_end: usize,

    /// The actual source code
    pub source: String,

    /// Documentation/docstring if present
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub documentation: Option<String>,

    /// Signature (for functions/methods)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub signature: Option<String>,

    /// Parent symbol ID (for methods in impls, etc.)
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub parent_id: Option<String>,

    /// Repository/project identifier
    pub repository: String,

    /// Git commit hash when indexed
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub commit_hash: Option<String>,

    /// When first indexed
    pub created: DateTime<Utc>,

    /// When last updated
    pub updated: DateTime<Utc>,

    /// SHA-256 hash of source for change detection
    pub content_hash: String,

    /// Scope (global or project)
    #[serde(default = "default_scope")]
    pub scope: String,
}

impl Default for CodeSymbol {
    fn default() -> Self { todo!() }
}

/// A relationship between code symbols (imports, calls, etc.).
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeRelationship {
    /// Unique identifier
    pub id: String,

    /// Source symbol ID
    pub source_id: String,

    /// Target symbol ID
    pub target_id: String,

    /// Type of relationship
    pub relation_type: CodeRelationType,

    /// Relationship weight/strength (default 1.0)
    #[serde(default = "default_weight")]
    pub weight: f32,

    /// When created
    pub created: DateTime<Utc>,
}

fn default_weight() -> f32 { todo!() }

impl Default for CodeRelationship {
    fn default() -> Self { todo!() }
}

/// A link between a code symbol and a CAS memory entry.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct CodeMemoryLink {
    /// Code symbol or file ID
    pub code_id: String,

    /// CAS entry/memory ID
    pub entry_id: String,

    /// Type of link
    pub link_type: CodeMemoryLinkType,

    /// Confidence score (0.0 - 1.0)
    #[serde(default = "default_confidence")]
    pub confidence: f32,

    /// When the link was created
    pub created: DateTime<Utc>,
}

fn default_confidence() -> f32 { todo!() }

impl Default for CodeMemoryLink {
    fn default() -> Self { todo!() }
}

/// Import statement extracted from source code.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Import {
    /// Module/package path being imported
    pub module_path: String,

    /// Specific items imported (empty for module-level import)
    pub items: Vec<String>,

    /// Line number where import appears
    pub line: usize,

    /// Whether this is a re-export (pub use in Rust)
    #[serde(default)]
    pub is_reexport: bool,
}

/// Result of parsing a source file.
#[derive(Debug, Clone, Default)]
pub struct ParseResult {
    /// Extracted symbols
    pub symbols: Vec<CodeSymbol>,

    /// Extracted imports
    pub imports: Vec<Import>,

    /// Parse errors (non-fatal)
    pub errors: Vec<String>,
}

#[cfg(test)]
mod tests {
    use crate::types::*;

    #[test]
    fn test_language_from_extension() {
        assert_eq!(Language::from_extension("rs"), Language::Rust);
        assert_eq!(Language::from_extension("ts"), Language::TypeScript);
        assert_eq!(Language::from_extension("tsx"), Language::TypeScript);
        assert_eq!(Language::from_extension("py"), Language::Python);
        assert_eq!(Language::from_extension("go"), Language::Go);
        assert_eq!(Language::from_extension("txt"), Language::Unknown);
    }

    #[test]
    fn test_language_roundtrip() {
        for lang in [
            Language::Rust,
            Language::TypeScript,
            Language::Python,
            Language::Go,
        ] {
            let s = lang.to_string();
            let parsed: Language = s.parse().unwrap();
            assert_eq!(lang, parsed);
        }
    }

    #[test]
    fn test_symbol_kind_roundtrip() {
        for kind in [
            SymbolKind::Function,
            SymbolKind::Method,
            SymbolKind::Class,
            SymbolKind::Struct,
        ] {
            let s = kind.to_string();
            let parsed: SymbolKind = s.parse().unwrap();
            assert_eq!(kind, parsed);
        }
    }
}
