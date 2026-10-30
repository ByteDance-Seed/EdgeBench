# Arc Cheat Sheet ⚡

## Comments
```arc
# hash comment
// double-slash comment
```

## Variables
```arc
let x = 42              # immutable
let mut y = 0           # mutable
y = y + 1               # reassign mutable
```

## Types
```arc
let n = 42              # int
let f = 3.14            # float
let s = "hello"         # string
let b = true            # bool
let l = [1, 2, 3]       # list
let m = {a: 1, b: 2}    # map
let nothing = nil        # nil
```

## Type Declarations
```arc
# Named types — give meaning to primitives
type Email = String matching /^[^@]+@[^@]+$/
type Positive = Number where x > 0
type Age = Number where x >= 0 and x <= 150
type Username = String matching /^[a-zA-Z_]\w{2,19}$/

# Composite types
type User = {name: String, age: Age, email: Email}

# Union types
type Status = "active" | "inactive" | "banned"
```

Arc's type system is **declaration-based, not annotation-based** — by design. Instead of cluttering every function signature with types, you declare meaningful types once and the checker validates your code. Less ceremony, more meaning. Type declarations are checked at compile time via `arc check file.arc` — they are not runtime constructors (you don't call `Email("foo@bar.com")`).

## Optional Chaining
```arc
let user = {name: "Roger", address: {city: "NYC"}}
print(user?.name)                # "Roger"
print(user?.phone?.number)       # nil (no error)
print(user?.address?.city)       # "NYC"
```

Safe navigation through nested data — returns `nil` instead of crashing if any part is missing.

## Strings
```arc
let name = "world"
let greeting = "hello {name}"           # interpolation
let msg = "total: {x + y}"              # expressions work too
let info = "len: {len(items)}"          # function calls in interpolation
let first = "first: {items[0]}"         # indexing in interpolation
let multi = "line one
line two"                                # multiline
let repeated = "ha" * 3                  # "hahaha"
```

## Functions
```arc
fn add(a, b) { a + b }                  # implicit return (last expr)
fn greet(name) { return "hi {name}" }   # explicit return also works

# Default parameters
fn greet(name, greeting = "hello") { "{greeting} {name}" }

# Rest parameters
fn sum(...nums) { reduce(nums, (a, b) => a + b, 0) }

# Lambdas
let double = (x) => x * 2
let add = (a, b) => a + b
```

## Control Flow
```arc
# If/else (`else` or `el` — both work)
let result = if x > 0 { "positive" } else { "non-positive" }

# Match (pattern matching)
let msg = match status {
  200 => "ok",
  404 => "not found",
  400..499 => "client error",
  500..599 => "server error",
  _ => "unknown"
}

# For loops
for i in 0..5 { print(i) }
for item in list { print(item) }
for [key, val] in entries(map) { print("{key}: {val}") }

# While loops
while x < 10 { x = x + 1 }
while true {
  if done { break }
  continue
}

# Do-while / do-until
do { x = x + 1 } while x < 10
do { x = x + 1 } until x >= 10
```

## Operators
```arc
# Arithmetic
+ - * / % **            # add, sub, mul, div, mod, power

# String
"hello" + " world"      # concatenation (++ also works)
"ha" * 3                # repetition → "hahaha"

# Comparison
== != < > <= >=

# Logical
and or not

# Pipeline
data |> filter(x => x > 0) |> map(x => x * 2) |> sum()

# Range
0..5                    # [0, 1, 2, 3, 4]

# Optional chaining
obj?.prop               # nil if obj is nil
```

## Try/Catch
```arc
# catch requires a variable name (e.g. `catch e`, `catch err`)
try {
  let x = int("not a number")
} catch e {
  print("Error: " + e)
}
```

## Built-in Functions

### I/O
| Function | Description | Example |
|----------|-------------|---------|
| `print(...)` | Print values | `print("hello", 42)` |

