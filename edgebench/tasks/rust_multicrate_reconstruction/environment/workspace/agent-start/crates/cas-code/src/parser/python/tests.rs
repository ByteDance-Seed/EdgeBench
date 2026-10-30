use crate::parser::python::*;

#[test]
fn test_parse_function() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
def greet(name: str) -> str:
    """Greet someone by name."""
    return f"Hello, {name}!"
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    assert_eq!(result.symbols.len(), 1);
    let sym = &result.symbols[0];
    assert_eq!(sym.name, "greet");
    assert_eq!(sym.kind, SymbolKind::Function);
    assert!(sym.signature.as_ref().unwrap().contains("def greet"));
    assert!(sym.documentation.is_some());
    assert_eq!(
        sym.documentation.as_ref().unwrap(),
        "Greet someone by name."
    );
}


#[test]
fn test_parse_class() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
class Person:
    """A person class."""

    def __init__(self, name: str):
        self.name = name

    def greet(self) -> str:
        return f"Hello, {self.name}!"
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    // Should have class + __init__ + greet method
    assert_eq!(result.symbols.len(), 3);

    let class_sym = result
        .symbols
        .iter()
        .find(|s| s.kind == SymbolKind::Class)
        .unwrap();
    assert_eq!(class_sym.name, "Person");
    assert!(
        class_sym
            .documentation
            .as_ref()
            .unwrap()
            .contains("A person class")
    );

    let init_sym = result
        .symbols
        .iter()
        .find(|s| s.name == "__init__")
        .unwrap();
    assert_eq!(init_sym.kind, SymbolKind::Method);

    let greet_sym = result.symbols.iter().find(|s| s.name == "greet").unwrap();
    assert_eq!(greet_sym.kind, SymbolKind::Method);
}

#[test]
fn test_parse_class_with_inheritance() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
class Employee(Person):
    def __init__(self, name: str, employee_id: int):
        super().__init__(name)
        self.employee_id = employee_id
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    let class_sym = result
        .symbols
        .iter()
        .find(|s| s.kind == SymbolKind::Class)
        .unwrap();
    assert_eq!(class_sym.name, "Employee");
    assert!(class_sym.signature.as_ref().unwrap().contains("(Person)"));
}

#[test]
fn test_parse_decorated_function() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
@decorator
@another_decorator(arg)
def my_function():
    pass
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    assert_eq!(result.symbols.len(), 1);
    let sym = &result.symbols[0];
    assert_eq!(sym.name, "my_function");
    assert!(sym.signature.as_ref().unwrap().contains("@decorator"));
}

#[test]
fn test_parse_decorated_class() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
@dataclass
class Config:
    name: str
    value: int
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    let class_sym = result
        .symbols
        .iter()
        .find(|s| s.kind == SymbolKind::Class)
        .unwrap();
    assert_eq!(class_sym.name, "Config");
    assert!(class_sym.signature.as_ref().unwrap().contains("@dataclass"));
}

#[test]
fn test_parse_imports() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
import os
import sys
from typing import List, Dict
from . import local_module
from ..parent import something
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    assert!(result.imports.len() >= 4);

    // Check import os
    assert!(result.imports.iter().any(|i| i.module_path == "os"));

    // Check from typing import
    let typing_import = result
        .imports
        .iter()
        .find(|i| i.module_path == "typing")
        .unwrap();
    assert!(typing_import.items.contains(&"List".to_string()));
    assert!(typing_import.items.contains(&"Dict".to_string()));
}

#[test]
fn test_parse_staticmethod() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
class Utils:
    @staticmethod
    def helper(x: int) -> int:
        return x * 2
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    let helper_sym = result.symbols.iter().find(|s| s.name == "helper").unwrap();
    // Static methods are treated as functions, not methods
    assert_eq!(helper_sym.kind, SymbolKind::Function);
}

