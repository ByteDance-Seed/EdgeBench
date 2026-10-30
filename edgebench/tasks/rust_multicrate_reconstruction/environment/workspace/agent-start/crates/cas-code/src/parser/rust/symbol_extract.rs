use chrono::Utc;
use tree_sitter::Node;

use crate::parser::rust::RustParser;
use crate::types::{CodeSymbol, Language, SymbolKind};

impl RustParser {
    pub(crate) fn extract_function(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        parent_id: Option<&str>,
        qualified_prefix: &str,
    ) -> Option<CodeSymbol> { todo!() }

    pub(crate) fn extract_struct(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
    ) -> Option<CodeSymbol> { todo!() }

    pub(crate) fn extract_enum(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
    ) -> Option<CodeSymbol> { todo!() }

    pub(crate) fn extract_trait(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
    ) -> Option<CodeSymbol> { todo!() }

    pub(crate) fn extract_impl(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
    ) -> (Option<CodeSymbol>, Vec<CodeSymbol>) { todo!() }
}