### Type Conversion
| Function | Description | Example |
|----------|-------------|---------|
| `int(v)` | Convert to int (throws on bad input) | `int("42")` → `42` |
| `float(v)` | Convert to float (throws on bad input) | `float("3.14")` → `3.14` |
| `str(v)` | Convert to string | `str(42)` → `"42"` |
| `bool(v)` | Convert to bool | `bool(0)` → `false` |
| `type_of(v)` | Get type name | `type_of([])` → `"list"` |

### String Functions
| Function | Description | Example |
|----------|-------------|---------|
| `len(s)` | Length (codepoints) | `len("🔥")` → `1` |
| `trim(s)` | Strip whitespace | `trim("  hi  ")` → `"hi"` |
| `upper(s)` | Uppercase | `upper("hi")` → `"HI"` |
| `lower(s)` | Lowercase | `lower("HI")` → `"hi"` |
| `split(s, sep)` | Split string | `split("a,b", ",")` → `["a","b"]` |
| `join(list, sep)` | Join strings | `join(["a","b"], ",")` → `"a,b"` |
| `replace(s, old, new)` | Replace all | `replace("hi", "h", "H")` → `"Hi"` |
| `contains(s, sub)` | Contains substring | `contains("hello", "ell")` → `true` |
| `starts(s, pre)` | Starts with | `starts("hello", "he")` → `true` |
| `ends(s, suf)` | Ends with | `ends("hello", "lo")` → `true` |
| `repeat(s, n)` | Repeat string | `repeat("-", 40)` → `"----..."` |
| `chars(s)` | Split to chars | `chars("hi")` → `["h","i"]` |
| `slice(s, start, end)` | Substring | `slice("hello", 1, 3)` → `"el"` |
| `index_of(s, sub)` | Find index | `index_of("hello", "l")` → `2` |
| `ord(s)` | Char to code | `ord("A")` → `65` |
| `chr(n)` | Code to char | `chr(65)` → `"A"` |
| `char_at(s, i)` | Char at index | `char_at("hi", 0)` → `"h"` |

### List Functions
| Function | Description | Example |
|----------|-------------|---------|
| `len(list)` | Length | `len([1,2,3])` → `3` |
| `map(list, fn)` | Transform each | `map([1,2], x => x*2)` → `[2,4]` |
| `filter(list, fn)` | Keep matching | `filter([1,2,3], x => x>1)` → `[2,3]` |
| `reduce(list, fn, init)` | Fold left | `reduce([1,2,3], (a,b) => a+b, 0)` → `6` |
| `fold(list, init, fn)` | Fold (init first) | `fold([1,2,3], 0, (a,b) => a+b)` → `6` |
| `find(list, fn)` | First match | `find([1,2,3], x => x>1)` → `2` |
| `any(list, fn)` | Any match? | `any([1,2,3], x => x>2)` → `true` |
| `all(list, fn)` | All match? | `all([1,2,3], x => x>0)` → `true` |
| `sort(list)` | Sort | `sort([3,1,2])` → `[1,2,3]` |
| `head(list)` | First element | `head([1,2,3])` → `1` |
| `tail(list)` | All but first | `tail([1,2,3])` → `[2,3]` |
| `last(list)` | Last element | `last([1,2,3])` → `3` |
| `reverse(list)` | Reverse | `reverse([1,2,3])` → `[3,2,1]` |
| `take(list, n)` | First n | `take([1,2,3], 2)` → `[1,2]` |
| `drop(list, n)` | Skip n | `drop([1,2,3], 1)` → `[2,3]` |
| `flat(list)` | Flatten nested | `flat([[1],[2,3]])` → `[1,2,3]` |
| `zip(a, b)` | Zip two lists | `zip([1,2],["a","b"])` → `[[1,"a"],[2,"b"]]` |
| `enumerate(list)` | Add indices | `enumerate(["a","b"])` → `[[0,"a"],[1,"b"]]` |
| `push(list, item)` | Append (new list) | `push([1,2], 3)` → `[1,2,3]` |
| `concat(a, b)` | Concatenate | `concat([1],[2])` → `[1,2]` |
| `sum(list)` | Sum numbers | `sum([1,2,3])` → `6` |
| `range(a, b)` | Number range | `range(0, 5)` → `[0,1,2,3,4]` |
| `contains(list, v)` | Has element? | `contains([1,2], 2)` → `true` |

