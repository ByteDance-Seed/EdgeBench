    #[test]
    fn test_parse_struct() {
        let mut parser = GoParser::new().unwrap();
        let source = r#"
package main

// Config holds configuration values.
type Config struct {
    Name    string
    Port    int
    Enabled bool
}
"#;
        let result = parser
            .parse_file(Path::new("test.go"), source, "test-repo")
            .unwrap();

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "Config");
        assert_eq!(sym.kind, SymbolKind::Struct);
        assert!(
            sym.signature
                .as_ref()
                .unwrap()
                .contains("type Config struct")
        );
    }

    #[test]
    fn test_parse_type_alias() {
        let mut parser = GoParser::new().unwrap();
        let source = r#"
package main

type StringSlice []string
"#;
        let result = parser
            .parse_file(Path::new("test.go"), source, "test-repo")
            .unwrap();

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "StringSlice");
        assert_eq!(sym.kind, SymbolKind::Type);
    }
