# Arc Standard Library Modules

**Version:** 0.1  
**Date:** 2026-02-16  
**Status:** Phase 0 - Planning

This document lists all planned modules for the Arc standard library, organized by category.

---

## Core Modules

### `core`
**Purpose:** Fundamental types and operations built into the language

**Exports:**
- Type constructors: `Int`, `Float`, `Bool`, `String`, `Nil`
- Result types: `Ok`, `Err`, `Result<T, E>`
- Option types: `Some`, `None`, `Option<T>`
- Control flow: `if`, `match`, `for`, `while`, `loop`
- Operators: `+`, `-`, `*`, `/`, `%`, `^`, `==`, `!=`, `<`, `>`, etc.

**Status:** Built-in (compiler)

---

### `collections`
**Purpose:** Data structure operations

**Submodules:**
- `collections/list` - List/Array operations
- `collections/map` - Hash map/dictionary
- `collections/set` - Set operations
- `collections/queue` - FIFO queue
- `collections/stack` - LIFO stack
- `collections/heap` - Priority queue/heap

**Exports:**
```arc
// List
List, map, filter, reduce, take, drop, chunk, zip, flatten, uniq, sort

// Map
Map, get, set, keys, values, entries, merge, filter, map_values

// Set
Set, union (∪), intersect (∩), difference (-), subset (⊆), superset (⊇)

// Queue
Queue, enqueue, dequeue, peek, empty?

// Stack
Stack, push, pop, peek, empty?

// Heap
Heap, push, pop, peek, heapify
```

**Token Efficiency Target:** 40-50% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

### `string`
**Purpose:** String manipulation and text processing

**Exports:**
```arc
// Creation & Conversion
String, from, to_string, parse

// Queries
len (#), empty?, contains (∈), starts?, ends?, match?

// Transform
upper, lower, trim, trim_start, trim_end
replace, replace_all, split, join
pad_left, pad_right, center
repeat, reverse

// Pattern matching
match, match_all, replace_regex, split_regex

// Unicode
graphemes, codepoints, bytes, chars
normalize, is_ascii?, is_alpha?, is_digit?

// Formatting
fmt, template, interpolate
```

**Token Efficiency Target:** 35-45% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

### `math`
**Purpose:** Mathematical operations and functions

**Exports:**
```arc
// Constants
π (PI), e (E), τ (TAU), ∞ (INFINITY)

// Basic
abs (|x|), sign, min, max, clamp
round, floor, ceil, trunc

// Power & Roots
sqrt (√), cbrt (∛), pow (^), exp
log, log10, log2, ln

// Trigonometry
sin, cos, tan, asin, acos, atan, atan2
sinh, cosh, tanh, asinh, acosh, atanh

// Aggregates
sum (∑), product (∏), mean, median, mode
variance, stddev, min, max

// Random
random, random_int, random_range, shuffle, sample

// Ranges
range (..), step, take, infinite
```

**Token Efficiency Target:** 45-55% reduction vs JS/Python (thanks to symbols)

**Status:** Phase 3 - Implementation

---

## I/O Modules

### `io`
**Purpose:** Input/output primitives

**Exports:**
```arc
// Console
print, println, eprint, eprintln, input, prompt

// Streams
Stream, read, write, close, flush
stdin, stdout, stderr

// Readers/Writers
Reader, Writer, read_all, read_line, read_bytes
write_all, write_line, write_bytes

// Buffering
BufferedReader, BufferedWriter, buffer_size
```

**Token Efficiency Target:** 50-60% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

### `fs`
**Purpose:** File system operations

**Exports:**
```arc
// File operations
read, write, append, delete, copy, move
exists?, is_file?, is_dir?, is_symlink?
size, mtime, atime, ctime, permissions

// Directory operations
ls, mkdir, rmdir, chdir, pwd
walk, glob

// Path manipulation
abspath, relpath, basename, dirname, extname
joinpath, splitpath, normalize

// Temporary files
tmp, tmpdir, tmp_file

// Watching
watch, on_change, on_create, on_delete
```