### Map Functions
| Function | Description | Example |
|----------|-------------|---------|
| `len(map)` | Number of keys | `len({a:1, b:2})` → `2` |
| `keys(map)` | Get keys | `keys({a:1})` → `["a"]` |
| `values(map)` | Get values | `values({a:1})` → `[1]` |
| `entries(map)` | Key-value pairs | `entries({a:1})` → `[{key:"a",value:1}]` |

### Math
| Function | Description | Example |
|----------|-------------|---------|
| `abs(n)` | Absolute value | `abs(-5)` → `5` |
| `min(a, b)` / `min(list)` | Minimum | `min(1, 2)` → `1` |
| `max(a, b)` / `max(list)` | Maximum | `max(1, 2)` → `2` |
| `round(n)` | Round | `round(3.7)` → `4` |

### Other
| Function | Description | Example |
|----------|-------------|---------|
| `assert(cond, msg)` | Assert truth | `assert(x > 0, "must be positive")` |
| `time_ms()` | Unix timestamp ms | `time_ms()` → `1708000000000` |
| `to_string(v)` | Alias for str | `to_string(42)` → `"42"` |

## Modules (use)
```arc
use math                 # import module
math.sqrt(16)            # namespace access
use math { sqrt, PI }    # selective import
sqrt(16)                 # direct access
```

### Key Modules
| Module | Highlights |
|--------|-----------|
| `math` | sqrt, pow, ceil, floor, clamp, PI, E, sin, cos, log |
| `strings` | pad_left, pad_right, capitalize, words |
| `collections` | group_by, chunk, flatten, zip_with, partition, sort_by, unique |
| `map` | merge, map_values, filter_map, from_pairs, pick, omit |
| `io` | read_file, write_file, read_lines, exists, append |
| `http` | get, post, put, delete — real HTTP requests |
| `json` | to_json, from_json, pretty, get_path |
| `csv` | parse_csv, to_csv, parse_csv_headers |
| `regex` | match, find, test, replace, split, capture |
| `datetime` | now, today, parse, format, add_days, diff_days |
| `os` | cwd, list_dir, mkdir, exec, platform, env, remove, copy |
| `env` | get, set, has, all — environment variables |
| `crypto` | sha256, sha512, hmac_sha256, uuid, random_bytes |
| `error` | try_catch, try_finally, throw, retry, assert |
| `result` | ok, err, is_ok, unwrap, map_result, try_fn |
| `net` | ws_connect, tcp_connect, dns_lookup, base64_encode |
| `yaml` | parse, stringify |
| `toml` | parse, stringify |
| `html` | parse, create_element, to_html |
| `path` | join, dirname, basename, extname |
| `log` | info, warn, error, debug |
| `store` | get, set, delete — persistent key-value storage |
| `test` | describe, it, expect_eq, run_tests |

## Toolchain
```bash
arc run file.arc         # Run a program
arc repl                 # Interactive REPL
arc new myproject        # Scaffold a project
arc build                # Build a project
arc test dir/            # Run tests
arc fmt file.arc         # Format code
arc lint file.arc        # Lint code
arc check file.arc       # Type check
arc parse file.arc       # Show AST
arc ir file.arc          # Show IR
arc compile file.arc     # Compile to JS
arc builtins             # List all built-in functions
```

