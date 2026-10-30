#[cfg(test)]
mod cases {
    use std::path::Path;

    use crate::parser::LanguageParser;
    use crate::parser::typescript::TypeScriptParser;
    use crate::types::{Language, SymbolKind};

    #[test]
    fn test_parse_function() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
/**
 * Greets a person by name.
 * @param name - The name to greet
 */
function greet(name: string): string {
    return `Hello, ${name}!`;
}
"#;
        let result = parser
            .parse_file(Path::new("test.ts"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "greet");
        assert_eq!(sym.kind, SymbolKind::Function);
        assert!(
            sym.signature
                .as_ref()
                .is_some_and(|s| s.contains("function greet"))
        );
        assert!(sym.documentation.is_some());
    }

    #[test]
    fn test_parse_class() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
class Person {
    name: string;

    constructor(name: string) {
        this.name = name;
    }

    greet(): string {
        return `Hello, ${this.name}!`;
    }
}
"#;
        let result = parser
            .parse_file(Path::new("test.ts"), source, "test-repo")
            .expect("parse file");

        assert!(result.symbols.len() >= 2);

        let class_sym = result
            .symbols
            .iter()
            .find(|s| s.kind == SymbolKind::Class)
            .expect("class symbol");
        assert_eq!(class_sym.name, "Person");

        let method_sym = result
            .symbols
            .iter()
            .find(|s| s.name == "greet")
            .expect("method symbol");
        assert_eq!(method_sym.kind, SymbolKind::Method);
    }

    #[test]
    fn test_parse_interface() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
interface User {
    id: number;
    name: string;
    email?: string;
}
"#;
        let result = parser
            .parse_file(Path::new("test.ts"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "User");
        assert_eq!(sym.kind, SymbolKind::Interface);
    }


    #[test]
    fn test_parse_arrow_function() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
const add = (a: number, b: number): number => a + b;
"#;
        let result = parser
            .parse_file(Path::new("test.ts"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "add");
        assert_eq!(sym.kind, SymbolKind::Function);
    }

    #[test]
    fn test_parse_enum() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
enum Color {
    Red,
    Green,
    Blue
}
"#;
        let result = parser
            .parse_file(Path::new("test.ts"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "Color");
        assert_eq!(sym.kind, SymbolKind::Enum);
    }

    #[test]
    fn test_parse_imports() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
import React from 'react';
import { useState, useEffect } from 'react';
import * as fs from 'fs';
"#;
        let result = parser
            .parse_file(Path::new("test.ts"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.imports.len(), 3);
        assert_eq!(result.imports[0].module_path, "react");
        assert_eq!(result.imports[1].module_path, "react");
        assert_eq!(result.imports[2].module_path, "fs");
    }

    #[test]
    fn test_parse_javascript() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
function hello(name) {
    return "Hello, " + name;
}
"#;
        let result = parser
            .parse_file(Path::new("test.js"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "hello");
        assert_eq!(sym.language, Language::JavaScript);
    }

    #[test]
    fn test_parse_tsx() {
        let mut parser = TypeScriptParser::new().expect("parser init");
        let source = r#"
function Button({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
    return <button onClick={onClick}>{children}</button>;
}
"#;
        let result = parser
            .parse_file(Path::new("test.tsx"), source, "test-repo")
            .expect("parse file");

        assert_eq!(result.symbols.len(), 1);
        let sym = &result.symbols[0];
        assert_eq!(sym.name, "Button");
        assert_eq!(sym.kind, SymbolKind::Function);
    }
}
