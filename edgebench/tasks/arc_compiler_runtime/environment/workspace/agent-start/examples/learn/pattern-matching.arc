# Learn Arc: Pattern Matching
# Extracted from Tutorial 3 — match expressions, destructuring, guards

# --- Basic Match ---
let day = "Monday"
let mood = match day {
  "Friday" => "🎉",
  "Saturday" | "Sunday" => "😎",
  _ => "😤"
}
print(mood)    # "😤"

# --- Match is an expression ---
let status_code = 200
let label = match status_code {
  200 => "OK",
  404 => "Not Found",
  500 => "Server Error",
  _ => "Unknown"
}
print(label)  # "OK"

# --- Or Patterns ---
let key = "help"
let result = match key {
  "q" | "Q" | "quit" | "exit" => "shutdown",
  "h" | "help" => "show help",
  _ => "process"
}
print(result)  # "show help"

# --- Guards ---
let temperature = 25
let feel = match temperature {
  t if t > 40 => "dangerously hot",
  t if t > 30 => "hot",
  t if t > 20 => "pleasant",
  t if t > 10 => "cool",
  t => "cold ({t}°)"
}
print(feel)  # "pleasant"

# --- Range Patterns (using guards) ---
let score = 85
let grade = match score {
  s if s >= 90 => "A",
  s if s >= 80 => "B",
  s if s >= 70 => "C",
  s if s >= 60 => "D",
  _ => "F"
}
print(grade)  # "B"

# --- Map Destructuring ---
# (Map patterns not yet supported in match — use if/else for map matching)

# --- List Destructuring ---
let items = [1, 2, 3, 4, 5]
let desc = match items {
  [] => "empty list",
  [x] => "single item: {x}",
  [first, second] => "pair: {first}, {second}",
  _ => "list with {len(items)} items"
}
print(desc)  # "list with 5 items"

# --- Nested Destructuring ---
# (Map patterns not yet supported in match)

# --- Result Matching ---
let result = Ok(42)
let val = match result {
  Ok(data) => "got: {data}",
  Err(msg) => "failed: {msg}"
}
print(val)  # "got: 42"

# --- API Response Handler ---
# (Uses map destructuring patterns — not yet supported)
# fn handle_response(response) => match response {
#   {status: 200, body} => parse(body),
#   ...
# }

# --- Command Parser ---
fn parse_command(input) {
  let parts = input |> trim |> split(" ")
  match parts {
    ["help"] => "show help",
    ["add", item] => "add: {item}",
    ["remove", item] => "remove: {item}",
    ["list"] => "list items",
    _ => "unknown command"
  }
}

# --- Classify with guards ---
fn classify(x) => match x {
  x if x < 0 => "negative",
  0 => "zero",
  x if x < 10 => "small",
  x if x < 100 => "medium",
  _ => "large"
}

print(classify(-5))   # "negative"
print(classify(0))    # "zero"
print(classify(7))    # "small"
print(classify(50))   # "medium"
print(classify(200))  # "large"

# --- Exercises ---
fn grade(score) => match score {
  s if s < 0 or s > 100 => "Invalid",
  s if s >= 90 => "A",
  s if s >= 80 => "B",
  s if s >= 70 => "C",
  s if s >= 60 => "D",
  _ => "F"
}

print(grade(95))   # "A"
print(grade(73))   # "C"
print(grade(45))   # "F"

# --- Map-based exercises (map destructuring not yet supported) ---
# fn area(s) => match s { ... }
# fn calc(expr) => match expr { ... }