**Token Efficiency Target:** 55-65% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

### `net`
**Purpose:** Network operations (low-level)

**Exports:**
```arc
// TCP
TcpListener, TcpStream
bind, connect, listen, accept
send, recv, close

// UDP
UdpSocket, send_to, recv_from

// DNS
resolve, lookup, reverse_lookup

// IP
IpAddr, Ipv4, Ipv6, parse, to_string

// URL
Url, parse, scheme, host, port, path, query, fragment
```

**Token Efficiency Target:** 40-50% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

### `http`
**Purpose:** HTTP client and server

**Exports:**
```arc
// Client
GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
request, fetch

// Client config
headers, timeout, retry, redirect

// Server
serve, route, handler
GET "/path" => handler
POST "/path" => handler

// Request/Response
Request, Response, status, body, headers, cookies

// WebSocket
WebSocket, connect, send, recv, on, close

// Middleware
cors, auth, logging, compression
```

**Token Efficiency Target:** 50-60% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

## Concurrency Modules

### `async`
**Purpose:** Async primitives and utilities

**Exports:**
```arc
// Execution
spawn, parallel, await, race, timeout

// Task management
Task, cancel, is_done?, is_cancelled?, result

// Sleep & Timing
sleep, delay, interval

// Utilities
join, join_all, select
```

**Token Efficiency Target:** 40-50% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

### `channel`
**Purpose:** Message passing between tasks

**Exports:**
```arc
// Channel creation
Channel, bounded, unbounded

// Operations
send (<-), recv (<-), try_send, try_recv
close, is_closed?

// Select
select, select_timeout

// Iteration
for msg in channel
```

**Token Efficiency Target:** 45-55% reduction vs Go

**Status:** Phase 3 - Implementation

---

### `sync`
**Purpose:** Synchronization primitives

**Exports:**
```arc
// Mutex
Mutex, lock, unlock, try_lock, is_locked?
with_lock (auto-unlock)

// RwLock (Read-write lock)
RwLock, read_lock, write_lock, unlock

// Atomic
Atomic, load, store, swap, compare_swap
inc, dec, add, sub

// WaitGroup
WaitGroup, add, done, wait

// Once
Once, do

// Semaphore
Semaphore, acquire, release, try_acquire

// Barrier
Barrier, wait
```

**Token Efficiency Target:** 35-45% reduction vs Go

**Status:** Phase 3 - Implementation

---

## Data Modules

### `json`
**Purpose:** JSON serialization/deserialization

**Exports:**
```arc
// Parsing
parse, from_string, from_reader

// Serialization
stringify, to_string, to_writer
pretty, minify

// Validation
validate, schema

// Path queries (JSONPath)
query, select, filter
```

**Token Efficiency Target:** 50-60% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

### `csv`
**Purpose:** CSV/TSV handling

**Exports:**
```arc
// Reading
read, read_all, read_header
parse, from_string

// Writing
write, write_all, write_header
to_string

// Configuration
delimiter, quote, escape, header?
```

**Token Efficiency Target:** 45-55% reduction vs Python

**Status:** Phase 3 - Implementation

---

### `xml`
**Purpose:** XML parsing and generation

**Exports:**
```arc
// Parsing
parse, from_string, from_reader

// Generation
build, to_string, to_writer

// Queries (XPath)
query, select, filter

// Utilities
validate, schema
```

**Token Efficiency Target:** 40-50% reduction vs JS/Python

**Status:** Phase 4 - Lower priority

---

### `yaml`
**Purpose:** YAML serialization/deserialization

**Exports:**
```arc
// Parsing
parse, from_string, from_reader

// Serialization
stringify, to_string, to_writer

// Validation
validate, schema
```

**Token Efficiency Target:** 45-55% reduction vs Python

**Status:** Phase 4 - Lower priority

---

