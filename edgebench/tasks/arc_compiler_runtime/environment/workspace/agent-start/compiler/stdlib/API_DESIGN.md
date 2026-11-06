# Arc Standard Library API Design

## Design Principles

1. **Token-minimal APIs** — Short function names, no unnecessary prefixes
2. **Convention over configuration** — Sensible defaults, override when needed
3. **Composable** — All functions work with `|>` pipeline
4. **Consistent** — Same patterns across all modules
5. **Zero-import common ops** — `print`, `len`, `map`, `filter` are always available (prelude)

---

## Prelude (Always Available)

These functions require no `use` statement:

```arc
# I/O
print(value)                    # Print to stdout
read(path) -> String            # Read file contents
write(path, data)               # Write to file

# Collections
len(collection) -> Int
map(collection, fn) -> [T]
filter(collection, fn) -> [T]
reduce(collection, init, fn) -> T
sort(collection, [key_fn]) -> [T]
take(collection, n) -> [T]
drop(collection, n) -> [T]
find(collection, fn) -> Option<T>
any(collection, fn) -> Bool
all(collection, fn) -> Bool
sum(collection) -> Number
flat(collection) -> [T]
zip(a, b) -> [(A, B)]
enumerate(collection) -> [(Int, T)]

# Strings
trim(s) -> String
split(s, delim) -> [String]
join(collection, delim) -> String
upper(s) -> String
lower(s) -> String
replace(s, from, to) -> String
contains(s, substr) -> Bool
starts(s, prefix) -> Bool
ends(s, suffix) -> Bool

# Type conversion
int(value) -> Int
float(value) -> Float
str(value) -> String
bool(value) -> Bool

# Math
min(a, b) -> Number
max(a, b) -> Number
abs(x) -> Number
round(x, [decimals]) -> Number
```

**Rationale:** These ~40 functions cover ~80% of typical agent operations. No imports needed = fewer tokens per program. Names are short (3-5 chars) and unambiguous.

---

## Module: `std/collections`

```arc
use std/collections: Set, Stack, Queue, deque

# Sets
let s = Set([1, 2, 3])
s |> add(4)                     # {1, 2, 3, 4}
s |> has(2)                     # true
s |> union(Set([3, 4, 5]))      # {1, 2, 3, 4, 5}
s |> intersect(Set([2, 3]))     # {2, 3}
s |> diff(Set([2]))             # {1, 3}

# Stack (LIFO)
let st = Stack()
st |> push(1) |> push(2)
st |> pop                       # (2, Stack([1]))

# Queue (FIFO)
let q = Queue()
q |> enq(1) |> enq(2)
q |> deq                        # (1, Queue([2]))

# Sorted map
use std/collections: SortedMap
let sm = SortedMap({a: 1, c: 3, b: 2})
sm |> keys                      # ["a", "b", "c"]
```

---

## Module: `std/math`

```arc
use std/math: pi, e, sin, cos, tan, log, sqrt, pow, floor, ceil, clamp, rand

sqrt(16)                        # 4.0
clamp(15, 0, 10)               # 10
rand()                          # 0.0..1.0
rand(1, 100)                   # random int 1-100
sin(pi / 2)                    # 1.0
log(e)                         # 1.0
```

---

## Module: `std/http`

```arc
use std/http: serve, request

# Server
serve 3000 {
  GET "/" => fn(req) => "Hello!"
  
  GET "/users/:id" => fn(req) {
    @db("SELECT * FROM users WHERE id = {req.params.id}")
  }
  
  POST "/users" => fn(req) {
    @db("INSERT INTO users VALUES ({req.body.name}, {req.body.email})")
  }
  
  # Middleware
  before => fn(req) {
    log("{req.method} {req.path}")
    req
  }
}

# Client (usually via @GET/@POST, but configurable requests available)
let resp = request({
  url: "https://api.example.com/data",
  method: "GET",
  headers: {Authorization: "Bearer {token}"},
  timeout: 5000
})
```

**Comparison — Express.js equivalent:**

```javascript
// JavaScript: ~50 tokens for basic server setup
const express = require('express');
const app = express();
app.use(express.json());
app.get('/', (req, res) => res.send('Hello!'));
app.get('/users/:id', async (req, res) => { ... });
app.post('/users', async (req, res) => { ... });
app.listen(3000);
```

```arc
# Arc: ~20 tokens for same functionality
serve 3000 {
  GET "/" => fn(req) => "Hello!"
  GET "/users/:id" => fn(req) { ... }
  POST "/users" => fn(req) { ... }
}
```

---

## Module: `std/json`

