#[test]
fn test_parse_async_function() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
async def fetch_data(url: str) -> dict:
    """Fetch data from URL."""
    pass
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    assert_eq!(result.symbols.len(), 1);
    let sym = &result.symbols[0];
    assert_eq!(sym.name, "fetch_data");
    assert!(sym.signature.as_ref().unwrap().contains("async def"));
}

#[test]
fn test_parse_type_hints() {
    let mut parser = PythonParser::new().unwrap();
    let source = r#"
def process(data: list[dict[str, int]]) -> tuple[bool, str]:
    """Process some data."""
    return True, "done"
"#;
    let result = parser
        .parse_file(Path::new("test.py"), source, "test-repo")
        .unwrap();

    assert_eq!(result.symbols.len(), 1);
    let sym = &result.symbols[0];
    assert!(
        sym.signature
            .as_ref()
            .unwrap()
            .contains("-> tuple[bool, str]")
    );
}
