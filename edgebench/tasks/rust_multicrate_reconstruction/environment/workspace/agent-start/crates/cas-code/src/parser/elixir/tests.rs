use crate::parser::elixir::*;


#[test]
fn test_parse_function() {
    let mut parser = ElixirParser::new().unwrap();
    let source = r#"
defmodule Calculator do
  def add(a, b) do
    a + b
  end

  defp internal_helper(x) do
    x * 2
  end
end
"#;
    let result = parser
        .parse_file(Path::new("test.ex"), source, "test-repo")
        .unwrap();

    let functions: Vec<_> = result
        .symbols
        .iter()
        .filter(|s| s.kind == SymbolKind::Function)
        .collect();

    assert_eq!(functions.len(), 2);
    assert!(
        functions
            .iter()
            .any(|s| s.name == "add" && s.signature.as_ref().unwrap().starts_with("def"))
    );
    assert!(
        functions
            .iter()
            .any(|s| s.name == "internal_helper"
                && s.signature.as_ref().unwrap().starts_with("defp"))
    );
}

#[test]
fn test_parse_macro() {
    let mut parser = ElixirParser::new().unwrap();
    let source = r#"
defmodule MyMacros do
  defmacro my_if(condition, do: do_clause) do
    quote do
      case unquote(condition) do
        true -> unquote(do_clause)
        false -> nil
      end
    end
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
            .any(|s| s.name == "my_if" && s.kind == SymbolKind::Macro)
    );
}



#[test]
fn test_parse_imports() {
    let mut parser = ElixirParser::new().unwrap();
    let source = r#"
defmodule MyApp do
  alias MyApp.Repo
  import Ecto.Query
  require Logger
  use GenServer
end
"#;
    let result = parser
        .parse_file(Path::new("test.ex"), source, "test-repo")
        .unwrap();

    assert!(result.imports.iter().any(|i| i.module_path == "MyApp.Repo"));
    assert!(result.imports.iter().any(|i| i.module_path == "Ecto.Query"));
    assert!(result.imports.iter().any(|i| i.module_path == "Logger"));
    assert!(result.imports.iter().any(|i| i.module_path == "GenServer"));
}


#[test]
fn test_function_with_guards() {
    let mut parser = ElixirParser::new().unwrap();
    let source = r#"
defmodule Guards do
  def check(x) when is_integer(x) and x > 0 do
    :positive
  end

  def check(x) when is_integer(x) do
    :non_positive
  end
end
"#;
    let result = parser
        .parse_file(Path::new("test.ex"), source, "test-repo")
        .unwrap();

    let check_fns: Vec<_> = result
        .symbols
        .iter()
        .filter(|s| s.name == "check")
        .collect();

    // Should have two function clauses
    assert_eq!(check_fns.len(), 2);
}