```arc
use std/json: parse, stringify

let data = parse('{"name": "Arc", "version": 1}')
data.name                       # "Arc"

let text = stringify(data)      # '{"name":"Arc","version":1}'
let pretty = stringify(data, indent: 2)

# Usually unnecessary — @ tool calls auto-parse JSON
let user = @GET "api/users/1"   # Already parsed
```

---

## Module: `std/io`

```arc
use std/io: readLines, appendFile, exists, mkdir, ls, rm, glob

# File operations (read/write are in prelude)
let lines = readLines("data.txt")        # [String]
appendFile("log.txt", "entry\n")
let found = exists("config.json")        # Bool

# Directory operations
mkdir("output")
let files = ls("src")                    # [String]
let arcs = glob("**/*.arc")             # [String]

# Stdin
use std/io: input
let name = input("What's your name? ")
```

---

## Module: `std/async`

```arc
use std/async: spawn, sleep, timeout, channel, select

# Spawn concurrent task
let task = spawn { heavyWork() }
let result = await task

# Sleep
sleep(1000)                     # ms

# Timeout
let data = timeout(5000) {
  @GET "slow-api/data"
} ? defaultData

# Channels (CSP-style)
let (tx, rx) = channel()
spawn { tx.send("hello") }
let msg = rx.recv()             # "hello"

# Select (wait for first)
match select [rx1, rx2, timeout(1000)] {
  (0, msg) => handle1(msg)
  (1, msg) => handle2(msg)
  (2, _) => handleTimeout()
}
```

**Rationale:** CSP-style channels (Go-inspired) are simpler than shared-memory concurrency. `select` provides multiplexing. `timeout` wraps any async operation with a deadline.

---

## Module: `std/csv`

```arc
use std/csv: parseCSV, toCSV

let data = read "data.csv" |> parseCSV   # [{name: "...", age: "..."}]
let text = data |> toCSV                  # Back to CSV string
```

---

## Module: `std/time`

```arc
use std/time: now, format, parse, duration

let t = now()                             # Timestamp
let s = format(t, "YYYY-MM-DD")          # "2026-02-16"
let d = duration(hours: 2, minutes: 30)
let later = t + d
```

---

## Module: `std/regex`

```arc
use std/regex: regex, matchAll, replaceAll

let pat = regex("[0-9]+")
let found = "abc 123 def 456" |> matchAll(pat)   # ["123", "456"]
let cleaned = "abc 123" |> replaceAll(pat, "#")   # "abc #"
```

---

## Module: `std/crypto`

```arc
use std/crypto: hash, hmac, encrypt, decrypt, uuid

let h = hash("sha256", "hello")
let id = uuid()                           # "550e8400-e29b-..."
```

---

## Module: `std/test`

```arc
use std/test: test, assert, assertEq, assertErr

test "addition" {
  assertEq(add(2, 3), 5)
}

test "division by zero" {
  assertErr(divide(1, 0))
}

test "user validation" {
  let user = User({name: "Arc", email: "arc@test.com", age: 1})
  assert(user.age > 0)
}
```

---

## API Design Patterns

### 1. Functions over methods
```arc
# Arc prefers free functions (work with |>)
len(items)          # not items.length
sort(items)         # not items.sort()
filter(items, fn)   # not items.filter(fn)
```

**Rationale:** Free functions compose with `|>`. No method resolution overhead. Agents don't need to remember which type has which method.

### 2. Options as last parameter
```arc
fn request(url, method = "GET", headers = {}, timeout = 30000)
```

### 3. Result types for fallible operations
```arc
fn readFile(path) -> Result<String>   # not throw
fn parse(text) -> Result<Value>       # not throw
```

### 4. Overloading by arity
```arc
rand()              # 0.0..1.0
rand(max)           # 0..max
rand(min, max)      # min..max
```

---

## Token Efficiency Summary

| Operation | JS stdlib | Python stdlib | Arc stdlib | vs JS | vs Python |
|-----------|-----------|---------------|------------|-------|-----------|
| Read file | `fs.readFileSync(p,'utf8')` | `open(p).read()` | `read p` | -70% | -50% |
| Parse JSON | `JSON.parse(text)` | `json.loads(text)` | `parse(text)` | -30% | -25% |
| HTTP GET | `await fetch(url).then(r=>r.json())` | `requests.get(url).json()` | `@GET url` | -75% | -60% |
| Sort by key | `arr.sort((a,b)=>a.k-b.k)` | `sorted(arr,key=lambda x:x.k)` | `sort(arr,x=>x.k)` | -40% | -30% |
| Filter | `arr.filter(x=>x.active)` | `[x for x in arr if x.active]` | `filter(arr,x=>x.active)` | -10% | -20% |
| **Average** | | | | **-45%** | **-37%** |

---

**Last Updated:** 2026-02-16
**Status:** Draft v0.1
