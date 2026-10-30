# Learn Arc: Functions & Pipelines
# Extracted from Tutorial 2 — function styles, pipelines, higher-order functions

# --- Expression Body ---
fn add(a, b) => a + b
fn square(x) => x * x
fn greet(name) => "Hello, {name}!"

# --- Block Body (last expression is returned) ---
fn process(data) {
  let cleaned = trim(data)
  let words = split(cleaned, " ")
  let count = len(words)
  print("Processing {count} words...")
  words
}

# --- Factorial (no return keyword needed) ---
fn factorial(n) {
  if n <= 1 { 1 }
  el { n * factorial(n - 1) }
}

# --- Default Parameters ---
fn greet(name, greeting = "Hello") => "{greeting}, {name}!"

# --- Closures and Lambdas ---
let double = x => x * 2
let add = (a, b) => a + b

fn make_adder(n) => x => x + n
let add5 = make_adder(5)
add5(10)    # 15

# --- Pipeline Operator |> ---
# a |> f(b) becomes f(a, b)

# Nested (hard to read):
# print(join(sort(filter(words, w => len(w) > 3)), ", "))

# Pipeline (reads left-to-right):
# words
#   |> filter(w => len(w) > 3)
#   |> sort
#   |> join(", ")
#   |> print

# --- Higher-Order Functions ---
let r1 = [1, 2, 3] |> map(x => x * 2)         # [2, 4, 6]
let r2 = ["hello", "world"] |> map(upper)       # ["HELLO", "WORLD"]
let r3 = [1, 2, 3, 4, 5] |> filter(x => x > 3) # [4, 5]
let r4 = [1, 2, 3, 4] |> reduce((sum, x) => sum + x, 0)  # 10

# --- Chaining ---
let users = [
  {name: "Alice", age: 32, active: true},
  {name: "Bob", age: 25, active: false},
  {name: "Carol", age: 28, active: true},
  {name: "Dave", age: 35, active: true}
]

let result = users
  |> filter(u => u.active)
  |> filter(u => u.age >= 30)
  |> map(u => u.name)
  |> join(", ")

print(result)    # "Alice, Dave"

# --- Custom Higher-Order Functions ---
fn apply_twice(f, x) => f(f(x))
apply_twice(x => x * 2, 3)      # 12

fn compose(f, g) => x => f(g(x))
let shout = compose(upper, s => s ++ "!")
shout("hello")    # "HELLO!"

# --- Blog post summarizer ---
fn summarize_posts(posts, limit = 5) {
  posts
    |> filter(p => p.published)
    |> sort_by(p => p.date)
    |> reverse
    |> take(limit)
    |> map(p => "• {p.title} ({p.date})\n  {p.summary |> take(100)}...")
    |> join("\n\n")
}

# --- Pipe function ---
fn pipe(fns) => x => fns |> reduce(x, (acc, f) => f(acc))
