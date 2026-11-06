    #[test]
    fn test_parse_type_alias() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
type UserId = string | number;
"#;
        let result = parser
            .parse_file(Path::new("test.ts"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "UserId");
        assert_eq!(sym.kind, SymbolKind::Type);
    }