### `toml`
**Purpose:** TOML configuration files

**Exports:**
```arc
// Parsing
parse, from_string, from_reader

// Serialization
stringify, to_string, to_writer
```

**Token Efficiency Target:** 45-55% reduction vs Rust

**Status:** Phase 4 - Lower priority

---

## Utility Modules

### `test`
**Purpose:** Testing framework

**Exports:**
```arc
// Assertions
assert, assert_eq, assert_ne, assert_ok, assert_err
assert_true, assert_false, assert_nil, assert_some
assert_contains, assert_match, assert_throws

// Test definition
test "description" { ... }
suite "description" { ... }

// Setup/Teardown
before { ... }
after { ... }
before_each { ... }
after_each { ... }

// Mocking
mock, stub, spy
mock_fn, reset_mocks

// Running
run_tests, run_suite, filter
```

**Token Efficiency Target:** 40-50% reduction vs Jest/pytest

**Status:** Phase 4 - Implementation

---

### `bench`
**Purpose:** Benchmarking utilities

**Exports:**
```arc
// Benchmarking
bench "name" { ... }
benchmark, measure

// Statistics
mean, median, stddev, min, max, percentile

// Comparison
compare, comparison reference, regression?

// Reporting
report, summary, detailed
```

**Token Efficiency Target:** 45-55% reduction vs criterion

**Status:** Phase 4 - Implementation

---

### `log`
**Purpose:** Logging

**Exports:**
```arc
// Levels
trace, debug, info, warn, error, fatal

// Configuration
level, format, output
timestamp?, colors?

// Structured logging
log(level, message, context)

// Loggers
Logger, with_context, with_prefix
```

**Token Efficiency Target:** 40-50% reduction vs winston/logging

**Status:** Phase 4 - Implementation

---

### `error`
**Purpose:** Error handling utilities

**Exports:**
```arc
// Error types
Error, custom_error, error_chain

// Result helpers
ok, err, unwrap, unwrap_or, expect
map, map_err, and_then, or_else

// Option helpers
some, none, unwrap, unwrap_or, expect
map, and_then, or_else, filter

// Recovery
try, catch, finally, recover, panic
```

**Token Efficiency Target:** 35-45% reduction vs Rust

**Status:** Phase 3 - Implementation

---

### `time`
**Purpose:** Date and time operations

**Exports:**
```arc
// Current time
now, today, utc_now

// Creation
date, datetime, time, duration
parse, from_string, from_timestamp

// Formatting
format, to_string, iso8601, rfc3339

// Arithmetic
add, subtract, diff
add_days, add_hours, add_minutes

// Queries
year, month, day, hour, minute, second
weekday, is_weekend?, is_leap_year?

// Timezone
to_utc, to_local, to_timezone
timezone, offset

// Duration
seconds, minutes, hours, days, weeks
```

**Token Efficiency Target:** 45-55% reduction vs moment/datetime

**Status:** Phase 4 - Implementation

---

### `regex`
**Purpose:** Regular expressions

**Exports:**
```arc
// Creation
Regex, compile, new

// Matching
match?, match, match_all, captures

// Replacement
replace, replace_all

// Splitting
split, split_n

// Utilities
escape, is_valid?
```

**Token Efficiency Target:** 40-50% reduction vs JS/Python

**Status:** Phase 3 - Implementation

---

### `hash`
**Purpose:** Hashing and cryptography (basic)

**Exports:**
```arc
// Hash functions
md5, sha1, sha256, sha512
hash, checksum

// Encoding
base64, base64_url
hex_encode, hex_decode

// UUIDs
uuid, uuid_v4, parse_uuid

// Password
hash_password, verify_password
bcrypt, argon2
```

**Token Efficiency Target:** 40-50% reduction vs crypto libraries

**Status:** Phase 4 - Implementation

---

### `env`
**Purpose:** Environment and process utilities

