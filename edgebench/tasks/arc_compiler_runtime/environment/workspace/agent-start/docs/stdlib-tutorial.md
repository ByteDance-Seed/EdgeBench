# Arc Standard Library Tutorial

A hands-on guide to using Arc's standard library for real-world tasks.

## Prerequisites

You should be familiar with Arc basics — see the [Getting Started Guide](getting-started.md) and [Language Tour](language-tour.md) first.

---

## 1. Working with Collections

Arc has powerful built-in list operations. No imports needed.

### Map, Filter, Reduce

```arc
let numbers = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]

# Square all numbers
let squares = numbers |> map(n => n * n)
# => [1, 4, 9, 16, 25, 36, 49, 64, 81, 100]

# Keep only evens
let evens = numbers |> filter(n => n % 2 == 0)
# => [2, 4, 6, 8, 10]

# Sum everything
let total = numbers |> reduce((acc, n) => acc + n, 0)
# => 55
```

### Pipelines

Arc's `|>` operator shines when chaining operations:

```arc
let result = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  |> filter(n => n % 2 == 0)    # keep evens
  |> map(n => n * n)             # square them
  |> take(3)                     # first 3
  |> reduce((a, b) => a + b, 0) # sum
# => 4 + 16 + 36 = 56
```

### Searching and Slicing

```arc
let fruits = ["apple", "banana", "cherry", "date"]

fruits |> find(f => f |> len > 5)   # => "banana"
fruits |> contains("cherry")         # => true
fruits |> take(2)                    # => ["apple", "banana"]
fruits |> skip(2)                    # => ["cherry", "date"]
fruits |> reverse                    # => ["date", "cherry", "banana", "apple"]
```

### Working with Maps

```arc
let user = {name: "Alice", age: 30, role: "dev"}

keys(user)    # => ["name", "age", "role"]
values(user)  # => ["Alice", 30, "dev"]

# Access fields
user.name     # => "Alice"
user["age"]   # => 30
```

---

## 2. String Manipulation

Basic string operations are built-in. The `strings` module adds more.

### Built-in String Functions

```arc
let s = "  Hello, World!  "

trim(s)              # => "Hello, World!"
upper("hello")       # => "HELLO"
lower("HELLO")       # => "hello"
split("a,b,c", ",") # => ["a", "b", "c"]
join(["a","b"], "-") # => "a-b"
len("hello")         # => 5
slice("hello", 1, 3) # => "el"
```

### String Interpolation

Arc uses `{}` inside strings for interpolation:

```arc
let name = "Arc"
let version = 1
print("Welcome to {name} v{version}!")
# => Welcome to Arc v1!
```

### The strings Module

```arc
use strings

strings.pad_left("42", 5, "0")     # => "00042"
strings.pad_right("hi", 10, ".")   # => "hi........"
strings.capitalize("hello world")   # => "Hello world"
strings.words("  one  two  three ") # => ["one", "two", "three"]
```

### Pipeline-Friendly String Processing

```arc
use strings

let title = "  hello world  "
  |> trim
  |> strings.capitalize
# => "Hello world"

# Process a list of names
let names = ["alice", "BOB", "Charlie"]
  |> map(n => strings.capitalize(n))
# => ["Alice", "Bob", "Charlie"]
```

---

## 3. HTTP & API Calls

Arc has first-class HTTP support with the `@` tool-call syntax.

### Quick Requests

```arc
# Simple GET — returns the response body
let data = @GET "https://api.example.com/users"

# With headers
let data = @GET "https://api.example.com/users" {
  Authorization: "Bearer {token}"
}
```

### POST with Body

```arc
let result = @POST "https://api.example.com/users" {
  name: "Alice",
  email: "alice@example.com"
}
```

### Parallel Requests

```arc
# Fetch multiple APIs concurrently
let [weather, news] = fetch [
  @GET "api/weather?city=NYC",
  @GET "api/news/top?limit=5"
]
```

### Processing API Data

```arc
let users = @GET "https://api.example.com/users"

let names = users
  |> filter(u => u.active)
  |> map(u => u.name)
  |> sort
  |> join(", ")

print("Active users: {names}")
```

---

## 4. JSON Processing

### Parsing and Stringifying (Planned)

```arc
use json

# Parse a JSON string
let data = json.parse('{"name": "Alice", "age": 30}')
# => {name: "Alice", age: 30}

# Convert to JSON
let s = json.stringify({x: 1, y: [2, 3]})
# => '{"x":1,"y":[2,3]}'

# Pretty print
let pretty = json.pretty({name: "Arc", version: 1})
# => '{
#   "name": "Arc",
#   "version": 1
# }'
```

