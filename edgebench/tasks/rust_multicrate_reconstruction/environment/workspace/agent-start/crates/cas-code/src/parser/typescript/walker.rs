use chrono::Utc;
use tree_sitter::Node;

use crate::parser::typescript::TypeScriptParser;
use crate::types::{CodeSymbol, Import, Language, SymbolKind};

impl TypeScriptParser {
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
        is_js: bool,
    ) { todo!() }

    fn extract_variable_functions(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
        symbols: &mut Vec<CodeSymbol>,
        is_js: bool,
    ) { todo!() }

    fn build_variable_function_symbol(
        &self,
        node: &Node,
        source: &[u8],
        file_path: &str,
        file_id: &str,
        repository: &str,
        qualified_prefix: &str,
        name: &str,
        is_js: bool,
    ) -> CodeSymbol { todo!() }
}
