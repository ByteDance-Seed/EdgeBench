use chrono::Utc;
use tree_sitter::Node;

use crate::parser::typescript::TypeScriptParser;
use crate::types::{CodeSymbol, Language, SymbolKind};

impl TypeScriptParser {
    pub(crate) fn extract_function(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        parent_id: Option<&str>,
        qualified_prefix: &str,
        is_js: bool,
    ) -> Option<CodeSymbol> { todo!() }

    pub(crate) fn extract_arrow_function(
        &self,
        name: &str,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
        is_js: bool,
    ) -> Option<CodeSymbol> { todo!() }

    pub(crate) fn extract_class(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
        is_js: bool,
    ) -> (Option<CodeSymbol>, Vec<CodeSymbol>) { todo!() }

    pub(crate) fn extract_method(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        parent_id: Option<&str>,
        qualified_prefix: &str,
        is_js: bool,
    ) -> Option<CodeSymbol> { todo!() }

    pub(crate) fn extract_interface(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
    ) -> Option<CodeSymbol> { todo!() }

    pub(crate) fn extract_type_alias(
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
}
