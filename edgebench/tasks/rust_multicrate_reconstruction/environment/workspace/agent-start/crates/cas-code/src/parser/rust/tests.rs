#[cfg(test)]
mod cases {
    use std::path::Path;

    use crate::parser::LanguageParser;
    use crate::parser::rust::RustParser;
    use crate::types::SymbolKind;

    #[test]
    fn test_parse_function() {
        let mut parser = RustParser::new().expect("parser init");
        let source = r#"
/// This is a doc comment
fn hello_world(name: &str) -> String {
    format!("Hello, {}!", name)
}
"#;
        let result = parser
            .parse_file(Path::new("test.rs"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "hello_world");
        assert_eq!(sym.kind, SymbolKind::Function);
        assert!(
            sym.signature
                .as_ref()
                .is_some_and(|s| s.contains("fn hello_world"))
        );
        assert!(sym.documentation.is_some());
    }


    #[test]
    fn test_parse_impl_with_methods() {
        let mut parser = RustParser::new().expect("parser init");
        let source = r#"
impl Person {
    fn new(name: String) -> Self {
        Self { name, age: 0 }
    }

    fn greet(&self) -> String {
        format!("Hello, {}", self.name)
    }
}
"#;
        let result = parser
            .parse_file(Path::new("test.rs"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 3);
        assert!(result.symbols.iter().any(|s| s.kind == SymbolKind::Impl));
        let methods: Vec<_> = result
            .symbols
            .iter()
            .filter(|s| s.kind == SymbolKind::Method)
            .collect();
        assert_eq!(methods.len(), 2);
    }

}
