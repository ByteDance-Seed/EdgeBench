    #[test]
    fn test_parse_struct() {
        let mut parser = RustParser::new().expect("parser init");
        let source = r#"
/// A person struct
pub struct Person {
    name: String,
    age: u32,
}
"#;
        let result = parser
            .parse_file(Path::new("test.rs"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "Person");
        assert_eq!(sym.kind, SymbolKind::Struct);
    }

    #[test]
    fn test_extract_imports() {
        let mut parser = RustParser::new().expect("parser init");
        let source = r#"
use std::collections::HashMap;
use crate::types::CodeSymbol;
pub use super::parser::RustParser;
"#;
        let imports = parser.extract_imports(source).expect("extract imports");

        assert_eq!(imports.len(), 3);
        assert!(imports[0].module_path.contains("std::collections"));
        assert!(imports[2].is_reexport);
    }
