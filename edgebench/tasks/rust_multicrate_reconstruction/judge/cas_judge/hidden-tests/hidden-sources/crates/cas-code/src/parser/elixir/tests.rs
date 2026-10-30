#[test]
fn test_parse_module() {
    let mut parser = ElixirParser::new().unwrap();
    let source = r#"
defmodule MyApp.Server do
  def start do
    :ok
  end
end
"#;
    let result = parser
        .parse_file(Path::new("test.ex"), source, "test-repo")
        .unwrap();

    assert!(
        result
            .symbols
            .iter()
            .any(|s| s.name == "MyApp.Server" && s.kind == SymbolKind::Module)
    );
    assert!(
        result
            .symbols
            .iter()
            .any(|s| s.name == "start" && s.kind == SymbolKind::Function)
    );
}

#[test]
fn test_parse_struct() {
    let mut parser = ElixirParser::new().unwrap();
    let source = r#"
defmodule User do
  defstruct [:name, :email, age: 0]
end
"#;
    let result = parser
        .parse_file(Path::new("test.ex"), source, "test-repo")
        .unwrap();

    assert!(result.symbols.iter().any(|s| s.kind == SymbolKind::Struct));
}

#[test]
fn test_parse_protocol() {
    let mut parser = ElixirParser::new().unwrap();
    let source = r#"
defprotocol Stringify do
  def to_string(data)
end
"#;
    let result = parser
        .parse_file(Path::new("test.ex"), source, "test-repo")
        .unwrap();

    assert!(
        result
            .symbols
            .iter()
            .any(|s| s.name == "Stringify" && s.kind == SymbolKind::Interface)
    );
}

#[test]
fn test_parse_nested_modules() {
    let mut parser = ElixirParser::new().unwrap();
    let source = r#"
defmodule Outer do
  defmodule Inner do
    def nested_function do
      :ok
    end
  end

  def outer_function do
    :ok
  end
end
"#;
    let result = parser
        .parse_file(Path::new("test.ex"), source, "test-repo")
        .unwrap();

    assert!(result.symbols.iter().any(|s| s.name == "Outer"));
    assert!(result.symbols.iter().any(|s| s.name == "Inner"));
    assert!(result.symbols.iter().any(|s| s.name == "nested_function"));
    assert!(result.symbols.iter().any(|s| s.name == "outer_function"));
}
