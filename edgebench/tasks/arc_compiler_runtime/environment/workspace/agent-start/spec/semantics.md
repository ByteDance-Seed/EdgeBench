# Arc Semantic Specification v0.1

**Status:** Draft  
**Last Updated:** 2026-02-16  
**Author:** Subagent 1 (Arc Language Specification Designer)

## Overview

This document defines the semantic behavior of Arc language constructs, including evaluation order, scoping rules, type system behavior, concurrency model, and runtime semantics. All design decisions prioritize **predictable behavior** and **zero-overhead abstractions**.

---

## 1. Evaluation Model

### 1.1 Expression-Oriented Evaluation

**Principle:** Everything in Arc is an expression that produces a value.

```arc
# If expression returns value
status = if age ≥ 18 => "adult" else => "minor"

# Match expression returns value
category = match score
  90..100 => "A"
  80..89 => "B"
  _ => "F"

# Block returns last expression
result =
  x = compute()
  y = transform(x)
  y * 2  # This value is returned
```

**Semantics:**
1. Every expression evaluates to a value
2. Blocks return the value of their last expression
3. Statements without meaningful value return `nil`
4. Assignment expressions return the assigned value

**Rationale:** Expression-oriented design eliminates special cases and makes code more composable.

---

## 2. Scoping Rules

### 2.1 Lexical Scoping

Arc uses **lexical (static) scoping** - variables are resolved at compile time based on code structure.

```arc
let x = 10

fn outer()
  let x = 20  # Shadows outer x
  
  fn inner()
    print(x)  # Refers to outer's x (20), not global x (10)
  
  inner()

outer()  # Prints: 20
```

**Semantics:**
1. Inner scopes can shadow outer variables
2. Lookups search from innermost to outermost scope
3. Function closures capture variables from their defining scope
4. No dynamic scoping or global state pollution

### 2.2 Block Scoping

```arc
let x = 1

if true
  let x = 2  # New binding, shadows outer x
  print(x)   # 2

print(x)     # 1 (outer x unchanged)

for i in 0..5
  let temp = i * 2  # temp only exists in loop
  print(temp)

# print(temp)  # Error: temp not in scope
```