### Real-World: API → Process → Output

```arc
use json

# Fetch API, transform, output as JSON
let result = @GET "https://api.example.com/products"
  |> filter(p => p.price < 50)
  |> map(p => {name: p.name, price: p.price})
  |> json.pretty

print(result)
```

---

## 5. Testing Your Arc Code

### Writing Tests (Planned)

```arc
use test
use math

fn test_abs() {
  test.assert_eq(math.abs(-5), 5, "abs of negative")
  test.assert_eq(math.abs(0), 0, "abs of zero")
  test.assert_eq(math.abs(3), 3, "abs of positive")
}

fn test_sqrt() {
  test.assert_eq(math.sqrt(4), 2, "sqrt of 4")
  test.assert_eq(math.sqrt(0), 0, "sqrt of 0")
  test.assert_eq(math.sqrt(-1), nil, "sqrt of negative")
}

fn test_clamp() {
  test.assert_eq(math.clamp(15, 0, 10), 10, "clamp above")
  test.assert_eq(math.clamp(-5, 0, 10), 0, "clamp below")
  test.assert_eq(math.clamp(5, 0, 10), 5, "clamp within")
}

test.run([test_abs, test_sqrt, test_clamp])
```

### Testing with Results

```arc
use test
use result

fn test_result_ok() {
  let r = result.ok(42)
  test.assert_ok(r)
  test.assert_eq(result.unwrap(r), 42)
}

fn test_result_err() {
  let r = result.err("oops")
  test.assert_err(r)
  test.assert_eq(result.unwrap_or(r, 0), 0)
}

test.run([test_result_ok, test_result_err])
```

---

## 6. Error Handling with Result

Arc uses the `Result` type for operations that can fail — no exceptions.

### The Basics (Planned)

```arc
use result

# Create results
let good = result.ok(42)
let bad = result.err("file not found")

# Check and extract
result.is_ok(good)          # => true
result.unwrap(good)         # => 42
result.unwrap_or(bad, 0)    # => 0
```

### Chaining with map and flat_map

```arc
use result

fn parse_int(s) {
  # Returns Result<Int>
  match int(s) {
    nil => result.err("not a number: {s}"),
    n   => result.ok(n)
  }
}

fn double(n) => result.ok(n * 2)

let r = parse_int("21")
  |> result.flat_map(double)
# => Ok(42)

let r2 = parse_int("abc")
  |> result.flat_map(double)
# => Err("not a number: abc")
```

### Pattern Matching on Results

```arc
let r = some_operation()

match r {
  Ok(value) => print("Got: {value}"),
  Err(msg)  => print("Error: {msg}")
}
```

---

## 7. File I/O

### Reading and Writing Files (Planned)

```arc
use io

# Read a file
let content = io.read_file("data.txt")
match content {
  Ok(text) => print("File has {len(text)} chars"),
  Err(e)   => print("Error: {e}")
}

# Write a file
io.write_file("output.txt", "Hello from Arc!")

# Read lines and process
let lines = io.read_lines("data.csv")
  |> result.unwrap_or([])
  |> skip(1)                    # skip header
  |> map(line => split(line, ","))
```

### Pipeline: Read → Process → Write

```arc
use io
use strings

let result = io.read_file("names.txt")
  |> result.map(text => {
    text
      |> split("\n")
      |> map(n => strings.capitalize(trim(n)))
      |> filter(n => len(n) > 0)
      |> sort
      |> join("\n")
  })

match result {
  Ok(sorted) => io.write_file("sorted-names.txt", sorted),
  Err(e)     => print("Failed: {e}")
}
```

---

## 8. Math

```arc
use math

# Constants
print("π = {math.PI}")   # => π = 3.141592653589793
print("e = {math.E}")    # => e = 2.718281828459045

# Circle area
fn circle_area(r) => math.PI * math.pow(r, 2)
print(circle_area(5))    # => 78.53981633974483

# Clamping user input
let volume = math.clamp(user_input, 0, 100)

# Safe sqrt
match math.sqrt(x) {
  nil => print("Cannot take sqrt of negative"),
  val => print("√{x} = {val}")
}
```

---

## What's Next?

- Check the [Standard Library Reference](stdlib-reference.md) for full API details
- Browse [examples/](../examples/) for complete programs
- Read the [Language Tour](language-tour.md) for all language features
- See the [FAQ](FAQ.md) for common questions