**Exports:**
```arc
// Environment variables
get, set, delete, has?
all, vars

// Process
args, exit, abort
pid, ppid

// System info
os, arch, platform
home_dir, tmp_dir, cwd
```

**Token Efficiency Target:** 45-55% reduction vs process/os

**Status:** Phase 3 - Implementation

---

### `cmd`
**Purpose:** Command execution and shell interaction

**Exports:**
```arc
// Execution
exec, run, spawn, output

// Pipes
pipe, stdin, stdout, stderr

// Status
wait, exit_code, success?, failed?

// Shell
shell, cmd, bash, powershell
```

**Token Efficiency Target:** 50-60% reduction vs child_process/subprocess

**Status:** Phase 4 - Implementation

---

## Advanced Modules (Future)

### `db`
**Purpose:** Database abstraction

**Status:** Phase 5+ (design later)

**Planned exports:**
- SQL query builder
- Connection pooling
- Migrations
- ORM-lite

---

### `graphics`
**Purpose:** Image processing and manipulation

**Status:** Phase 5+ (design later)

**Planned exports:**
- Image loading/saving
- Resize, crop, rotate
- Filters and effects
- Drawing primitives

---

### `ml`
**Purpose:** Machine learning utilities (AI agent focus)

**Status:** Phase 5+ (design later)

**Planned exports:**
- Embeddings
- Similarity search
- Token counting
- Model inference helpers

---

## Module Organization

### Directory Structure
```
stdlib/
├── core/           # Core types (built-in)
├── collections/    # Data structures
│   ├── list.arc
│   ├── map.arc
│   ├── set.arc
│   └── ...
├── string/         # String operations
├── math/           # Mathematics
├── io/             # I/O primitives
├── fs/             # File system
├── net/            # Networking
├── http/           # HTTP client/server
├── async/          # Async primitives
├── channel/        # Message passing
├── sync/           # Synchronization
├── json/           # JSON
├── csv/            # CSV
├── xml/            # XML (future)
├── yaml/           # YAML (future)
├── toml/           # TOML (future)
├── test/           # Testing
├── bench/          # Benchmarking
├── log/            # Logging
├── error/          # Error utilities
├── time/           # Date/time
├── regex/          # Regular expressions
├── hash/           # Hashing/crypto
├── env/            # Environment
└── cmd/            # Command execution
```

### Use Syntax

```arc
// Use entire module
use collections

// Use specific exports
use collections { List, Map, Set }

// Use everything (discouraged)
use collections { * }
```

---

## Implementation Priority

**Phase 3 (Core - Weeks 13-16):**
1. `collections` - Essential data structures
2. `string` - Text processing
3. `math` - Mathematical operations
4. `io` - I/O primitives
5. `fs` - File system
6. `http` - HTTP client/server
7. `async` - Async primitives
8. `channel` - Message passing
9. `sync` - Synchronization
10. `json` - JSON handling
11. `error` - Error utilities
12. `env` - Environment access

**Phase 4 (Extended - Weeks 17-20):**
1. `test` - Testing framework
2. `bench` - Benchmarking
3. `log` - Logging
4. `time` - Date/time
5. `regex` - Regular expressions
6. `csv` - CSV handling
7. `hash` - Hashing
8. `cmd` - Command execution

**Phase 5+ (Future):**
1. `xml` - XML parsing
2. `yaml` - YAML handling
3. `toml` - TOML parsing
4. `db` - Database abstraction
5. `graphics` - Image processing
6. `ml` - ML utilities

---

## Quality Standards

Every module must have:
1. ✅ Complete API documentation
2. ✅ Usage examples for every function
3. ✅ Token efficiency comparisons
4. ✅ 90%+ test coverage
5. ✅ Performance benchmarks
6. ✅ Error handling examples
7. ✅ Type signatures (gradual typing)

---

**Last Updated:** 2026-02-16  
**Designed By:** Subagent 3 (Opus 4.6)  
**Status:** Ready for Phase 3 implementation
