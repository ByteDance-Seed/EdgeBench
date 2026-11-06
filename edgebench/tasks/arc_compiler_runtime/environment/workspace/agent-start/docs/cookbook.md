# Cookbook

Practical recipes showing idiomatic Arc patterns. Each example is self-contained and runnable.

## Data Processing

### Parse CSV and Transform

Read CSV text, parse rows into maps, and filter with pipelines.

```arc
use str
use io

let csv = io.read("users.csv")

let rows = csv
  |> str.lines()
  |> map(fn(line) { str.split(line, ",") })

let headers = rows[0]

let users = rows[1..]
  |> map(fn(cols) {
    { name: cols[0], age: int(cols[1]), city: cols[2] }
  })
  |> filter(fn(u) { u.age >= 18 })

print(users)
```

### JSON Transform Pipeline

Parse JSON, reshape data, and serialize back.

```arc
use json

let raw = '{"users": [{"first": "Kai", "last": "Park"}, {"first": "Ava", "last": "Chen"}]}'

let result = json.parse(raw).users
  |> map(fn(u) { { full_name: u.first + " " + u.last } })
  |> json.encode()

print(result)
// [{"full_name":"Kai Park"},{"full_name":"Ava Chen"}]
```

## String Manipulation

### Build Templates with Interpolation

```arc
fn greeting(name, items) {
  let count = len(items)
  "Hey {name}, you have {count} item{if count != 1 { "s" } else { "" }} in your cart."
}

print(greeting("Kai", ["book", "pen", "tape"]))
// Hey Kai, you have 3 items in your cart.
```

### Extract with Regex

```arc
use re

let log = "2026-02-21 ERROR [db] Connection timeout after 30s"

let ts = re.find(log, `\d{4}-\d{2}-\d{2}`)
let level = re.find(log, `ERROR|WARN|INFO`)
let module = re.find(log, `\[(\w+)\]`, 1)

print("{ts} | {level} | {module}")
// 2026-02-21 | ERROR | db
```

## Error Handling

### Try/Catch with Fallbacks

```arc
use io
use json

fn load_config(path) {
  try {
    let raw = io.read(path)
    json.parse(raw)
  } catch err {
    print("Config load failed: {err}, using defaults")
    { port: 8080, debug: false }
  }
}

let config = load_config("config.json")
print("Running on port {config.port}")
```

### Result Chaining

```arc
use result

fn parse_port(s) {
  let n = try_int(s)
  match n {
    Result.Ok(p) if p > 0 and p < 65536 => Result.Ok(p),
    Result.Ok(p) => Result.Err("port out of range: {p}"),
    Result.Err(e) => Result.Err("not a number: {e}")
  }
}

let port = parse_port("3000")
  |> result.unwrap_or(8080)

print("Using port {port}")
```

## Pattern Matching

### Match on Types and Ranges

```arc
fn describe(value) {
  match value {
    0 => "zero",
    1..9 => "single digit",
    10..99 => "double digit",
    n: Int => "big number: {n}",
    s: String => "text: {s}",
    _ => "unknown"
  }
}

print(describe(42))   // double digit
print(describe("hi")) // text: hi
```

### Destructure Nested Data

```arc
fn summarize(event) {
  match event {
    { type: "login", user: { name, role: "admin" } } =>
      "Admin login: {name}",
    { type: "login", user: { name } } =>
      "User login: {name}",
    { type: "error", code, msg } =>
      "Error {code}: {msg}",
    _ => "Unknown event"
  }
}

let e = { type: "login", user: { name: "Kai", role: "admin" } }
print(summarize(e))
// Admin login: Kai
```

## HTTP & APIs

### Fetch and Parse an API Response

```arc
use http
use json

let resp = http.get("https://api.example.com/users/1")

match resp.status {
  200 => {
    let user = json.parse(resp.body)
    print("Name: {user.name}, Email: {user.email}")
  },
  404 => print("User not found"),
  code => print("Unexpected status: {code}")
}
```

### Simple HTTP Endpoint

```arc
use http

http.serve(3000, fn(req) {
  match [req.method, req.path] {
    ["GET", "/health"] => http.response(200, { status: "ok" }),
    ["GET", "/hello"] => http.response(200, "Hello from Arc!"),
    _ => http.response(404, "Not found")
  }
})

print("Listening on :3000")
```

## Collections

### Group, Sort, and Reduce

```arc
let orders = [
  { item: "book", category: "media", price: 15 },
  { item: "album", category: "media", price: 10 },
  { item: "shirt", category: "clothing", price: 25 },
  { item: "hat", category: "clothing", price: 12 },
]

// Group by category
let grouped = orders |> group_by(fn(o) { o.category })

// Total per category
let totals = grouped
  |> map_values(fn(items) {
    items |> reduce(0, fn(sum, o) { sum + o.price })
  })

print(totals)
// { media: 25, clothing: 37 }

// Top 2 most expensive
let top = orders
  |> sort_by(fn(o) { -o.price })
  |> take(2)
  |> map(fn(o) { o.item })

print(top) // ["shirt", "book"]
```

## File I/O

### Read, Process, and Write Files

```arc
use io

// Read lines, filter blanks, number them
let lines = io.read("input.txt")
  |> str.lines()
  |> filter(fn(l) { str.trim(l) != "" })
  |> enumerate()
  |> map(fn([i, l]) { "{i + 1}: {l}" })
  |> str.join("\n")

io.write("output.txt", lines)
print("Wrote {len(str.lines(lines))} lines")
```

### Walk a Directory

```arc
use io

let files = io.glob("src/**/*.arc")
  |> filter(fn(f) { !str.contains(f, "test") })
  |> sort()

for f in files {
  let size = io.stat(f).size
  print("{f} — {size} bytes")
}
```

## AI / Agent Patterns

### Prompt and Parse with LLM

```arc
use llm
use json

let response = llm.chat("gpt-4", [
  { role: "system", content: "Extract structured data. Reply with JSON only." },
  { role: "user", content: "Kai Park, age 28, lives in Seoul, works as engineer" }
])

let person = json.parse(response.content)
print("{person.name} is {person.age}, based in {person.city}")
```

### Semantic Search with Embeddings

```arc
use embed
use store

// Index documents
let docs = ["Arc is a modern language", "Pipelines chain operations", "Pattern matching replaces if/else"]

for doc in docs {
  let vec = embed.text(doc)
  store.insert("docs", { text: doc, embedding: vec })
}

// Query
let query_vec = embed.text("How do I chain functions?")
let results = store.search("docs", query_vec, limit: 3)

for r in results {
  print("{r.score}: {r.text}")
}
```

### Agent Tool Loop

```arc
use llm
use json

let tools = [
  { name: "weather", desc: "Get weather for a city", params: ["city"] },
  { name: "calc", desc: "Evaluate math expression", params: ["expr"] },
]

fn agent(question) {
  let mut messages = [
    { role: "system", content: "You are a helpful agent. Use tools when needed." },
    { role: "user", content: question }
  ]

  loop {
    let resp = llm.chat("gpt-4", messages, tools: tools)

    match resp.tool_call {
      Some({ name, args }) => {
        let result = run_tool(name, args)
        messages = messages + [resp.message, { role: "tool", content: result }]
      },
      None => return resp.content
    }
  }
}

print(agent("What's the weather in Seoul?"))
```
