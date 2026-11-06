use tree_sitter::Node;

use crate::parser::typescript::TypeScriptParser;
use crate::types::Import;

impl TypeScriptParser {
    /// Extract import statements.
    pub(crate) fn extract_import(&self, node: &Node, source: &[u8]) -> Option<Import> { todo!() }

    /// Extract export statements (for re-exports).
    pub(crate) fn extract_export(&self, node: &Node, source: &[u8]) -> Option<Import> { todo!() }
}