## Agent Workflows
```arc
// HTTP requests
use http
let res = http.get("https://api.example.com/data")
print(res.status)  // 200
print(res.data)    // response body (parsed JSON or string)
print(res.ok)      // true if 2xx

// Fetch (parallel HTTP)
let [weather, news] = fetch [
  @GET "https://api.weather.com/current",
  @GET "https://api.news.com/top"
]

// Environment variables
use env
let api_key = env.get("API_KEY")

// Shell commands
use os
let output = os.exec("ls -la")
print(output)

// File I/O
use io
let content = io.read_file("config.json")
io.write_file("output.txt", "hello")

// JSON processing
use json
let data = json.from_json(content)
let pretty = json.pretty(data)

// Error handling
try {
  let val = int(user_input)
} catch e {
  print("Invalid: " + e)
}
```

## Additional Syntax

### Arrow Function Declarations
```arc
fn add(a, b) => a + b                   # named arrow fn (single expr)
fn square(x) => x * x
fn greet(name) => "hello {name}"
```

### Return Keyword (`ret`)
```arc
fn find(list, target) {
  for item in list {
    if item == target { ret item }       # ret = return (both work)
  }
  ret nil
}
```

### Visibility (`pub`)
```arc
pub let API_VERSION = "1.0"             # public variable
pub fn handle(req) { ... }              # public function
pub type Config = { port: Int }         # public type
pub async fn fetch_data() { ... }       # public async function
```

### Async / Await
```arc
async fn fetch_user(id) {
  let res = await http.get("/users/{id}")
  res.data
}

async {                                  # async block
  let data = await load()
  process(data)
}
```

### Tool Calls (`@GET`, `@POST`, etc.)
```arc
# Declarative HTTP tool calls
@GET "https://api.example.com/items"
@POST "https://api.example.com/items" { name: "new", value: 42 }
@PUT "https://api.example.com/items/1" { name: "updated" }
@DELETE "https://api.example.com/items/1"

# Fetch with parallel tool calls
let [a, b] = fetch [
  @GET "https://api.a.com/data",
  @POST "https://api.b.com/data" { query: "test" }
]
```

### Import (alternative to `use`)
```arc
import crypto                            # import module
import regex from "stdlib/regex"         # import from path
import net                               # import net module
crypto.sha256("hello")
```

### List Comprehensions
```arc
let squares = [x * 2 for x in range(0, 10)]
let evens = [x for x in list if x % 2 == 0]
let pairs = [[x, y] for x in xs for y in ys]
let grid = [x + y for x in [1,2] for y in [10,20]]
```

### Destructuring
```arc
# Array destructuring
let [a, b, c] = [1, 2, 3]
let [first, ...rest] = [1, 2, 3, 4]     # rest parameter

# Map/object destructuring
let {name, age} = {name: "Arc", age: 1}
let {x, ...others} = {x: 1, y: 2, z: 3}

# In function parameters
fn process([head, ...tail]) { ... }
fn greet({name, age}) { "Hi {name}, age {age}" }

# In for loops
for [key, val] in entries(map) { ... }
for {name, score} in students { ... }
```

### Rich Match Patterns
```arc
match value {
  0 => "zero",                           # literal
  x if x > 100 => "big: {x}",          # binding with guard
  [1, 2, ...] => "starts with 1,2",    # array pattern
  {name: "admin"} => "admin user",      # object pattern
  "a" | "b" | "c" => "letter",         # or-pattern
  true => "yes",
  nil => "nothing",
  -1 => "negative one",                 # negative literal
  _ => "other"                           # wildcard
}
```

### Member and Index Assignment
```arc
let mut obj = {name: "arc", version: 1}
obj.version = 2                          # member assignment
obj.new_field = true                     # add field

let mut arr = [1, 2, 3]
arr[0] = 10                              # index assignment

let mut nested = {data: {count: 0}}
nested.data.count = 5                    # nested member assignment
```

### Semicolons
```arc
let a = 1; let b = 2; let c = a + b     # semicolons separate statements
fn pair(x, y) => [x, y]; pair(1, 2)     # inline statement separator
```

### Function Types
```arc
type Handler = (Int) -> String
type Reducer = (Int, Int) -> Int
type Predicate = (String) -> Bool
```

