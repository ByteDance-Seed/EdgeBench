# Mini Expression Compiler
# Demonstrates: tokenization, parsing, AST, code generation

# Tokenizer
fn tokenize(src) {
  let chs = chars(src)
  let mut tokens = []
  let mut i = 0
  let mut num_buf = ""

  for ch in chs {
    if ch == " " {
      if num_buf != "" {
        tokens = push(tokens, {kind: "num", value: num_buf})
        num_buf = ""
      }
    } el if ch == "+" or ch == "-" or ch == "*" or ch == "/" or ch == "(" or ch == ")" {
      if num_buf != "" {
        tokens = push(tokens, {kind: "num", value: num_buf})
        num_buf = ""
      }
      tokens = push(tokens, {kind: "op", value: ch})
    } el {
      num_buf = num_buf ++ ch
    }
  }
  if num_buf != "" {
    tokens = push(tokens, {kind: "num", value: num_buf})
  }
  tokens
}

# Simple AST-based evaluator
fn parse_expr(tokens) {
  # Very simple: handles num op num
  if len(tokens) == 1 {
    ret {kind: "literal", value: int(tokens[0].value)}
  }
  if len(tokens) >= 3 {
    let left = {kind: "literal", value: int(tokens[0].value)}
    let op = tokens[1].value
    let right_tokens = drop(tokens, 2)
    let right = parse_expr(right_tokens)
    ret {kind: "binop", op: op, left: left, right: right}
  }
  {kind: "literal", value: 0}
}

fn eval_ast(node) => match node.kind {
  "literal" => node.value,
  "binop" => {
    let l = eval_ast(node.left)
    let r = eval_ast(node.right)
    match node.op {
      "+" => l + r,
      "-" => l - r,
      "*" => l * r,
      "/" => l / r,
      _ => 0
    }
  },
  _ => 0
}

fn compile_to_stack(node) {
  match node.kind {
    "literal" => ["PUSH {node.value}"],
    "binop" => {
      let left_ops = compile_to_stack(node.left)
      let right_ops = compile_to_stack(node.right)
      let op = match node.op {
        "+" => "ADD",
        "-" => "SUB",
        "*" => "MUL",
        "/" => "DIV",
        _ => "NOP"
      }
      left_ops ++ right_ops ++ [op]
    },
    _ => []
  }
}

fn compile_and_run(src) {
  print("Source: {src}")
  let tokens = tokenize(src)
  print("  Tokens: {tokens |> map(t => t.value)}")
  let ast = parse_expr(tokens)
  let result = eval_ast(ast)
  print("  Result: {result}")
  let bytecode = compile_to_stack(ast)
  print("  Bytecode: {bytecode}")
  print("")
}

# Demo
print("=== Mini Compiler ===")
compile_and_run("2 + 3")
compile_and_run("10 - 4")
compile_and_run("6 * 7")
compile_and_run("100 / 5 + 3")
compile_and_run("1 + 2 + 3 + 4")
