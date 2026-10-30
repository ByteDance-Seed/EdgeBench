# Calculator with Expression Parsing
# Demonstrates: recursion, pattern matching, string processing

# Tokenizer
fn tokenize(input) {
  let chars = chars(input)
  let mut tokens = []
  let mut i = 0
  let mut current_num = ""

  for ch in chars {
    if ch == " " {
      if current_num != "" {
        tokens = push(tokens, {kind: "num", value: int(current_num)})
        current_num = ""
      }
    } el if ch == "+" or ch == "-" or ch == "*" or ch == "/" or ch == "(" or ch == ")" {
      if current_num != "" {
        tokens = push(tokens, {kind: "num", value: int(current_num)})
        current_num = ""
      }
      tokens = push(tokens, {kind: "op", value: ch})
    } el {
      current_num = current_num ++ ch
    }
  }
  if current_num != "" {
    tokens = push(tokens, {kind: "num", value: int(current_num)})
  }
  tokens
}

# Evaluate simple expressions (no precedence, left-to-right)
fn eval_tokens(tokens) {
  if len(tokens) == 0 { ret 0 }
  if len(tokens) == 1 { ret tokens[0].value }

  let mut result = tokens[0].value
  let mut i = 1
  for _ in 0..((len(tokens) - 1) / 2) {
    let op = tokens[i].value
    let num = tokens[i + 1].value
    i = i + 2
    result = match op {
      "+" => result + num,
      "-" => result - num,
      "*" => result * num,
      "/" => result / num,
      _ => result
    }
  }
  result
}

fn calc(input) {
  let tokens = tokenize(input)
  eval_tokens(tokens)
}

# Test the calculator
print("=== Calculator ===")
print("2 + 3 = {calc("2 + 3")}")
print("10 - 4 = {calc("10 - 4")}")
print("6 * 7 = {calc("6 * 7")}")
print("20 / 5 = {calc("20 / 5")}")
print("1 + 2 + 3 = {calc("1 + 2 + 3")}")

# Direct computation with Arc
print("")
print("Arc math:")
print("2 ** 10 = {2 ** 10}")
print("abs(-42) = {abs(-42)}")
print("max(3, 7) = {max(3, 7)}")
print("min(3, 7) = {min(3, 7)}")
print("round(3.7) = {round(3.7)}")