**Semantics:**
1. `let` bindings are scoped to their containing block
2. Loop variables are scoped to the loop body
3. No variable hoisting (unlike JavaScript's `var`)
4. Variables must be declared before use

### 2.3 Closure Semantics

```arc
fn makeCounter()
  let mut count = 0
  
  fn increment()
    count += 1
    count
  
  increment

let counter = makeCounter()
print(counter())  # 1
print(counter())  # 2
print(counter())  # 3
```

**Semantics:**
1. Closures capture variables by reference (not value)
2. Mutable variables in closures are shared
3. Captured variables live as long as any closure referencing them
4. No explicit capture syntax needed (automatic)

**Memory Management:**
- Captured variables are heap-allocated
- Reference counting or garbage collection manages lifetime
- Zero-cost when not using closures

---

## 3. Type System

### 3.1 Gradual Typing

Arc uses **gradual typing** - types are optional, inference handles most cases, runtime checks when needed.

```arc
# Fully inferred
fn add(a, b) => a + b
result = add(10, 20)  # Works: inferred as Int

# Explicit types
fn divide(a: Float, b: Float) -> Float => a / b
result = divide(10.0, 3.0)  # Works: types match

# Runtime type checking
result = divide(10, 3)  # Error: expected Float, got Int
```

**Semantics:**
1. **Type inference:** Infer types from usage when possible
2. **Type checking:** Check annotated types at compile time
3. **Runtime coercion:** No implicit coercion (explicit casts required)
4. **Duck typing:** Objects checked by structure, not nominal type

### 3.2 Type Inference Rules

```arc
# Literal inference
x = 42          # Int
y = 3.14        # Float
s = "hello"     # String
b = true        # Bool

# Function inference
fn double(x) => x * 2
# Inferred: (Int | Float) -> (Int | Float)

# Array inference
items = [1, 2, 3]     # [Int]
mixed = [1, "two", 3] # [Int | String]

# Object inference
user = {name: "Alice", age: 30}
# Inferred: {name: String, age: Int}
```

**Inference Algorithm:**
1. Start with unknown type `?`
2. Propagate constraints from usage
3. Unify constraints to find most general type
4. Report error if constraints conflict

### 3.3 Semantic Types

Arc supports **semantic types** - types with validation constraints:

```arc
type Email = String where s => s.contains("@") && s.contains(".")
type Age = Int where x => x ≥ 0 && x ≤ 150
type PositiveInt = Int where x => x > 0

fn sendEmail(address: Email)
  # address is guaranteed to be valid format
  ...

# Compile-time validation (when possible)
sendEmail("user@example.com")  # OK
sendEmail("invalid")           # Error at compile time

# Runtime validation (when needed)
let input = getUserInput()
sendEmail(input)  # Runtime check, throws if invalid
```

**Semantics:**
1. Constraints checked at compile time when value is literal
2. Runtime validation when value is dynamic
3. Failed validation throws `TypeError`
4. Constraints are part of type signature

**Performance:**
- Compile-time checks = zero runtime cost
- Runtime checks = single validation call
- JIT compilers can optimize repeated checks

### 3.4 Union Types

```arc
type Result<T> = Success(T) | Error(String)

fn divide(a: Float, b: Float) -> Result<Float>
  if b = 0 => Error("Division by zero")
  else => Success(a / b)

# Pattern matching enforces exhaustiveness
match divide(10, 2)
  Success(value) => print("Result: {value}")
  Error(msg) => print("Error: {msg}")
  # Compiler error if missing case
```

**Semantics:**
1. Union types represent "one of several types"
2. Must handle all cases (exhaustiveness checking)
3. Pattern matching is the canonical way to destructure
4. Compiler tracks which case is active

---

## 4. Memory Model

### 4.1 Value vs Reference Semantics

```arc
# Primitive types: passed by value
let x = 10
let y = x
y += 1
print(x)  # 10 (unchanged)
print(y)  # 11

# Objects and arrays: passed by reference
let obj1 = {count: 0}
let obj2 = obj1
obj2.count += 1
print(obj1.count)  # 1 (changed!)
print(obj2.count)  # 1 (same object)

# Strings: immutable, implementation can optimize
let s1 = "hello"
let s2 = s1
# s1 and s2 may share same memory (copy-on-write)
```

**Semantics:**
1. **Primitive types** (Int, Float, Bool): Copy by value
2. **Objects and arrays**: Copy by reference
3. **Strings**: Immutable, shared representation
4. **Functions**: Reference to code + captured environment

### 4.2 Mutation

```arc
# Immutable bindings (default)
let x = 10
# x = 20  # Error: cannot reassign immutable binding

# Mutable bindings
let mut y = 10
y = 20  # OK

# Object properties are always mutable
let obj = {count: 0}
obj.count += 1  # OK, even though obj binding is immutable

# Freezing objects (making properties immutable)
let frozen = freeze({count: 0})
# frozen.count = 1  # Error: object is frozen
```

**Semantics:**
1. Bindings are immutable by default (`let`)
2. `let mut` creates mutable binding
3. Object properties are mutable regardless of binding
4. `freeze()` makes object deeply immutable

**Rationale:** Immutability by default prevents bugs and enables optimizations.

### 4.3 Memory Management

Arc uses **automatic memory management**:

**Options:**
1. **Garbage Collection (GC):** Stop-the-world or incremental
2. **Reference Counting (RC):** Deterministic cleanup, cycle detection needed
3. **Compile-time analysis:** Insert frees when possible (like Rust, but simpler)

**Chosen approach:** Hybrid
- Reference counting for most objects
- Cycle detector runs periodically
- Compile-time optimization eliminates RC overhead for local variables

**Rationale:**
- Deterministic cleanup for resources (files, connections)
- Low pause times (no GC stops)
- Predictable performance

---

## 5. Concurrency Model

### 5.1 Async by Default

**All functions in Arc are async** - no special syntax needed.

```arc
# This function is async
fn fetchUser(id)
  user = GET api/users/{id}  # Awaits automatically
  user

# Calling async functions
user = fetchUser(123)  # Awaits automatically

# Sequential execution
user1 = fetchUser(1)
user2 = fetchUser(2)  # Waits for user1 first
```

**Semantics:**
1. All function calls are awaited automatically
2. No `async`/`await` keywords
3. Sequential code executes sequentially
4. Use explicit parallelism for concurrent execution

**Rationale:** AI agents spend 90% of time on I/O. Making async the default eliminates ceremony.

### 5.2 Explicit Parallelism

```arc
# Parallel execution with array syntax
[user1, user2, user3] = [
  fetchUser(1),
  fetchUser(2),
  fetchUser(3)
]
# All three fetches happen in parallel, then results collected

# Parallel map
results = items.parallelMap(item => processItem(item))

# Race (first to complete)
fastest = race([
  fetchFromServer1(),
  fetchFromServer2(),
  fetchFromServer3()
])
```

**Semantics:**
1. Array of async expressions executes in parallel
2. Results collected when all complete
3. `race()` returns first completed value
4. `parallelMap()` processes items concurrently

### 5.3 Error Handling in Async

```arc
# Errors propagate normally
fn fetchData(id)
  result = GET api/data/{id}  # May throw
  result

# Handling errors
try
  data = fetchData(123)
  process(data)
catch e
  handleError(e)

# Result type (preferred)
fn fetchData(id) -> Result<Data>
  match GET api/data/{id}
    {status: 200, body: data} => Success(data)
    {status: s} => Error("HTTP {s}")
```

**Semantics:**
1. Async errors throw exceptions
2. Use try-catch or Result type
3. Unhandled errors propagate to top-level
4. Top-level errors crash program (fail-fast)

---

## 6. Pattern Matching Semantics

### 6.1 Pattern Evaluation Order

```arc
match value
  pattern1 => expr1
  pattern2 => expr2
  pattern3 => expr3
```

**Semantics:**
1. Patterns evaluated top-to-bottom
2. First matching pattern wins
3. Remaining patterns not evaluated
4. Must be exhaustive (all cases covered)

### 6.2 Pattern Binding

```arc
match [1, 2, 3]
  [] => "Empty"
  [x] => "One: {x}"           # x bound to 1 (if pattern matched)
  [x, y] => "Two: {x}, {y}"   # x=1, y=2
  [x, ..rest] => "First: {x}" # x=1, rest=[2, 3]
```

**Semantics:**
1. Patterns bind variables in their scope
2. Variables shadow outer scope
3. Bindings only accessible in pattern's arm
4. Rest patterns `..name` capture remaining elements

### 6.3 Guard Clauses

```arc
match x
  n where n < 0 => "Negative"
  n where n = 0 => "Zero"
  n => "Positive"
```

**Semantics:**
1. `where` clause evaluated after pattern matches
2. If guard returns false, try next pattern
3. Guards can reference pattern bindings
4. Guards must be pure (no side effects)

---

## 7. Operators and Precedence

### 7.1 Operator Precedence (highest to lowest)

| Precedence | Operators | Description |
|------------|-----------|-------------|
| 1 | `()` `[]` `.` | Call, index, member access |
| 2 | `²` `³` | Postfix (square, cube) |
| 3 | `!` `-` `√` | Prefix (not, negate, sqrt) |
| 4 | `*` `/` `%` | Multiplicative |
| 5 | `+` `-` | Additive |
| 6 | `..` `..=` | Range |
| 7 | `<` `>` `≤` `≥` | Comparison |
| 8 | `=` `≠` | Equality |
| 9 | `&&` | Logical AND |
| 10 | `||` | Logical OR |
| 11 | `|>` | Pipeline |
| 12 | `=` `+=` `-=` ... | Assignment |

### 7.2 Associativity

```arc
# Left-associative
a - b - c  # Evaluates as: (a - b) - c
a / b / c  # Evaluates as: (a / b) / c

# Right-associative
a = b = c  # Evaluates as: a = (b = c)

# Non-associative (error)
a < b < c  # Error: chain comparisons not supported
           # Use: a < b && b < c
```

### 7.3 Short-Circuit Evaluation

```arc
# && short-circuits
false && expensiveFunction()  # expensiveFunction() NOT called

# || short-circuits  
true || expensiveFunction()   # expensiveFunction() NOT called

# Returns last evaluated value
x = getValue() || defaultValue
```

**Semantics:**
1. `&&` returns first falsy value or last value
2. `||` returns first truthy value or last value
3. Side effects only occur if expression is evaluated

---

## 8. Control Flow Semantics

### 8.1 If Expression

```arc
result = if condition => thenBranch else => elseBranch
```

**Semantics:**
1. Condition evaluated first
2. If truthy, evaluate thenBranch
3. If falsy, evaluate elseBranch (or `nil` if no else)
4. Return value of evaluated branch

**Truthy/Falsy Values:**
- **Falsy:** `false`, `nil`, `0`, `""`, `[]`, `{}`
- **Truthy:** Everything else

### 8.2 Match Expression

```arc
result = match value
  pattern1 => expr1
  pattern2 => expr2
```

**Semantics:**
1. Evaluate value once
2. Try patterns in order
3. First match: bind variables, evaluate arm
4. Return arm's value
5. Error if no match (must be exhaustive)

**Exhaustiveness Checking:**
```arc
# Compiler error: non-exhaustive
match x
  0 => "zero"
  1 => "one"
  # Missing case for other numbers

# Fixed: add wildcard
match x
  0 => "zero"
  1 => "one"
  _ => "other"  # Catches all remaining cases
```

### 8.3 Loop Semantics

```arc
# For loop
for item in items => process(item)

# While loop
while condition => body
```

**For Loop Semantics:**
1. Evaluate iterable once
2. Create iterator
3. For each element: bind to pattern, execute body
4. Return array of results (if used as expression)

**While Loop Semantics:**
1. Evaluate condition
2. If truthy: execute body, repeat
3. If falsy: exit loop
4. Return `nil` (or last value if used as expression)

**Break and Continue:**
```arc
for item in items
  if shouldSkip(item) => continue
  if shouldStop(item) => break
  process(item)
```

- `break`: Exit loop immediately
- `continue`: Skip to next iteration
- `break value`: Exit and return value (like Rust)

---

## 9. HTTP Semantics

### 9.1 HTTP Expression Evaluation

```arc
user = GET api/users/123
```

**Semantics:**
1. Construct URL (with interpolation if needed)
2. Make HTTP request (async)
3. Await response
4. Parse response body as JSON (if Content-Type is application/json)
5. Return parsed data
6. Throw exception on error (4xx, 5xx status codes)

### 9.2 HTTP Request Details

```arc
# GET
data = GET url  # Returns parsed body

# POST/PUT/PATCH with body
result = POST url requestBody
# Serializes requestBody to JSON, sets Content-Type header

# DELETE
result = DELETE url  # Returns response body (if any)
```

**Automatic Handling:**
1. **JSON serialization:** Objects/arrays automatically converted to JSON
2. **JSON parsing:** Responses with `application/json` parsed automatically
3. **Headers:** Automatic `Content-Type`, `Accept` headers
4. **Error handling:** 4xx/5xx throw exceptions with status code

### 9.3 Error Handling

```arc
# Exceptions for errors
try
  user = GET api/users/invalid
catch e
  print("Error: {e.status} - {e.message}")

# Result type (preferred)
fn fetchUser(id) -> Result<User>
  match GET api/users/{id}
    {status: 200, body: user} => Success(user)
    {status: 404} => Error("Not found")
    {status: s} => Error("HTTP {s}")
```

---

## 10. Module System

### 10.1 Module Resolution

```arc
use mymodule { func }
```

**Resolution Order:**
1. Check if "module" is builtin (e.g., "io", "http")
2. Check for local file: `./module.arc`, `./module/index.arc`
3. Check in `node_modules` or package directory
4. Throw error if not found

### 10.2 Export Semantics

```arc
# All top-level definitions are exportable
fn publicFunction() => "available"
type PublicType = Int

# Private definitions (prefix with _)
fn _privateFunction() => "not exported"
```

**Semantics:**
1. Top-level `fn`, `type`, `let` are exportable
2. Users of the module can choose which to use
3. Private definitions (prefixed `_`) not exported
4. Re-exports possible: `use a { x }; x` exports x

---

## 11. Equality and Comparison

### 11.1 Equality Semantics

```arc
# Structural equality (default)
[1, 2, 3] = [1, 2, 3]         # true
{a: 1, b: 2} = {a: 1, b: 2}   # true
"hello" = "hello"             # true

# Reference equality for objects (not structural)
obj1 = {x: 1}
obj2 = {x: 1}
obj1 = obj2  # false (different references)

# Use reference equality explicitly
obj1.refEquals(obj2)  # false
```

**Semantics:**
1. Primitives: value equality
2. Strings: value equality (immutable)
3. Arrays: structural equality (deep comparison)
4. Objects: reference equality (unless overridden)
5. Functions: reference equality

**Rationale:** Structural equality for data structures is more useful than reference equality in most cases.

### 11.2 Comparison Semantics

```arc
# Numbers: mathematical comparison
1 < 2     # true
2.5 > 1   # true

# Strings: lexicographic comparison
"apple" < "banana"  # true
"a" < "b"           # true

# Arrays: lexicographic comparison
[1, 2] < [1, 3]     # true
[1, 2] < [2, 1]     # true
```

---

## 12. Standard Library Integration

### 12.1 Built-in Methods

Arrays, strings, and objects have built-in methods:

```arc
# Array methods
[1, 2, 3].map(x => x * 2)      # [2, 4, 6]
[1, 2, 3].filter(x => x > 1)   # [2, 3]
[1, 2, 3].reduce((a, b) => a + b, 0)  # 6

# String methods
"hello".toUpper()              # "HELLO"
"hello world".split(" ")       # ["hello", "world"]
"hello".contains("ell")        # true

# Object methods
{a: 1, b: 2}.keys()            # ["a", "b"]
{a: 1, b: 2}.values()          # [1, 2]
```

**Semantics:**
1. Methods are properties of prototype
2. `this` binding follows JavaScript rules
3. Methods can be chained
4. Mutating methods (like `push`) return the array

---

## 13. Error Semantics

### 13.1 Error Propagation

```arc
fn doWork()
  data = riskyOperation()  # May throw
  process(data)            # Not called if riskyOperation throws

fn caller()
  try
    doWork()
  catch e
    handleError(e)
```

**Semantics:**
1. Errors (exceptions) propagate up the call stack
2. First `try-catch` handles the error
3. Unhandled errors crash program
4. Stack trace preserved

### 13.2 Result Type (Preferred)

```arc
type Result<T, E> = Success(T) | Error(E)

fn divide(a, b) -> Result<Float, String>
  if b = 0 => Error("Division by zero")
  else => Success(a / b)

# Error propagation with ?
fn calculate() -> Result<Float, String>
  a = getNumber()?  # If Error, return early
  b = getNumber()?
  divide(a, b)?
```

**Semantics:**
1. `Result` is union type
2. Must explicitly handle both cases
3. `?` operator unwraps Success or returns Error
4. Compile-time exhaustiveness checking

---

## 14. Performance Semantics

### 14.1 Zero-Cost Abstractions

**Principle:** High-level features compile to efficient code.

```arc
# Array map
numbers.map(x => x * 2)

# Compiled to equivalent of:
let result = []
for i in 0..numbers.length
  result.push(numbers[i] * 2)
result
```

**Guarantees:**
1. No runtime overhead for abstractions
2. Optimizing compiler inlines small functions
3. Dead code elimination removes unused code
4. Constant folding for compile-time constants

### 14.2 Tail Call Optimization

```arc
fn factorial(n, acc = 1)
  if n ≤ 1 => acc
  else => factorial(n - 1, n * acc)  # Tail call optimized

factorial(100000)  # Doesn't blow the stack
```

**Semantics:**
1. Tail calls reuse stack frame
2. Enables deep recursion without stack overflow
3. Required by spec (not optional optimization)

---

## 15. Undefined Behavior

Arc aims to minimize undefined behavior:

**Never Undefined:**
- Array bounds (throws exception)
- Null/nil dereference (throws exception)
- Type errors (caught at compile time or runtime)
- Integer overflow (wraps or throws, configurable)

**Implementation Defined:**
- Exact numeric precision (platform-dependent)
- Maximum recursion depth
- Memory limits

---

## Appendix: Semantic Comparison

### JavaScript vs Arc

| Feature | JavaScript | Arc |
|---------|-----------|-----|
| Variable hoisting | Yes (var) | No |
| Implicit coercion | Yes | No |
| `this` binding | Complex | Simple (lexical) |
| Async by default | No | Yes |
| Type system | Optional (TS) | Optional (gradual) |
| Pattern matching | No | Yes |
| Exhaustiveness | No | Yes |
| Tail calls | Not guaranteed | Guaranteed |

---

**Status:** Draft v0.1 - Ready for implementation  
**Next Steps:** Build reference interpreter to validate semantics

