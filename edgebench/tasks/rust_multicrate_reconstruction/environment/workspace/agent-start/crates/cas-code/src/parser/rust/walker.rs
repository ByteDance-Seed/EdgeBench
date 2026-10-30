use tree_sitter::Node;

use crate::parser::rust::RustParser;
use crate::types::{CodeSymbol, Import};

impl RustParser {
    /// Recursively walk the AST and extract symbols.
    pub(crate) fn walk_tree(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
        symbols: &mut Vec<CodeSymbol>,
        imports: &mut Vec<Import>,
    ) { todo!() }
}
