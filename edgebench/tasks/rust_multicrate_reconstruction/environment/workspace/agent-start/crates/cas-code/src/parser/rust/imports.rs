use tree_sitter::Node;

use crate::parser::rust::RustParser;
use crate::types::Import;

impl RustParser {
    /// Extract use/import statements.
    pub(crate) fn extract_use_statement(&self, node: &Node, source: &[u8]) -> Option<Import> { todo!() }
}
